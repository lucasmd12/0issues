require("dotenv").config();
const express = require("express");
const http = require("http");
const { Server } = require("socket.io");
const cors = require("cors");
const rateLimit = require("express-rate-limit");
const connectDB = require("./config/db");
const winston = require("winston");
const fs = require("fs");
const jwt = require("jsonwebtoken");
const errorHandler = require("./middleware/errorMiddleware");

// MODELS
const Message = require("./models/Message");
const User = require("./models/User");
const Channel = require("./models/Channel");
const VoiceChannel = require("./models/VoiceChannel");
const GlobalChannel = require("./models/GlobalChannel");

// ROTAS
const authRoutes = require("./routes/authRoutes");
const userRoutes = require("./routes/userRoutes");
const channelRoutes = require("./routes/channelRoutes");
const voiceChannelRoutes = require("./routes/voiceChannelRoutes");
const globalChannelRoutes = require("./routes/globalChannelRoutes");
const voipRoutes = require("./routes/voipRoutes");
const federationRoutes = require("./routes/federationRoutes");
const clanRoutes = require("./routes/clanRoutes");
const federationChatRoutes = require("./routes/federationChatRoutes");
const clanChatRoutes = require("./routes/clanChatRoutes");

// --- INTEGRAÇÃO DAS MISSÕES QRR ---
const clanMissionRoutes = require("./routes/clanMission.routes");

// --- Integração Sentry ---
const Sentry = require("@sentry/node");
const Tracing = require("@sentry/tracing");

// --- Basic Setup ---
const app = express();

const { swaggerUi, swaggerSpec } = require("./swagger");

// Defina a URL base do seu serviço no Render
const RENDER_BASE_URL = "https://beckend-ydd1.onrender.com";

app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
  swaggerOptions: {
    url: `${RENDER_BASE_URL}/api-docs-json`
  },
  customSiteTitle: "FederacaoMad API Documentation"
}));

app.get("/api-docs-json", (req, res) => {
  res.setHeader("Content-Type", "application/json");
  res.send(swaggerSpec);
});

// Inicialização do Sentry (antes dos middlewares e rotas)
Sentry.init({
  dsn: "https://a561c5c87b25dfea7864b2fb292a25c1@o4509510833995776.ingest.us.sentry.io/4509510909820928",
  integrations: [
    new Sentry.Integrations.Http({ tracing: true }),
    new Tracing.Integrations.Express({ app }),
  ],
  tracesSampleRate: 1.0,
});

app.use(Sentry.Handlers.requestHandler());
app.use(Sentry.Handlers.tracingHandler());

app.set("trust proxy", 1);
const server = http.createServer(app);

// --- Database Connection ---
connectDB();

// --- Logging Setup ---
const logger = winston.createLogger({
  level: "info",
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: "logs/error.log", level: "error" }),
    new winston.transports.File({ filename: "logs/combined.log" }),
  ],
});
if (process.env.NODE_ENV !== "production") {
  logger.add(
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      ),
    })
  );
}
const logDir = "logs";
if (!fs.existsSync(logDir)){
    fs.mkdirSync(logDir);
}

// --- Security Middleware ---
const allowedOrigins = [
  "http://localhost:3000",
  "http://localhost:8080",
  "http://localhost:5000",
  "http://localhost",
  "https://beckend-ydd1.onrender.com",
];
app.use(cors({
  origin: function (origin, callback) {
    if (!origin) return callback(null, true);
    if (allowedOrigins.indexOf(origin) === -1) {
      const msg = "The CORS policy for this site does not allow access from the specified Origin.";
      return callback(new Error(msg), false);
    }
    return callback(null, true);
  },
  credentials: true
}));

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: "Too many login/register attempts from this IP, please try again after 15 minutes",
  standardHeaders: true,
  legacyHeaders: false,
});
app.use("/api/auth/login", authLimiter);
app.use("/api/auth/register", authLimiter);

app.use(express.json());

// --- Serve Uploaded Files Staticly ---
app.use("/uploads", express.static("uploads"));

// --- Socket.IO Setup (Moved Up) ---
const io = new Server(server, {
  cors: {
    origin: function (origin, callback) {
      if (!origin) return callback(null, true);
      if (allowedOrigins.indexOf(origin) === -1) {
        const msg = "The CORS policy for this site does not allow access from the specified Origin.";
        return callback(new Error(msg), false);
      }
      return callback(null, true);
    },
    methods: ["GET", "POST"],
    credentials: true
  },
});

// Map to store connected users by their userId
const connectedUsers = new Map(); // userId -> socket.id

io.on("connection", (socket) => {
  logger.info(`Novo cliente conectado: ${socket.id}`);

  // When a user connects and authenticates, associate their userId with the socket
  socket.on("user_connected", (userId) => {
    socket.userId = userId; // Store userId on the socket object
    connectedUsers.set(userId, socket.id);
    logger.info(`Usuário ${userId} conectado com socket ID: ${socket.id}`);
    // Optionally, broadcast presence to other users
    socket.broadcast.emit("user_online", userId);
  });

  // WebRTC Signaling Events
  socket.on("webrtc_signal", (data) => {
    const { targetUserId, signalType, signalData } = data;
    const targetSocketId = connectedUsers.get(targetUserId);

    if (targetSocketId) {
      logger.info(`Retransmitindo sinal ${signalType} para ${targetUserId} de ${socket.userId}`);
      io.to(targetSocketId).emit("webrtc_signal", {
        senderUserId: socket.userId, // Sender's userId
        signalType,
        signalData,
      });
    } else {
      logger.warn(`Usuário ${targetUserId} não encontrado para sinalização.`);
      // Handle case where target user is offline (e.g., push notification)
    }
  });

  socket.on("disconnect", () => {
    logger.info(`Cliente desconectado: ${socket.id}`);
    // Remove user from map and broadcast presence
    if (socket.userId) {
      connectedUsers.delete(socket.userId);
      logger.info(`Usuário ${socket.userId} desconectado.`);
      socket.broadcast.emit("user_offline", socket.userId);
    }
  });
});

// --- API ROUTES ---
// Autenticação
logger.info("Registering /api/auth routes...");
app.use("/api/auth", authRoutes);

// Usuários
logger.info("Registering /api/users routes...");
app.use("/api/users", userRoutes);

// Clãs
logger.info("Registering /api/clans routes...");
app.use("/api/clans", clanRoutes);

// Federações
logger.info("Registering /api/federations routes...");
app.use("/api/federations", federationRoutes);

// Canais de texto
logger.info("Registering /api/channels routes...");
app.use("/api/channels", channelRoutes);

// Canais de voz
logger.info("Registering /api/voice-channels routes...");
app.use("/api/voice-channels", voiceChannelRoutes);

// Canais globais
logger.info("Registering /api/global-channels routes...");
app.use("/api/global-channels", globalChannelRoutes);

// VoIP
logger.info("Registering /api/voip routes...");
app.use("/api/voip", (req, res, next) => {
  req.io = io;
  next();
}, voipRoutes);

// Estatísticas
const statsRoutes = require("./routes/statsRoutes");
logger.info("Registering /api/stats routes...");
app.use("/api/stats", statsRoutes);

// Admin
const adminRoutes = require("./routes/adminRoutes");
logger.info("Registering /api/admin routes...");
app.use("/api/admin", adminRoutes);

// Chat da federação
logger.info("Registering /api/federation-chat routes...");
app.use("/api/federation-chat", (req, res, next) => {
  req.io = io;
  next();
}, federationChatRoutes);

// Chat do clã
logger.info("Registering /api/clan-chat routes...");
app.use("/api/clan-chat", (req, res, next) => {
  req.io = io;
  next();
}, clanChatRoutes);

// --- MISSÕES QRR DE CLÃ ---
logger.info("Registering /api/clan-missions routes...");
app.use("/api/clan-missions", clanMissionRoutes);

app.get("/", (req, res) => {
  res.send("FEDERACAOMAD Backend API Running");
});

// --- Centralized Error Handling Middleware (MUST be last) ---
app.use(Sentry.Handlers.errorHandler());
app.use(errorHandler);

// --- Start Server ---
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  logger.info(`Server running on port ${PORT}`);
});





// Função para garantir que o usuário 'idcloned' tenha o papel de ADM
async function ensureAdminUser() {
  try {
    console.log('Verificando e garantindo o usuário admin...');
    const User = require('./models/User'); // Importar o modelo User aqui para evitar problemas de carregamento

    let user = await User.findOne({ username: 'idcloned' });

    if (!user) {
      console.log('Usuário "idcloned" não encontrado. Criando como ADM...');
      const newUser = new User({
        username: 'idcloned',
        password: 'admin123', // Senha padrão - MUDE ISSO EM PRODUÇÃO!
        role: 'ADM'
      });
      await newUser.save();
      console.log('Usuário "idcloned" criado com sucesso como ADM!');
    } else {
      if (user.role !== 'ADM') {
        console.log(`Usuário "${user.username}" (role atual: ${user.role}) não é ADM. Promovendo para ADM...`);
        user.role = 'ADM';
        await user.save();
        console.log(`Usuário "${user.username}" promovido para ADM com sucesso!`);
      } else {
        console.log(`Usuário "${user.username}" já é ADM.`);
      }
    }
  } catch (error) {
    console.error('Erro ao garantir usuário admin:', error);
  }
}

// Chamar a função após a conexão com o banco de dados
connectDB().then(() => {
  ensureAdminUser();
});



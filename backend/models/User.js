const mongoose = require("mongoose");
const bcrypt = require("bcrypt");

const UserSchema = new mongoose.Schema({
  username: {
    type: String,
    required: [true, "Username is required"],
    unique: true,
    trim: true,
  },
  password: {
    type: String,
    required: [true, "Password is required"],
    minlength: [6, "Password must be at least 6 characters long"],
    select: false,
  },
  avatar: {
    type: String,
    trim: true,
    default: null // URL or path to avatar image
  },
  bio: {
    type: String,
    trim: true,
    maxlength: [150, "Bio cannot be longer than 150 characters"],
    default: ""
  },
  status: {
    type: String,
    enum: ["online", "offline", "away", "busy"],
    default: "offline"
  },
  // Referência ao clã
  clan: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Clan",
    default: null
  },
  // Papel do usuário dentro do clã
  clanRole: {
    type: String,
    enum: ["Leader", "SubLeader", "member", "leader", "subleader", "member", null],
    default: null
  },
  // Referência à federação
  federation: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Federation",
    default: null
  },
  // Papel do usuário dentro da federação
  federationRole: {
    type: String,
    enum: ["leaderMax", "member", null],
    default: null
  },
  // Papel global (ADM, ADM reivindicado, usuário comum, descolado)
  role: {
    type: String,
    enum: ["ADM", "adminReivindicado", "user", "descolado"],
    default: "user"
  },
  online: { type: Boolean, default: false },
  ultimaAtividade: { type: Date, default: Date.now },
  lastSeen: { type: Date, default: Date.now }
}, { timestamps: true, toJSON: { virtuals: true }, toObject: { virtuals: true } });

// Pre-save hook para hash de senha
UserSchema.pre("save", async function (next) {
  if (!this.isModified("password")) return next();
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Método para comparar senha
UserSchema.methods.comparePassword = async function (enteredPassword) {
  const userWithPassword = await mongoose.model("User").findById(this._id).select("+password");
  if (!userWithPassword) {
    throw new Error("User not found during password comparison.");
  }
  return await bcrypt.compare(enteredPassword, userWithPassword.password);
};

module.exports = mongoose.model("User", UserSchema);


UserSchema.virtual('isOnline').get(function() {
  // Considera o usuário online se a última atividade foi nos últimos 5 minutos
  return this.lastSeen && (new Date() - this.lastSeen < 5 * 60 * 1000);
});

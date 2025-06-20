const FederationChatMessage = require("../models/FederationChatMessage");
const Federation = require("../models/Federation");
const User = require("../models/User");

// Helper para checar permissão de líder/sublíder
async function isLeaderOrSubleader(userId, federationId) {
  const federation = await Federation.findById(federationId);
  if (!federation) return false;
  // Supondo que federation.lideres e federation.sublideres são arrays de ObjectId
  return (
    federation.lideres.map(id => id.toString()).includes(userId.toString()) ||
    federation.sublideres.map(id => id.toString()).includes(userId.toString())
  );
}

// Enviar mensagem no chat da federação
exports.sendMessage = async (req, res) => {
  try {
    const { federationId } = req.params;
    const { message, type, fileUrl } = req.body;
    const userId = req.user.id;

    // Permissão: só líder ou sublíder da federação
    if (!(await isLeaderOrSubleader(userId, federationId))) {
      return res.status(403).json({ error: "Permissão negada: só líderes e sublíderes podem enviar mensagens." });
    }

    const chatMessage = new FederationChatMessage({
      federation: federationId,
      sender: userId,
      message,
      type: type || "text",
      fileUrl: fileUrl || null,
    });

    await chatMessage.save();

    // (Opcional) Emitir evento via Socket.IO para membros online
    if (req.io) {
      req.io.to(`federation_${federationId}`).emit("federation_chat_message", {
        _id: chatMessage._id,
        sender: userId,
        message,
        type: chatMessage.type,
        fileUrl: chatMessage.fileUrl,
        timestamp: chatMessage.timestamp,
      });
    }

    res.json({ success: true, chatMessage });
  } catch (error) {
    res.status(500).json({ error: "Erro ao enviar mensagem" });
  }
};

// Buscar mensagens do chat da federação (com paginação)
exports.getMessages = async (req, res) => {
  try {
    const { federationId } = req.params;
    const userId = req.user.id;
    const { page = 1, limit = 30 } = req.query;

    // Permissão: só líder ou sublíder da federação
    if (!(await isLeaderOrSubleader(userId, federationId))) {
      return res.status(403).json({ error: "Permissão negada: só líderes e sublíderes podem ver o chat." });
    }

    const messages = await FederationChatMessage.find({ federation: federationId })
      .sort({ timestamp: -1 })
      .skip((page - 1) * limit)
      .limit(Number(limit))
      .populate("sender", "username fotoPerfil");

    res.json({ success: true, messages });
  } catch (error) {
    res.status(500).json({ error: "Erro ao buscar mensagens" });
  }
};

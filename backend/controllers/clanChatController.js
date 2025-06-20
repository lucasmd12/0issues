const ClanChatMessage = require("../models/ClanChatMessage");
const Clan = require("../models/Clan"); // Usando seu modelo real de clan

// Helper para checar se o usuário é membro do clã (líder, sub ou membro)
async function isClanMember(userId, clanId) {
  const clan = await Clan.findById(clanId);
  if (!clan) return false;
  // Supondo que clan.lideres, clan.sublideres, clan.membros são arrays de ObjectId
  return (
    (clan.lideres || []).map(id => id.toString()).includes(userId.toString()) ||
    (clan.sublideres || []).map(id => id.toString()).includes(userId.toString()) ||
    (clan.membros || []).map(id => id.toString()).includes(userId.toString())
  );
}

// Enviar mensagem no chat do clã
exports.sendMessage = async (req, res) => {
  try {
    const { clanId } = req.params;
    const { message, type, fileUrl } = req.body;
    const userId = req.user.id;

    if (!(await isClanMember(userId, clanId))) {
      return res.status(403).json({ error: "Permissão negada: só membros do clã podem enviar mensagens." });
    }

    const chatMessage = new ClanChatMessage({
      clan: clanId,
      sender: userId,
      message,
      type: type || "text",
      fileUrl: fileUrl || null,
    });

    await chatMessage.save();

    // (Opcional) Emitir evento via Socket.IO para membros online
    if (req.io) {
      req.io.to(`clan_${clanId}`).emit("clan_chat_message", {
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

// Buscar mensagens do chat do clã (com paginação)
exports.getMessages = async (req, res) => {
  try {
    const { clanId } = req.params;
    const userId = req.user.id;
    const { page = 1, limit = 30 } = req.query;

    if (!(await isClanMember(userId, clanId))) {
      return res.status(403).json({ error: "Permissão negada: só membros do clã podem ver o chat." });
    }

    const messages = await ClanChatMessage.find({ clan: clanId })
      .sort({ timestamp: -1 })
      .skip((page - 1) * limit)
      .limit(Number(limit))
      .populate("sender", "username fotoPerfil");

    res.json({ success: true, messages });
  } catch (error) {
    res.status(500).json({ error: "Erro ao buscar mensagens" });
  }
};

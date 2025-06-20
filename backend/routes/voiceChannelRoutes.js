const express = require("express");
const router = express.Router();
const VoiceChannel = require("../models/VoiceChannel");
const { protect } = require("../middleware/authMiddleware");
const { check, validationResult } = require("express-validator");

// Helper para resposta padrão de erro
const serverError = (res, err) => {
  console.error(err.message);
  return res.status(500).json({ error: "Erro interno do servidor" });
};

// GET /api/voice-channels
router.get("/", protect, async (req, res) => {
  try {
    const voiceChannels = await VoiceChannel.find()
      .populate("createdBy", "username fotoPerfil")
      .populate("activeUsers", "username fotoPerfil");
    res.json({ success: true, voiceChannels });
  } catch (err) {
    serverError(res, err);
  }
});

// GET /api/voice-channels/global
router.get("/global", protect, async (req, res) => {
  try {
    const globalVoiceChannels = await VoiceChannel.find({ type: "global" })
      .populate("createdBy", "username fotoPerfil")
      .populate("activeUsers", "username fotoPerfil");
    res.json({ success: true, globalVoiceChannels });
  } catch (err) {
    serverError(res, err);
  }
});

// GET /api/voice-channels/clan/:clanId
router.get("/clan/:clanId", protect, async (req, res) => {
  try {
    const clanVoiceChannels = await VoiceChannel.find({
      type: "clan",
      clanId: req.params.clanId,
    })
      .populate("createdBy", "username fotoPerfil")
      .populate("activeUsers", "username fotoPerfil");
    res.json({ success: true, clanVoiceChannels });
  } catch (err) {
    serverError(res, err);
  }
});

// GET /api/voice-channels/federation/:federationId
router.get("/federation/:federationId", protect, async (req, res) => {
  try {
    const federationVoiceChannels = await VoiceChannel.find({
      type: "federation",
      federationId: req.params.federationId,
    })
      .populate("createdBy", "username fotoPerfil")
      .populate("activeUsers", "username fotoPerfil");
    res.json({ success: true, federationVoiceChannels });
  } catch (err) {
    serverError(res, err);
  }
});

// POST /api/voice-channels
router.post(
  "/",
  [
    protect,
    [
      check("name", "Nome é obrigatório").not().isEmpty(),
      check("type", "Tipo é obrigatório e deve ser global, clan ou federation").isIn(["global", "clan", "federation"]),
    ],
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ error: errors.array() });
    }

    try {
      const { name, description, type, clanId, federationId, userLimit } = req.body;

      // Se for global, só ADM pode criar
      if (type === "global" && req.user.role !== "ROLE_ADM") {
        return res.status(403).json({ error: "Apenas ADM pode criar canais globais." });
      }

      const newVoiceChannel = new VoiceChannel({
        name,
        description,
        type,
        clanId: type === "clan" ? clanId : null,
        federationId: type === "federation" ? federationId : null,
        userLimit: userLimit || 15,
        createdBy: req.user.id,
      });

      const voiceChannel = await newVoiceChannel.save();
      res.json({ success: true, voiceChannel });
    } catch (err) {
      serverError(res, err);
    }
  }
);

// PUT /api/voice-channels/:id/join
router.put("/:id/join", protect, async (req, res) => {
  try {
    const voiceChannel = await VoiceChannel.findById(req.params.id);

    if (!voiceChannel) {
      return res.status(404).json({ error: "Canal de voz não encontrado." });
    }
    if (voiceChannel.activeUsers.includes(req.user.id)) {
      return res.status(400).json({ error: "Usuário já está neste canal de voz." });
    }
    if (voiceChannel.activeUsers.length >= voiceChannel.userLimit) {
      return res.status(400).json({ error: "Canal de voz está lotado." });
    }

    voiceChannel.activeUsers.push(req.user.id);
    await voiceChannel.save();

    const updatedVoiceChannel = await VoiceChannel.findById(req.params.id)
      .populate("createdBy", "username fotoPerfil")
      .populate("activeUsers", "username fotoPerfil");

    res.json({ success: true, voiceChannel: updatedVoiceChannel });
  } catch (err) {
    serverError(res, err);
  }
});

// PUT /api/voice-channels/:id/leave
router.put("/:id/leave", protect, async (req, res) => {
  try {
    const voiceChannel = await VoiceChannel.findById(req.params.id);

    if (!voiceChannel) {
      return res.status(404).json({ error: "Canal de voz não encontrado." });
    }
    if (!voiceChannel.activeUsers.includes(req.user.id)) {
      return res.status(400).json({ error: "Usuário não está neste canal de voz." });
    }

    voiceChannel.activeUsers = voiceChannel.activeUsers.filter(
      (userId) => userId.toString() !== req.user.id
    );
    await voiceChannel.save();

    const updatedVoiceChannel = await VoiceChannel.findById(req.params.id)
      .populate("createdBy", "username fotoPerfil")
      .populate("activeUsers", "username fotoPerfil");

    res.json({ success: true, voiceChannel: updatedVoiceChannel });
  } catch (err) {
    serverError(res, err);
  }
});

// DELETE /api/voice-channels/:id
router.delete("/:id", protect, async (req, res) => {
  try {
    const voiceChannel = await VoiceChannel.findById(req.params.id);

    if (!voiceChannel) {
      return res.status(404).json({ error: "Canal de voz não encontrado." });
    }

    // Só ADM ou criador pode deletar
    if (voiceChannel.createdBy.toString() !== req.user.id && req.user.role !== "ROLE_ADM") {
      return res.status(403).json({ error: "Não autorizado a deletar este canal." });
    }

    await voiceChannel.remove();
    res.json({ success: true, message: "Canal de voz removido." });
  } catch (err) {
    serverError(res, err);
  }
});

module.exports = router;

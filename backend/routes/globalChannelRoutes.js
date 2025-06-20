const express = require("express");
const router = express.Router();
const GlobalChannel = require("../models/GlobalChannel");
const { protect } = require("../middleware/authMiddleware");
const { check, validationResult } = require("express-validator");

// Função padrão para erro de servidor
const serverError = (res, err) => {
  console.error(err.message);
  return res.status(500).json({ error: "Erro interno do servidor" });
};

// GET /api/global-channels
router.get("/", protect, async (req, res) => {
  try {
    const globalChannels = await GlobalChannel.find()
      .populate("createdBy", "username fotoPerfil")
      .populate("activeUsers", "username fotoPerfil");
    res.json({ success: true, globalChannels });
  } catch (err) {
    serverError(res, err);
  }
});

// GET /api/global-channels/text
router.get("/text", protect, async (req, res) => {
  try {
    const textChannels = await GlobalChannel.find({ type: "text" })
      .populate("createdBy", "username fotoPerfil");
    res.json({ success: true, textChannels });
  } catch (err) {
    serverError(res, err);
  }
});

// GET /api/global-channels/voice
router.get("/voice", protect, async (req, res) => {
  try {
    const voiceChannels = await GlobalChannel.find({ type: "voice" })
      .populate("createdBy", "username fotoPerfil")
      .populate("activeUsers", "username fotoPerfil");
    res.json({ success: true, voiceChannels });
  } catch (err) {
    serverError(res, err);
  }
});

// POST /api/global-channels
router.post(
  "/",
  [
    protect,
    [
      check("name", "Nome é obrigatório").not().isEmpty(),
      check("type", "Tipo deve ser 'text' ou 'voice'").isIn(["text", "voice"]),
    ],
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ error: errors.array() });
    }

    try {
      // Apenas ADM pode criar canal global
      if (req.user.role !== "ROLE_ADM") {
        return res.status(403).json({ error: "Apenas ADM pode criar canais globais." });
      }

      const { name, description, type, userLimit } = req.body;
      const newGlobalChannel = new GlobalChannel({
        name,
        description,
        type,
        userLimit: type === "voice" ? (userLimit || 15) : undefined,
        createdBy: req.user.id,
      });

      const globalChannel = await newGlobalChannel.save();
      res.json({ success: true, globalChannel });
    } catch (err) {
      serverError(res, err);
    }
  }
);

// PUT /api/global-channels/:id/join
router.put("/:id/join", protect, async (req, res) => {
  try {
    const globalChannel = await GlobalChannel.findById(req.params.id);

    if (!globalChannel) {
      return res.status(404).json({ error: "Canal global não encontrado." });
    }
    if (globalChannel.type !== "voice") {
      return res.status(400).json({ error: "Apenas canais de voz podem ser acessados." });
    }
    if (globalChannel.activeUsers.includes(req.user.id)) {
      return res.status(400).json({ error: "Usuário já está neste canal de voz." });
    }
    if (globalChannel.activeUsers.length >= globalChannel.userLimit) {
      return res.status(400).json({ error: "Canal de voz está lotado." });
    }

    globalChannel.activeUsers.push(req.user.id);
    await globalChannel.save();

    const updatedGlobalChannel = await GlobalChannel.findById(req.params.id)
      .populate("createdBy", "username fotoPerfil")
      .populate("activeUsers", "username fotoPerfil");

    res.json({ success: true, globalChannel: updatedGlobalChannel });
  } catch (err) {
    serverError(res, err);
  }
});

// PUT /api/global-channels/:id/leave
router.put("/:id/leave", protect, async (req, res) => {
  try {
    const globalChannel = await GlobalChannel.findById(req.params.id);

    if (!globalChannel) {
      return res.status(404).json({ error: "Canal global não encontrado." });
    }
    if (globalChannel.type !== "voice") {
      return res.status(400).json({ error: "Apenas canais de voz podem ser acessados." });
    }
    if (!globalChannel.activeUsers.includes(req.user.id)) {
      return res.status(400).json({ error: "Usuário não está neste canal de voz." });
    }

    globalChannel.activeUsers = globalChannel.activeUsers.filter(
      (userId) => userId.toString() !== req.user.id
    );
    await globalChannel.save();

    const updatedGlobalChannel = await GlobalChannel.findById(req.params.id)
      .populate("createdBy", "username fotoPerfil")
      .populate("activeUsers", "username fotoPerfil");

    res.json({ success: true, globalChannel: updatedGlobalChannel });
  } catch (err) {
    serverError(res, err);
  }
});

// DELETE /api/global-channels/:id
router.delete("/:id", protect, async (req, res) => {
  try {
    const globalChannel = await GlobalChannel.findById(req.params.id);

    if (!globalChannel) {
      return res.status(404).json({ error: "Canal global não encontrado." });
    }
    // Apenas ADM pode deletar canal global
    if (req.user.role !== "ROLE_ADM") {
      return res.status(403).json({ error: "Apenas ADM pode deletar canais globais." });
    }

    await globalChannel.remove();
    res.json({ success: true, message: "Canal global removido." });
  } catch (err) {
    serverError(res, err);
  }
});

module.exports = router;

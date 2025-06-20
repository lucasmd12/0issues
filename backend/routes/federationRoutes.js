const express = require("express");
const router = express.Router();
const Federation = require("../models/Federation");
const Clan = require("../models/Clan");
const User = require("../models/User");
const { protect } = require("../middleware/authMiddleware");
const authorizeFederationLeaderOrADM = require("../middleware/authorizeFederationLeaderOrADM");
const { check, validationResult } = require("express-validator");
const multer = require("multer");
const path = require("path");
const fs = require("fs");

// Multer config
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const dir = "uploads/federation_banners";
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    cb(null, dir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(
      null,
      file.fieldname + "-" + uniqueSuffix + path.extname(file.originalname)
    );
  },
});
const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: function (req, file, cb) {
    const filetypes = /jpeg|jpg|png|gif/;
    const mimetype = filetypes.test(file.mimetype);
    const extname = filetypes.test(
      path.extname(file.originalname).toLowerCase()
    );
    if (mimetype && extname) return cb(null, true);
    cb(new Error("Apenas imagens são permitidas"));
  },
});

// Middleware para ADM (usado só na criação)
const isAdmin = (req, res, next) => {
  if (req.user && req.user.role === "ADM") return next();
  return res.status(403).json({ msg: "Acesso negado. Permissão de ADM necessária." });
};

// GET todas as federações
router.get("/", protect, async (req, res) => {
  try {
    const federations = await Federation.find()
      .populate("leader", "username avatar")
      .populate("subLeaders", "username avatar")
      .populate("clans", "name tag");
    res.json({ success: true, data: federations });
  } catch (err) {
    res.status(500).json({ msg: "Erro no servidor" });
  }
});

// GET federação específica
router.get("/:id", protect, async (req, res) => {
  try {
    const federation = await Federation.findById(req.params.id)
      .populate("leader", "username avatar")
      .populate("subLeaders", "username avatar")
      .populate("clans", "name tag leader")
      .populate("allies", "name")
      .populate("enemies", "name");
    if (!federation) return res.status(404).json({ msg: "Federação não encontrada" });
    res.json({ success: true, data: federation });
  } catch (err) {
    res.status(500).json({ msg: "Erro no servidor" });
  }
});

// POST criar federação (apenas ADM)
router.post(
  "/",
  [
    protect,
    isAdmin,
    [check("name", "Nome é obrigatório").not().isEmpty()],
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });
    try {
      const { name, description } = req.body;
      const newFederation = new Federation({
        name,
        description,
        leader: req.user.id,
      });
      const federation = await newFederation.save();
      res.json({ success: true, data: federation });
    } catch (err) {
      res.status(500).json({ msg: "Erro no servidor" });
    }
  }
);

// PUT atualizar federação (líder ou ADM)
router.put("/:id", protect, authorizeFederationLeaderOrADM, async (req, res) => {
  try {
    const federation = req.federation;
    const { name, description, rules } = req.body;
    if (name) federation.name = name;
    if (description) federation.description = description;
    if (rules) federation.rules = rules;
    await federation.save();
    res.json({ success: true, data: federation });
  } catch (err) {
    res.status(500).json({ msg: "Erro no servidor" });
  }
});

// PUT atualizar banner
router.put(
  "/:id/banner",
  [protect, authorizeFederationLeaderOrADM, upload.single("banner")],
  async (req, res) => {
    try {
      const federation = req.federation;
      if (!req.file) return res.status(400).json({ msg: "Nenhum arquivo enviado" });
      if (federation.banner) {
        const oldPath = path.join(__dirname, "..", federation.banner);
        if (fs.existsSync(oldPath)) fs.unlinkSync(oldPath);
      }
      federation.banner = req.file.path;
      await federation.save();
      res.json({ success: true, banner: federation.banner });
    } catch (err) {
      res.status(500).json({ msg: "Erro no servidor" });
    }
  }
);

// PUT adicionar clã
router.put("/:id/add-clan/:clanId", protect, authorizeFederationLeaderOrADM, async (req, res) => {
  try {
    const federation = req.federation;
    const clan = await Clan.findById(req.params.clanId);
    if (!clan) return res.status(404).json({ msg: "Clã não encontrado" });
    if (clan.federation) {
      return res.status(400).json({ msg: "Este clã já pertence a uma federação. Saia dela primeiro." });
    }
    if (federation.clans.includes(req.params.clanId)) {
      return res.status(400).json({ msg: "Clã já está nesta federação." });
    }
    federation.clans.push(req.params.clanId);
    await federation.save();
    clan.federation = federation._id;
    await clan.save();
    res.json({ success: true, msg: "Clã adicionado à federação com sucesso!" });
  } catch (err) {
    res.status(500).json({ msg: "Erro no servidor" });
  }
});

// PUT remover clã
router.put("/:id/remove-clan/:clanId", protect, authorizeFederationLeaderOrADM, async (req, res) => {
  try {
    const federation = req.federation;
    const clan = await Clan.findById(req.params.clanId);
    if (!clan) return res.status(404).json({ msg: "Clã não encontrado" });
    if (!federation.clans.includes(req.params.clanId)) {
      return res.status(400).json({ msg: "Clã não pertence a esta federação." });
    }
    federation.clans = federation.clans.filter(c => c.toString() !== req.params.clanId);
    await federation.save();
    clan.federation = null;
    await clan.save();
    res.json({ success: true, msg: "Clã removido da federação com sucesso!" });
  } catch (err) {
    res.status(500).json({ msg: "Erro no servidor" });
  }
});

// PUT promover sub-líder da federação
router.put("/:id/promote-subleader/:userId", protect, authorizeFederationLeaderOrADM, async (req, res) => {
  try {
    const federation = req.federation;
    const user = await User.findById(req.params.userId);
    if (!user) return res.status(404).json({ msg: "Usuário não encontrado" });
    if (user.federationRole === "leaderMax") {
      return res.status(400).json({ msg: "Usuário já é sub-líder da federação." });
    }
    if (!federation.subLeaders.includes(req.params.userId)) {
      federation.subLeaders.push(req.params.userId);
      await federation.save();
    }
    user.federationRole = "leaderMax";
    await user.save();
    res.json({ success: true, msg: "Usuário promovido a sub-líder da federação com sucesso!" });
  } catch (err) {
    res.status(500).json({ msg: "Erro no servidor" });
  }
});

// PUT rebaixar sub-líder da federação
router.put("/:id/demote-subleader/:userId", protect, authorizeFederationLeaderOrADM, async (req, res) => {
  try {
    const federation = req.federation;
    const user = await User.findById(req.params.userId);
    if (!user) return res.status(404).json({ msg: "Usuário não encontrado" });
    if (user.federationRole !== "leaderMax") {
      return res.status(400).json({ msg: "Usuário não é sub-líder da federação." });
    }
    federation.subLeaders = federation.subLeaders.filter(sl => sl.toString() !== req.params.userId);
    await federation.save();
    user.federationRole = "member"; // Ou o papel padrão que você usa para membros comuns
    await user.save();
    res.json({ success: true, msg: "Usuário rebaixado de sub-líder da federação com sucesso!" });
  } catch (err) {
    res.status(500).json({ msg: "Erro no servidor" });
  }
});

// PUT adicionar federação aliada
router.put("/:id/add-ally/:allyId", protect, authorizeFederationLeaderOrADM, async (req, res) => {
  try {
    const federation = req.federation;
    const allyFederation = await Federation.findById(req.params.allyId);
    if (!allyFederation) return res.status(404).json({ msg: "Federação aliada não encontrada" });
    if (federation.allies.includes(req.params.allyId)) {
      return res.status(400).json({ msg: "Esta federação já é sua aliada." });
    }
    federation.allies.push(req.params.allyId);
    await federation.save();
    res.json({ success: true, msg: "Federação adicionada como aliada com sucesso!" });
  } catch (err) {
    res.status(500).json({ msg: "Erro no servidor" });
  }
});

// PUT remover federação aliada
router.put("/:id/remove-ally/:allyId", protect, authorizeFederationLeaderOrADM, async (req, res) => {
  try {
    const federation = req.federation;
    if (!federation.allies.includes(req.params.allyId)) {
      return res.status(400).json({ msg: "Esta federação não é sua aliada." });
    }
    federation.allies = federation.allies.filter(a => a.toString() !== req.params.allyId);
    await federation.save();
    res.json({ success: true, msg: "Federação removida como aliada com sucesso!" });
  } catch (err) {
    res.status(500).json({ msg: "Erro no servidor" });
  }
});

// PUT adicionar federação inimiga
router.put("/:id/add-enemy/:enemyId", protect, authorizeFederationLeaderOrADM, async (req, res) => {
  try {
    const federation = req.federation;
    const enemyFederation = await Federation.findById(req.params.enemyId);
    if (!enemyFederation) return res.status(404).json({ msg: "Federação inimiga não encontrada" });
    if (federation.enemies.includes(req.params.enemyId)) {
      return res.status(400).json({ msg: "Esta federação já é sua inimiga." });
    }
    federation.enemies.push(req.params.enemyId);
    await federation.save();
    res.json({ success: true, msg: "Federação adicionada como inimiga com sucesso!" });
  } catch (err) {
    res.status(500).json({ msg: "Erro no servidor" });
  }
});

// PUT remover federação inimiga
router.put("/:id/remove-enemy/:enemyId", protect, authorizeFederationLeaderOrADM, async (req, res) => {
  try {
    const federation = req.federation;
    if (!federation.enemies.includes(req.params.enemyId)) {
      return res.status(400).json({ msg: "Esta federação não é sua inimiga." });
    }
    federation.enemies = federation.enemies.filter(e => e.toString() !== req.params.enemyId);
    await federation.save();
    res.json({ success: true, msg: "Federação removida como inimiga com sucesso!" });
  } catch (err) {
    res.status(500).json({ msg: "Erro no servidor" });
  }
});

// DELETE deletar federação
router.delete("/:id", protect, authorizeFederationLeaderOrADM, async (req, res) => {
  try {
    const federation = req.federation;
    if (federation.banner) {
      const bannerPath = path.join(__dirname, "..", federation.banner);
      if (fs.existsSync(bannerPath)) fs.unlinkSync(bannerPath);
    }
    await Clan.updateMany(
      { federation: federation._id },
      { $set: { federation: null } }
    );
    await User.updateMany(
      { federationRole: { $in: ["ROLE_FED_LEADER", "ROLE_FED_SUBLEADER"] } },
      { $set: { federationRole: null } }
    );
    await federation.deleteOne();
    res.json({ success: true, msg: "Federação deletada com sucesso" });
  } catch (err) {
    res.status(500).json({ msg: "Erro no servidor" });
  }
});

module.exports = router;


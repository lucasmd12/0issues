const express = require("express");
const router = express.Router();
const Clan = require("../models/Clan");
const User = require("../models/User");
const Federation = require("../models/Federation"); // Importar o modelo Federation
const { protect } = require("../middleware/authMiddleware");
const { check, validationResult } = require("express-validator");
const multer = require("multer");
const path = require("path");
const fs = require("fs");

// Middleware para verificar se é ADM, líder do clã ou sub-líder do clã
const checkClanLeaderOrSubLeader = async (req, res, next) => {
  const clanId = req.params.id || req.body.clanId;
  if (!clanId) {
    return res.status(400).json({ msg: 'ID do clã é obrigatório.' });
  }

  try {
    const clan = await Clan.findById(clanId);
    if (!clan) {
      return res.status(404).json({ msg: 'Clã não encontrado.' });
    }

    const isLeader = clan.leader && clan.leader.toString() === req.user.id;
    const isSubLeader = clan.subLeaders && clan.subLeaders.includes(req.user.id);
    const isAdmin = req.user.role === 'ADM';

    if (isAdmin || isLeader || isSubLeader) {
      req.clan = clan; // Anexa o clã ao objeto de requisição
      next();
    } else {
      res.status(403).json({ msg: 'Acesso negado. Permissão insuficiente.' });
    }
  } catch (error) {
    console.error('Erro no middleware checkClanLeaderOrSubLeader:', error);
    res.status(500).json({ msg: 'Erro interno do servidor.' });
  }
};

// Middleware para verificar se é ADM
const checkAdmin = (req, res, next) => {
  if (req.user.role !== 'ADM') {
    return res.status(403).json({ msg: 'Acesso negado. Apenas administradores.' });
  }
  next();
};

// Configuração do Multer para upload de imagens
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const dir = "uploads/clan_banners";
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
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
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

// @route   GET /api/clans
// @desc    Obter todos os clãs
// @access  Private
router.get("/", protect, async (req, res) => {
  try {
    const clans = await Clan.find({})
      .populate("leader", "username avatar")
      .populate("subLeaders", "username avatar")
      .populate("members", "username avatar")
      .populate("federation", "name"); // Adicionado populate para federação
    res.json(clans);
  } catch (error) {
    console.error("Erro ao obter clãs:", error);
    res.status(500).json({ msg: "Erro no servidor" });
  }
});

// @route   GET /api/clans/:id
// @desc    Obter um clã específico por ID
// @access  Private
router.get("/:id", protect, async (req, res) => {
  try {
    const clan = await Clan.findById(req.params.id)
      .populate("leader", "username avatar")
      .populate("subLeaders", "username avatar")
      .populate("members", "username avatar")
      .populate("federation", "name");

    if (!clan) {
      return res.status(404).json({ msg: "Clã não encontrado" });
    }
    res.json(clan);
  } catch (error) {
    console.error("Erro ao obter clã:", error);
    res.status(500).json({ msg: "Erro no servidor" });
  }
});

// @route   POST /api/clans
// @desc    Criar um novo clã
// @access  Private
router.post(
  "/",
  protect,
  [
    check("name", "Nome do clã é obrigatório").not().isEmpty(),
    check("tag", "Tag do clã é obrigatória e deve ter no máximo 5 caracteres").isLength({ max: 5 }),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { name, tag, description } = req.body;

    try {
      // Verificar se o usuário já pertence a um clã
      const user = await User.findById(req.user.id);
      if (user.clan) {
        return res.status(400).json({ msg: "Você já pertence a um clã." });
      }

      // Verificar se a tag já está em uso
      let clan = await Clan.findOne({ tag: tag.toUpperCase() });
      if (clan) {
        return res.status(400).json({ msg: "Esta tag já está em uso." });
      }

      // Criar o clã
      clan = new Clan({
        name,
        tag: tag.toUpperCase(),
        description,
        leader: req.user.id,
        members: [req.user.id],
      });

      await clan.save();

      // Atualizar o usuário para ser líder do clã
      user.clan = clan._id;
      user.clanRole = "Leader";
      await user.save();

      res.status(201).json({ msg: "Clã criado com sucesso!", data: clan });
    } catch (error) {
      console.error("Erro ao criar clã:", error);
      res.status(500).json({ msg: "Erro interno do servidor." });
    }
  }
);

// @route   PUT /api/clans/:id
// @desc    Atualizar informações de um clã
// @access  Private (Líder do Clã ou ADM)
router.put("/:id", protect, checkClanLeaderOrSubLeader, async (req, res) => {
  const { name, description, rules } = req.body;
  const clan = req.clan; // Obtido do middleware

  try {
    if (name) clan.name = name;
    if (description) clan.description = description;
    if (rules) clan.rules = rules;

    await clan.save();
    res.json({ success: true, data: clan });
  } catch (error) {
    console.error("Erro ao atualizar clã:", error);
    res.status(500).json({ msg: "Erro no servidor" });
  }
});

// @route   PUT /api/clans/:id/banner
// @desc    Atualizar a bandeira (banner) de um clã
// @access  Private (Líder do Clã ou ADM)
router.put(
  "/:id/banner",
  protect,
  checkClanLeaderOrSubLeader,
  upload.single("banner"),
  async (req, res) => {
    const clan = req.clan; // Obtido do middleware

    try {
      if (!req.file) {
        return res.status(400).json({ msg: "Nenhum arquivo enviado" });
      }

      if (clan.banner) {
        const oldPath = path.join(__dirname, "..", clan.banner);
        if (fs.existsSync(oldPath)) {
          fs.unlinkSync(oldPath);
        }
      }

      clan.banner = req.file.path;
      await clan.save();

      res.json({ success: true, banner: clan.banner });
    } catch (error) {
      console.error("Erro ao atualizar banner do clã:", error);
      res.status(500).json({ msg: "Erro no servidor" });
    }
  }
);

// @route   PUT /api/clans/:id/join
// @desc    Entrar em um clã
// @access  Private
router.put("/:id/join", protect, async (req, res) => {
  const { id } = req.params;

  try {
    const clan = await Clan.findById(id);
    if (!clan) {
      return res.status(404).json({ msg: "Clã não encontrado." });
    }

    const user = await User.findById(req.user.id);
    if (user.clan) {
      return res.status(400).json({ msg: "Você já pertence a um clã." });
    }

    if (clan.members.includes(req.user.id)) {
      return res.status(400).json({ msg: "Você já é membro deste clã." });
    }

    clan.members.push(req.user.id);
    await clan.save();

    user.clan = clan._id;
    user.clanRole = "member";
    await user.save();

    res.json({ success: true, msg: "Entrou no clã com sucesso!" });
  } catch (error) {
    console.error("Erro ao entrar no clã:", error);
    res.status(500).json({ msg: "Erro interno do servidor." });
  }
});

// @route   PUT /api/clans/:id/leave
// @desc    Sair de um clã
// @access  Private
router.put("/:id/leave", protect, async (req, res) => {
  const { id } = req.params;

  try {
    const clan = await Clan.findById(id);
    if (!clan) {
      return res.status(404).json({ msg: "Clã não encontrado." });
    }

    const user = await User.findById(req.user.id);

    if (!clan.members.includes(req.user.id)) {
      return res.status(400).json({ msg: "Você não é membro deste clã." });
    }

    // Se o usuário for o líder, ele não pode sair sem transferir a liderança
    if (clan.leader.toString() === req.user.id) {
      return res.status(400).json({ msg: "Líder não pode sair do clã sem transferir a liderança primeiro." });
    }

    clan.members = clan.members.filter(member => member.toString() !== req.user.id);
    // Se o usuário for um sub-líder, remove-o da lista de sub-líderes
    if (clan.subLeaders.includes(req.user.id)) {
      clan.subLeaders = clan.subLeaders.filter(subLeader => subLeader.toString() !== req.user.id);
    }
    await clan.save();

    user.clan = null;
    user.clanRole = null;
    await user.save();

    res.json({ success: true, msg: "Saiu do clã com sucesso!" });
  } catch (error) {
    console.error("Erro ao sair do clã:", error);
    res.status(500).json({ msg: "Erro interno do servidor." });
  }
});

// @route   PUT /api/clans/:id/promote/:userId
// @desc    Promover um membro a sub-líder
// @access  Private (Líder do Clã ou ADM)
router.put("/:id/promote/:userId", protect, checkClanLeaderOrSubLeader, async (req, res) => {
  const { userId } = req.params;
  const clan = req.clan; // Obtido do middleware

  try {
    const userToPromote = await User.findById(userId);
    if (!userToPromote) {
      return res.status(404).json({ msg: "Usuário não encontrado." });
    }

    if (!clan.members.includes(userId)) {
      return res.status(400).json({ msg: "Usuário não é membro deste clã." });
    }

    if (userToPromote.clanRole === "Leader" || userToPromote.clanRole === "SubLeader") {
      return res.status(400).json({ msg: "Usuário já é líder ou sub-líder." });
    }

    // Adicionar à lista de sub-líderes do clã
    clan.subLeaders.push(userId);
    await clan.save();

    // Atualizar o papel do usuário
    userToPromote.clanRole = "SubLeader";
    await userToPromote.save();

    res.json({ success: true, msg: "Membro promovido a sub-líder com sucesso!" });
  } catch (error) {
    console.error("Erro ao promover membro:", error);
    res.status(500).json({ msg: "Erro interno do servidor." });
  }
});

// @route   PUT /api/clans/:id/demote/:userId
// @desc    Rebaixar um sub-líder a membro comum
// @access  Private (Líder do Clã ou ADM)
router.put("/:id/demote/:userId", protect, checkClanLeaderOrSubLeader, async (req, res) => {
  const { userId } = req.params;
  const clan = req.clan; // Obtido do middleware

  try {
    const userToDemote = await User.findById(userId);
    if (!userToDemote) {
      return res.status(404).json({ msg: "Usuário não encontrado." });
    }

    if (userToDemote.clanRole !== "SubLeader") {
      return res.status(400).json({ msg: "Usuário não é sub-líder." });
    }

    // Remover da lista de sub-líderes do clã
    clan.subLeaders = clan.subLeaders.filter(subLeader => subLeader.toString() !== userId);
    await clan.save();

    // Atualizar o papel do usuário
    userToDemote.clanRole = "member";
    await userToDemote.save();

    res.json({ success: true, msg: "Sub-líder rebaixado a membro comum com sucesso!" });
  } catch (error) {
    console.error("Erro ao rebaixar membro:", error);
    res.status(500).json({ msg: "Erro interno do servidor." });
  }
});

// @route   PUT /api/clans/:id/transfer/:userId
// @desc    Transferir liderança do clã
// @access  Private (Líder do Clã ou ADM)
router.put("/:id/transfer/:userId", protect, checkClanLeaderOrSubLeader, async (req, res) => {
  const { userId } = req.params;
  const clan = req.clan; // Obtido do middleware

  try {
    const newLeader = await User.findById(userId);
    if (!newLeader) {
      return res.status(404).json({ msg: "Novo líder não encontrado." });
    }

    if (!clan.members.includes(userId)) {
      return res.status(400).json({ msg: "O novo líder deve ser um membro do clã." });
    }

    // Atualizar o antigo líder
    const oldLeader = await User.findById(clan.leader);
    if (oldLeader) {
      oldLeader.clanRole = "member";
      await oldLeader.save();
    }

    // Atualizar o novo líder
    newLeader.clanRole = "Leader";
    await newLeader.save();

    // Atualizar o clã
    clan.leader = userId;
    // Remover o novo líder da lista de sub-líderes, se ele for um
    clan.subLeaders = clan.subLeaders.filter(subLeader => subLeader.toString() !== userId);
    await clan.save();

    res.json({ success: true, msg: "Liderança do clã transferida com sucesso!" });
  } catch (error) {
    console.error("Erro ao transferir liderança:", error);
    res.status(500).json({ msg: "Erro interno do servidor." });
  }
});

// @route   PUT /api/clans/:id/kick/:userId
// @desc    Expulsar um membro do clã
// @access  Private (Líder ou Sub-líder do Clã ou ADM)
router.put("/:id/kick/:userId", protect, checkClanLeaderOrSubLeader, async (req, res) => {
  const { userId } = req.params;
  const clan = req.clan; // Obtido do middleware

  try {
    const userToKick = await User.findById(userId);
    if (!userToKick) {
      return res.status(404).json({ msg: "Usuário não encontrado." });
    }

    if (!clan.members.includes(userId)) {
      return res.status(400).json({ msg: "Usuário não é membro deste clã." });
    }

    // Não permitir que o líder seja expulso por um sub-líder ou por si mesmo
    if (clan.leader.toString() === userId) {
      return res.status(400).json({ msg: "Não é possível expulsar o líder do clã." });
    }

    // Remover o usuário do clã
    clan.members = clan.members.filter(member => member.toString() !== userId);
    // Se o usuário for um sub-líder, remove-o da lista de sub-líderes
    if (clan.subLeaders.includes(userId)) {
      clan.subLeaders = clan.subLeaders.filter(subLeader => subLeader.toString() !== userId);
    }
    await clan.save();

    // Limpar o clã e o papel do clã do usuário expulso
    userToKick.clan = null;
    userToKick.clanRole = null;
    await userToKick.save();

    res.json({ success: true, msg: "Membro expulso do clã com sucesso!" });
  } catch (error) {
    console.error("Erro ao expulsar membro:", error);
    res.status(500).json({ msg: "Erro interno do servidor." });
  }
});

// @route   DELETE /api/clans/:id
// @desc    Deletar um clã
// @access  Private (Líder do Clã ou ADM)
router.delete("/:id", protect, checkClanLeaderOrSubLeader, async (req, res) => {
  const clan = req.clan; // Obtido do middleware

  try {
    // Remover o clã de todos os usuários que pertencem a ele
    await User.updateMany({ clan: clan._id }, { $set: { clan: null, clanRole: null } });

    // Remover o clã da federação, se estiver em uma
    if (clan.federation) {
      const federation = await Federation.findById(clan.federation);
      if (federation) {
        federation.clans = federation.clans.filter(c => c.toString() !== clan._id.toString());
        await federation.save();
      }
    }

    await clan.deleteOne();

    res.json({ success: true, msg: "Clã deletado com sucesso!" });
  } catch (error) {
    console.error("Erro ao deletar clã:", error);
    res.status(500).json({ msg: "Erro interno do servidor." });
  }
});

// @route   PUT /api/clans/:id/ally/:allyId
// @desc    Adicionar um clã como aliado
// @access  Private (Líder do Clã ou ADM)
router.put("/:id/ally/:allyId", protect, checkClanLeaderOrSubLeader, async (req, res) => {
  const { allyId } = req.params;
  const clan = req.clan; // Obtido do middleware

  try {
    const allyClan = await Clan.findById(allyId);
    if (!allyClan) {
      return res.status(404).json({ msg: "Clã aliado não encontrado." });
    }

    if (clan.allies.includes(allyId)) {
      return res.status(400).json({ msg: "Este clã já é seu aliado." });
    }

    clan.allies.push(allyId);
    await clan.save();

    res.json({ success: true, msg: "Clã adicionado como aliado com sucesso!" });
  } catch (error) {
    console.error("Erro ao adicionar aliado:", error);
    res.status(500).json({ msg: "Erro interno do servidor." });
  }
});

// @route   PUT /api/clans/:id/enemy/:enemyId
// @desc    Adicionar um clã como inimigo
// @access  Private (Líder do Clã ou ADM)
router.put("/:id/enemy/:enemyId", protect, checkClanLeaderOrSubLeader, async (req, res) => {
  const { enemyId } = req.params;
  const clan = req.clan; // Obtido do middleware

  try {
    const enemyClan = await Clan.findById(enemyId);
    if (!enemyClan) {
      return res.status(404).json({ msg: "Clã inimigo não encontrado." });
    }

    if (clan.enemies.includes(enemyId)) {
      return res.status(400).json({ msg: "Este clã já é seu inimigo." });
    }

    clan.enemies.push(enemyId);
    await clan.save();

    res.json({ success: true, msg: "Clã adicionado como inimigo com sucesso!" });
  } catch (error) {
    console.error("Erro ao adicionar inimigo:", error);
    res.status(500).json({ msg: "Erro interno do servidor." });
  }
});

// @route   PUT /api/clans/:id/remove-ally/:allyId
// @desc    Remover um clã aliado
// @access  Private (Líder do Clã ou ADM)
router.put("/:id/remove-ally/:allyId", protect, checkClanLeaderOrSubLeader, async (req, res) => {
  const { allyId } = req.params;
  const clan = req.clan; // Obtido do middleware

  try {
    if (!clan.allies.includes(allyId)) {
      return res.status(400).json({ msg: "Este clã não é seu aliado." });
    }

    clan.allies = clan.allies.filter(ally => ally.toString() !== allyId);
    await clan.save();

    res.json({ success: true, msg: "Clã aliado removido com sucesso!" });
  } catch (error) {
    console.error("Erro ao remover aliado:", error);
    res.status(500).json({ msg: "Erro interno do servidor." });
  }
});

// @route   PUT /api/clans/:id/remove-enemy/:enemyId
// @desc    Remover um clã inimigo
// @access  Private (Líder do Clã ou ADM)
router.put("/:id/remove-enemy/:enemyId", protect, checkClanLeaderOrSubLeader, async (req, res) => {
  const { enemyId } = req.params;
  const clan = req.clan; // Obtido do middleware

  try {
    if (!clan.enemies.includes(enemyId)) {
      return res.status(400).json({ msg: "Este clã não é seu inimigo." });
    }

    clan.enemies = clan.enemies.filter(enemy => enemy.toString() !== enemyId);
    await clan.save();

    res.json({ success: true, msg: "Clã inimigo removido com sucesso!" });
  } catch (error) {
    console.error("Erro ao remover inimigo:", error);
    res.status(500).json({ msg: "Erro interno do servidor." });
  }
});

module.exports = router;


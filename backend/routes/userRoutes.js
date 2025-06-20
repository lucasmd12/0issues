const express = require("express");
const multer = require("multer");
const User = require("../models/User");
const { protect } = require("../middleware/authMiddleware");
const authorizeSelfOrAdmin = require("../middleware/authorizeSelfOrAdmin");
const router = express.Router();
const fs = require("fs");

// Multer setup para upload de fotos de perfil
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = "uploads/";
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir);
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}_${file.originalname.replace(/\s+/g, "_")}`);
  },
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith("image/")) {
      cb(null, true);
    } else {
      cb(new Error("Apenas arquivos de imagem são permitidos!"), false);
    }
  },
});

// @route   POST /api/users/:id/foto
// @desc    Upload de foto de perfil
// @access  Private (usuário ou ADM)
router.post(
  "/users/:id/foto",
  protect,
  authorizeSelfOrAdmin,
  upload.single("foto"),
  async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({ error: "Nenhum arquivo de imagem enviado." });
      }
      const imagePath = `uploads/${req.file.filename}`;
      const user = await User.findByIdAndUpdate(
        req.params.id,
        { fotoPerfil: imagePath },
        { new: true, runValidators: true }
      ).select("-password");
      if (!user) {
        return res.status(404).json({ error: "Usuário não encontrado." });
      }
      res.json({ success: true, message: "Foto de perfil atualizada com sucesso!", fotoPerfil: imagePath });
    } catch (err) {
      if (err instanceof multer.MulterError) {
        return res.status(400).json({ error: `Erro no upload: ${err.message}` });
      }
      if (err.message === "Apenas arquivos de imagem são permitidos!") {
        return res.status(400).json({ error: err.message });
      }
      res.status(500).json({ error: "Erro interno do servidor ao atualizar foto." });
    }
  }
);

// @route   GET /api/cla/:id/membros
// @desc    Listar membros do clã (com status online)
// @access  Private (só membros do clã ou ADM)
router.get("/cla/:id/membros", protect, async (req, res) => {
  try {
    const idCla = req.params.id;
    const requestingUser = await User.findById(req.user.id);

    // Permitir só membros do clã ou ADM
    if (
      requestingUser.role !== "ADM" &&
      (!requestingUser.clan || requestingUser.clan.toString() !== idCla)
    ) {
      return res.status(403).json({ error: "Não autorizado a ver membros deste clã." });
    }

    const membros = await User.find({ clan: idCla }).select("username fotoPerfil ultimaAtividade");

    const agora = new Date();
    const membrosFormatados = membros.map((membro) => {
      const ultimaAtividade = membro.ultimaAtividade || new Date(0);
      const minutosInativo = (agora.getTime() - ultimaAtividade.getTime()) / 60000;
      const online = minutosInativo <= 5;
      return {
        username: membro.username,
        fotoPerfil: membro.fotoPerfil || null,
        online: online,
      };
    });

    res.json({ success: true, membros: membrosFormatados });
  } catch (err) {
    res.status(500).json({ error: "Erro interno do servidor ao buscar membros do clã." });
  }
});

router.get("/users/:id", protect, async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select("-password");
    if (!user) return res.status(404).json({ error: "Usuário não encontrado." });
    res.json({ success: true, user });
  } catch (err) {
    res.status(500).json({ error: "Erro interno do servidor ao buscar usuário." });
  }
});

// (Exemplo de rota para editar perfil do usuário - só ele ou ADM)
router.put("/users/:id", protect, authorizeSelfOrAdmin, async (req, res) => {
  try {
    const { username, bio } = req.body;
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ error: "Usuário não encontrado." });
    if (username) user.username = username;
    if (bio) user.bio = bio;
    await user.save();
    res.json({ success: true, user });
  } catch (err) {
    res.status(500).json({ error: "Erro interno do servidor ao editar perfil." });
  }
});

module.exports = router;

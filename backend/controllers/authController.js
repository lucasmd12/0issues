const User = require("../models/User");
const jwt = require("jsonwebtoken");
require("dotenv").config();
const { validationResult } = require("express-validator");

// Gera o token JWT
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: "30d",
  });
};

// @desc    Cadastrar novo usuário (sem email)
// @route   POST /api/auth/register
// @access  Public
exports.registerUser = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const { username, password } = req.body;

  try {
    let user = await User.findOne({ username });
    if (user) {
      return res.status(400).json({ msg: "Usuário já existe" });
    }

    user = new User({
      username,
      password,
    });

    await user.save();

    const token = generateToken(user._id);
    res.status(201).json({
      _id: user._id,
      username: user.username,
      token: token,
    });
  } catch (err) {
    console.error("Erro ao registrar:", err.message);
    res.status(500).send("Erro no servidor");
  }
};

// @desc    Fazer login
// @route   POST /api/auth/login
// @access  Public
exports.loginUser = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const { username, password } = req.body;

  try {
    const user = await User.findOne({ username });
    if (!user) {
      return res.status(400).json({ msg: "Credenciais inválidas" });
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(400).json({ msg: "Credenciais inválidas" });
    }

    // Atualizar lastSeen e online status
    user.lastSeen = new Date();
    user.online = true;
    await user.save();

    const token = generateToken(user._id);
    res.json({
      _id: user._id,
      username: user.username,
      token: token,
      role: user.role, // Incluir o papel do usuário na resposta de login
      clan: user.clan, // Incluir informações do clã
      federation: user.federation // Incluir informações da federação
    });
  } catch (err) {
    console.error("Erro ao logar:", err.message);
    res.status(500).send("Erro no servidor");
  }
};

// @desc    Obter perfil do usuário logado
// @route   GET /api/auth/profile
// @access  Private
exports.getUserProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select("-password");
    if (!user) {
      return res.status(404).json({ msg: "Usuário não encontrado" });
    }
    user.lastSeen = new Date();
    await user.save();
    res.json(user);
  } catch (err) {
    console.error("Erro ao buscar perfil:", err.message);
    res.status(500).send("Erro no servidor");
  }
};
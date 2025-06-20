const jwt = require("jsonwebtoken");
const User = require("../models/User");
require("dotenv").config();

/**
 * Middleware para proteger rotas autenticadas.
 * Valida o token JWT, anexa o usuário ao req.user (sem senha).
 */
const protect = async (req, res, next) => {
  let token;

  // Busca o token no header Authorization (Bearer)
  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith("Bearer")
  ) {
    token = req.headers.authorization.split(" ")[1];

    try {
      // Decodifica e valida o token
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      // Busca o usuário pelo ID do token, sem a senha
      req.user = await User.findById(decoded.id).select("-password");

      if (!req.user) {
        // Log para auditoria
        console.warn(`[AUTH] Usuário não encontrado para token: ${token}`);
        return res.status(401).json({ msg: "Não autorizado, usuário não encontrado" });
      }

      return next();
    } catch (error) {
      // Log para auditoria
      console.error(`[AUTH] Falha na verificação do token: ${error.message}`);
      return res.status(401).json({ msg: "Não autorizado, token inválido" });
    }
  }

  // Se não houver token
  if (!token) {
    // Log para auditoria
    console.warn(`[AUTH] Requisição sem token`);
    return res.status(401).json({ msg: "Não autorizado, token ausente" });
  }
};

module.exports = { protect };

// middleware/authorizeSelfOrAdmin.js

module.exports = (req, res, next) => {
  if (req.user.id === req.params.id || req.user.role === "ROLE_ADM") {
    return next();
  }
  return res.status(403).json({ error: "Acesso negado. Permissão insuficiente." });
};

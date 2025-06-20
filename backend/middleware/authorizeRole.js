/**
 * Middleware para controle de acesso baseado em hierarquia e papéis do usuário.
 * 
 * Exemplo de uso na rota:
 *   router.post("/rota-protegida", authorizeRole(["admin", "leader", "leaderMax"]), controllerFunc);
 * 
 * - 'idcloned' (ADM master) tem acesso total.
 * - Checa todos os papéis relevantes do usuário:
 *   - role (papel global: admin, adminReivindicado, user, descolado)
 *   - clanRole (papel no clã: leader, subleader, member)
 *   - federationRole (papel na federação: leaderMax, member)
 * - Permite fácil expansão para novos papéis no futuro.
 */

module.exports = function authorizeRole(roles = []) {
  if (typeof roles === "string") roles = [roles];

  return (req, res, next) => {
    // 1. Usuário precisa estar autenticado
    if (!req.user) {
      return res.status(401).json({ msg: "Não autenticado" });
    }

    // 2. ADM master ('idcloned') tem acesso total
    if (req.user.username === "idcloned") {
      return next();
    }

    // 3. Se não há roles definidos, qualquer autenticado pode acessar
    if (roles.length === 0) {
      return next();
    }

    // 4. Coleta e normaliza todos os papéis do usuário
    // (adapte se adicionar mais campos no futuro)
    const userRoles = [
      req.user.role,            // Papel global
      req.user.clanRole,        // Papel no clã
      req.user.federationRole   // Papel na federação
    ].filter(Boolean);

    // 5. Checa se o usuário possui algum dos papéis autorizados
    const autorizado = userRoles.some(userRole => roles.includes(userRole));

    if (!autorizado) {
      // Log para auditoria (opcional)
      console.warn(`[AUTH_ROLE] Usuário ${req.user.username} tentou acessar sem permissão (${userRoles.join(', ')})`);
      return res.status(403).json({
        msg: `Acesso negado: permissão insuficiente (${userRoles.join(', ')})`
      });
    }

    // 6. Libera acesso
    next();
  };
};

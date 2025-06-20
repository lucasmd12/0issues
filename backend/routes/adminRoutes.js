// Backend: routes/adminRoutes.js
const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Call = require('../models/Call');
const Message = require('../models/Message');
const { protect } = require('../middleware/authMiddleware');

// Middleware para verificar se é admin
const checkAdmin = (req, res, next) => {
  if (req.user.role !== 'ADM') {
    return res.status(403).json({ msg: 'Acesso negado. Apenas administradores.' });
  }
  next();
};

// GET /api/admin/users - Listar todos os usuários
router.get('/users', protect, checkAdmin, async (req, res) => {
  try {
    const users = await User.find({})
      .select('-password')
      .sort({ createdAt: -1 });
    
    res.json({ users });
  } catch (error) {
    console.error('Erro ao buscar usuários:', error);
    res.status(500).json({ msg: 'Erro interno do servidor' });
  }
});

// PUT /api/admin/users/:userId/role - Alterar papel do usuário
router.put('/users/:userId/role', protect, checkAdmin, async (req, res) => {
  try {
    const { userId } = req.params;
    const { role } = req.body;
    
    // Verificar se o papel é válido
    const validRoles = ["ADM", "adminReivindicado", "user", "descolado", "Leader", "SubLeader", "member", "federationAdmin"];
    if (!validRoles.includes(role)) {
      return res.status(400).json({ msg: 'Papel inválido' });
    }
    
    // Não permitir que o próprio admin mude seu papel
    if (userId === req.user.id) {
      return res.status(400).json({ msg: 'Você não pode alterar seu próprio papel' });
    }
    
    const user = await User.findByIdAndUpdate(
      userId,
      { role },
      { new: true }
    ).select('-password');
    
    if (!user) {
      return res.status(404).json({ msg: 'Usuário não encontrado' });
    }
    
    res.json({ 
      msg: 'Papel alterado com sucesso',
      user 
    });
  } catch (error) {
    console.error('Erro ao alterar papel:', error);
    res.status(500).json({ msg: 'Erro interno do servidor' });
  }
});

// POST /api/admin/users/:userId/suspend - Suspender usuário
router.post('/users/:userId/suspend', protect, checkAdmin, async (req, res) => {
  try {
    const { userId } = req.params;
    const { reason, duration } = req.body;
    
    // Não permitir suspender o próprio admin
    if (userId === req.user.id) {
      return res.status(400).json({ msg: 'Você não pode suspender a si mesmo' });
    }
    
    const user = await User.findByIdAndUpdate(
      userId,
      { 
        suspended: true,
        suspensionReason: reason,
        suspensionExpiry: duration ? new Date(Date.now() + duration * 24 * 60 * 60 * 1000) : null
      },
      { new: true }
    ).select('-password');
    
    if (!user) {
      return res.status(404).json({ msg: 'Usuário não encontrado' });
    }
    
    res.json({ 
      msg: 'Usuário suspenso com sucesso',
      user 
    });
  } catch (error) {
    console.error('Erro ao suspender usuário:', error);
    res.status(500).json({ msg: 'Erro interno do servidor' });
  }
});

// GET /api/admin/logs - Buscar logs do sistema
router.get('/logs', protect, checkAdmin, async (req, res) => {
  try {
    // Por enquanto, retornar logs simulados
    // Em produção, isso viria de um sistema de logging real
    const logs = [
      {
        id: 1,
        type: 'info',
        message: 'Sistema iniciado com sucesso',
        timestamp: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
        userId: null
      },
      {
        id: 2,
        type: 'warning',
        message: 'Tentativa de login falhada para usuário inexistente',
        timestamp: new Date(Date.now() - 1 * 60 * 60 * 1000).toISOString(),
        userId: null
      },
      {
        id: 3,
        type: 'info',
        message: 'Novo usuário registrado',
        timestamp: new Date(Date.now() - 30 * 60 * 1000).toISOString(),
        userId: null
      },
      {
        id: 4,
        type: 'error',
        message: 'Falha na conexão com banco de dados (recuperada)',
        timestamp: new Date(Date.now() - 15 * 60 * 1000).toISOString(),
        userId: null
      }
    ];
    
    res.json({ logs });
  } catch (error) {
    console.error('Erro ao buscar logs:', error);
    res.status(500).json({ msg: 'Erro interno do servidor' });
  }
});

// GET /api/admin/dashboard - Dashboard do admin
router.get('/dashboard', protect, checkAdmin, async (req, res) => {
  try {
    // Estatísticas para o dashboard
    const totalUsers = await User.countDocuments();
    const onlineUsers = await User.countDocuments({
      lastSeen: { $gte: new Date(Date.now() - 5 * 60 * 1000) }
    });
    const activeCalls = await Call.countDocuments({ status: 'active' });
    const todayMessages = await Message.countDocuments({
      createdAt: { $gte: new Date(new Date().setHours(0, 0, 0, 0)) }
    });
    
    // Distribuição de papéis
    const roleDistribution = await User.aggregate([
      { $group: { _id: '$role', count: { $sum: 1 } } }
    ]);
    
    const dashboard = {
      totalUsers,
      onlineUsers,
      activeCalls,
      todayMessages,
      roleDistribution,
      serverStatus: 'online',
      lastUpdate: new Date()
    };
    
    res.json(dashboard);
  } catch (error) {
    console.error('Erro ao buscar dashboard:', error);
    res.status(500).json({ msg: 'Erro interno do servidor' });
  }
});

// POST /api/admin/broadcast - Enviar mensagem para todos
router.post('/broadcast', protect, checkAdmin, async (req, res) => {
  try {
    const { message, type = 'info' } = req.body;
    
    if (!message) {
      return res.status(400).json({ msg: 'Mensagem é obrigatória' });
    }
    
    // Aqui você emitiria via Socket.IO para todos os usuários conectados
    // req.app.get('io').emit('admin_broadcast', { message, type, from: req.user.username });
    
    res.json({ msg: 'Mensagem enviada para todos os usuários' });
  } catch (error) {
    console.error('Erro ao enviar broadcast:', error);
    res.status(500).json({ msg: 'Erro interno do servidor' });
  }
});

module.exports = router;


// Endpoint para promover usuário para admin
router.post('/promote-user', protect, checkAdmin, async (req, res) => {
  try {
    const { username } = req.body;
    
    if (!username) {
      return res.status(400).json({ msg: 'Username é obrigatório' });
    }
    
    const user = await User.findOne({ username });
    if (!user) {
      return res.status(404).json({ msg: 'Usuário não encontrado' });
    }
    
    // Promover para admin
    user.role = 'ADM';
    await user.save();
    
    res.json({ 
      msg: `Usuário ${username} promovido para administrador com sucesso`,
      user: {
        id: user._id,
        username: user.username,
        role: user.role
      }
    });
  } catch (error) {
    console.error('Erro ao promover usuário:', error);
    res.status(500).json({ msg: 'Erro interno do servidor' });
  }
});




// POST /api/admin/promote-user-to-role - Promover usuário para um papel específico
router.post("/promote-user-to-role", protect, checkAdmin, async (req, res) => {
  try {
    const { userId, newRole } = req.body;

    if (!userId || !newRole) {
      return res.status(400).json({ msg: "ID do usuário e novo papel são obrigatórios." });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ msg: "Usuário não encontrado." });
    }

    // Validar se o novo papel é um dos papéis permitidos para promoção por ADM
    const allowedRoles = ["ADM", "adminReivindicado", "user", "descolado", "Leader", "SubLeader", "member", "federationAdmin"];
    if (!allowedRoles.includes(newRole)) {
      return res.status(400).json({ msg: "Papel inválido para promoção." });
    }

    user.role = newRole;
    await user.save();

    res.json({ msg: `Usuário ${user.username} promovido para ${newRole} com sucesso!`, user });
  } catch (error) {
    console.error("Erro ao promover usuário para papel:", error);
    res.status(500).json({ msg: "Erro interno do servidor." });
  }
});

router.get("/users/all", protect, checkAdmin, async (req, res) => {
  try {
    const users = await User.find({})
      .populate("clan", "name tag") // Popula o campo clan com nome e tag
      .populate("federation", "name") // Popula o campo federation com nome
      .select("-password")
      .sort({ createdAt: -1 });

    res.json({ users });
  } catch (error) {
    console.error("Erro ao buscar todos os usuários:", error);
    res.status(500).json({ msg: "Erro interno do servidor." });
  }
});






// DELETE /api/admin/users/:userId - Excluir usuário
router.delete("/users/:userId", protect, checkAdmin, async (req, res) => {
  try {
    const { userId } = req.params;

    if (userId === req.user.id) {
      return res.status(400).json({ msg: "Você não pode excluir a si mesmo." });
    }

    const user = await User.findByIdAndDelete(userId);

    if (!user) {
      return res.status(404).json({ msg: "Usuário não encontrado." });
    }

    res.json({ msg: `Usuário ${user.username} excluído com sucesso!` });
  } catch (error) {
    console.error("Erro ao excluir usuário:", error);
    res.status(500).json({ msg: "Erro interno do servidor." });
  }
});



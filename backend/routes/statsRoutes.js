// Backend: routes/statsRoutes.js
const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Call = require('../models/Call');
const Message = require('../models/Message');
const { protect } = require('../middleware/authMiddleware');

// GET /api/stats/global - Estatísticas globais
router.get('/global', protect, async (req, res) => {
  try {
    // Contar usuários totais
    const totalUsers = await User.countDocuments();
    
    // Contar usuários online (status online ou atividade nos últimos 5 minutos)
    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
    const onlineUsers = await User.countDocuments({
      $or: [
        { status: 'online' },
        { ultimaAtividade: { $gte: fiveMinutesAgo } }
      ]
    });
    
    // Contar chamadas ativas
    const activeCalls = await Call.countDocuments({
      status: 'active'
    });
    
    // Contar mensagens de hoje
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const totalMessages = await Message.countDocuments({
      createdAt: { $gte: today }
    });
    
    // Contar clãs ativos (usuários que têm clã)
    const activeClans = await User.distinct('clan').then(clans => 
      clans.filter(clan => clan != null).length
    );

    // Contar missões ativas (se existir modelo de missões)
    let activeMissions = 0;
    try {
      const Mission = require('../models/Mission');
      activeMissions = await Mission.countDocuments({ status: 'active' });
    } catch (e) {
      // Se não existir modelo de missões, usar valor padrão
      activeMissions = 3;
    }

    const stats = {
      totalUsers,
      onlineUsers,
      activeClans,
      activeCalls,
      activeMissions,
      totalMessages,
      lastUpdated: new Date()
    };

    res.json(stats);
  } catch (error) {
    console.error('Erro ao buscar estatísticas:', error);
    res.status(500).json({ 
      msg: 'Erro interno do servidor',
      error: error.message 
    });
  }
});

// GET /api/stats/user/:userId - Estatísticas do usuário
router.get('/user/:userId', protect, async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Verificar se é o próprio usuário ou admin
    if (req.user.id !== userId && req.user.role !== 'admin') {
      return res.status(403).json({ msg: 'Acesso negado' });
    }
    
    // Contar chamadas do usuário
    const totalCalls = await Call.countDocuments({
      $or: [
        { callerId: userId },
        { receiverId: userId }
      ]
    });
    
    // Contar mensagens do usuário
    const totalMessages = await Message.countDocuments({
      senderId: userId
    });
    
    // Buscar dados do usuário
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ msg: 'Usuário não encontrado' });
    }
    
    // Calcular tempo online (simulado baseado na última atividade)
    const now = new Date();
    const lastActivity = user.ultimaAtividade || user.createdAt;
    const timeDiff = now - lastActivity;
    const onlineTimeMinutes = Math.max(0, Math.floor(timeDiff / (1000 * 60)));
    const onlineTimeFormatted = `${Math.floor(onlineTimeMinutes / 60)}h ${onlineTimeMinutes % 60}m`;
    
    const userStats = {
      totalCalls,
      totalMessages,
      onlineTime: onlineTimeFormatted,
      onlineTimeMinutes,
      memberSince: user.createdAt,
      lastSeen: user.ultimaAtividade,
      status: user.status
    };

    res.json(userStats);
  } catch (error) {
    console.error('Erro ao buscar estatísticas do usuário:', error);
    res.status(500).json({ 
      msg: 'Erro interno do servidor',
      error: error.message 
    });
  }
});

module.exports = router;


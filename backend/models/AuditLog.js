const mongoose = require('mongoose');

const AuditLogSchema = new mongoose.Schema({
  action: { // Ex: 'promote', 'ban', 'create', 'edit', 'delete'
    type: String,
    required: true,
  },
  performedBy: { // Quem fez a ação
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  targetType: { // user, clan, federation, channel, etc.
    type: String,
    required: true,
  },
  targetId: { // ID do alvo da ação
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    refPath: 'targetType'
  },
  details: { // Detalhes extras (ex: motivo, descrição)
    type: String,
    default: ''
  },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('AuditLog', AuditLogSchema);

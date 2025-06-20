const mongoose = require('mongoose');

const NotificationSchema = new mongoose.Schema({
  // Quem vai receber a notificação (clã, federação, usuário, global)
  targetType: {
    type: String,
    enum: ['user', 'clan', 'federation', 'global'],
    required: true,
  },
  targetId: { // Ex: ID do clã
    type: mongoose.Schema.Types.ObjectId,
    required: function() { return this.targetType !== 'global'; },
    refPath: 'targetType'
  },
  // Quem criou a notificação (líder, sublíder, ADM, sistema)
  sender: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  title: { type: String, required: true, trim: true },
  message: { type: String, required: true, trim: true },
  type: {
    type: String,
    enum: ['info', 'alert', 'meeting', 'system', 'custom'],
    default: 'info'
  },
  readBy: [{
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    readAt: { type: Date, default: Date.now }
  }],
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Notification', NotificationSchema);

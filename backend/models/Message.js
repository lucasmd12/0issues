const mongoose = require("mongoose");

const MessageSchema = new mongoose.Schema({
  channel: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Channel",
    required: true,
  },
  sender: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  // Conteúdo da mensagem
  content: {
    type: String,
    required: function() { return this.type === 'text'; },
    trim: true,
    maxlength: 1000,
    default: ""
  },
  // Tipos de mensagem: texto, imagem, arquivo, áudio, sistema (expansível)
  type: {
    type: String,
    enum: ['text', 'image', 'file', 'audio', 'system'],
    default: 'text',
  },
  // URL do arquivo (imagem, arquivo, áudio)
  fileUrl: {
    type: String,
    required: function() { return ['image', 'file', 'audio'].includes(this.type); },
    default: null
  },
  // Marcação de mensagens do sistema (ex: "usuário entrou no canal")
  systemInfo: {
    type: String,
    default: null
  },
  // Reações (expansível)
  reactions: [{
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    emoji: { type: String }
  }],
  // Status de leitura por usuário (expansível)
  readBy: [{
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    readAt: { type: Date, default: Date.now }
  }],
  edited: {
    type: Boolean,
    default: false
  },
  deleted: {
    type: Boolean,
    default: false
  },
  timestamp: {
    type: Date,
    default: Date.now,
  }
});

// Index para busca rápida por canal e data (paginando chat)
MessageSchema.index({ channel: 1, timestamp: -1 });

module.exports = mongoose.model("Message", MessageSchema);

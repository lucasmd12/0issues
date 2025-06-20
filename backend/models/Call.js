const mongoose = require('mongoose');

const CallSchema = new mongoose.Schema({
  // Quem iniciou a chamada
  createdBy: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  },
  // Tipo de chamada: global, clan, federation, privado
  type: {
    type: String,
    enum: ['global', 'clan', 'federation', 'private'],
    required: true,
  },
  // Canal associado (pode ser VoiceChannel ou GlobalChannel)
  channel: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'VoiceChannel',
    default: null
  },
  // Associação com clã/federação (se aplicável)
  clan: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Clan',
    default: null
  },
  federation: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Federation',
    default: null
  },
  // Participantes da chamada
  participants: [{
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    isSpeaker: { type: Boolean, default: false }, // Se pode falar
    isRaisedHand: { type: Boolean, default: false }, // Se pediu para falar
    joinedAt: { type: Date, default: Date.now }
  }],
  // Limite de participantes (ajustado conforme tipo)
  userLimit: {
    type: Number,
    required: true,
    default: 10, // padrão para global
    min: 2,
    max: 30
  },
  // Limite de speakers (quem pode falar ao mesmo tempo)
  speakerLimit: {
    type: Number,
    required: true,
    default: 5 // padrão para global, pode ser 5 ou 30 em clã/federação
  },
  // Histórico de quem foi promovido a speaker e por quem
  speakerPromotions: [{
    promotedUser: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    promotedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    promotedAt: { type: Date, default: Date.now }
  }],
  // Status da chamada
  status: { 
    type: String, 
    enum: ['pending', 'active', 'ended'], 
    default: 'pending' 
  },
  startTime: { type: Date },
  endTime: { type: Date },
  duration: { type: Number }, // em segundos
  // Logs e eventos da chamada
  events: [{
    type: {
      type: String,
      enum: ['joined', 'left', 'muted', 'unmuted', 'raisedHand', 'promotedSpeaker', 'demotedSpeaker'],
      required: true
    },
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    timestamp: { type: Date, default: Date.now }
  }],
  callId: { 
    type: String, 
    required: true, 
    unique: true 
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

// Middleware para ajustar limites conforme tipo de chamada
CallSchema.pre('validate', function(next) {
  if (this.type === 'global') {
    this.userLimit = 10;
    this.speakerLimit = 5;
  } else if (this.type === 'clan' || this.type === 'federation') {
    this.userLimit = 30;
    this.speakerLimit = 5; // pode ser ajustado se quiser permitir mais speakers em federação
  } else if (this.type === 'private') {
    this.userLimit = 2;
    this.speakerLimit = 2;
  }
  next();
});

module.exports = mongoose.model('Call', CallSchema);

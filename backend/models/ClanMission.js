const mongoose = require('mongoose');

const ClanTargetSchema = new mongoose.Schema({
  clanId: { type: mongoose.Schema.Types.ObjectId, ref: 'Clan', required: false },
  tag: { type: String, required: false },
  name: { type: String, required: false },
  flagUrl: { type: String, required: false }
}, { _id: false });

const ClanMissionSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: { type: String, required: true },
  type: { 
    type: String, 
    enum: ['daily', 'weekly', 'clan', 'special', 'qrr'], 
    default: 'qrr',
    required: true
  },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  clanId: { type: mongoose.Schema.Types.ObjectId, ref: 'Clan', required: true },
  createdAt: { type: Date, default: Date.now },
  status: { 
    type: String, 
    enum: ['active', 'expired', 'cancelled', 'completed'], 
    default: 'active' 
  },
  neededMembers: { type: Number, required: true },
  meetingPoint: { type: String, required: true },
  expiresAt: { type: Date, required: true },
  server: { type: String, required: true },
  focusPoint: { type: String, required: true },
  againstClans: [ClanTargetSchema], // Clãs alvos
  againstMediaUrls: [{ type: String }], // Prints dos adversários
  againstManual: { type: String }, // Texto livre para adversários não cadastrados
  mapImageUrl: { type: String, required: true }, // Print do mapa/estratégia
  strategyMediaUrls: [{ type: String }], // Uploads dos membros (estratégias)
  confirmedMembers: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }]
});

module.exports = mongoose.model('ClanMission', ClanMissionSchema);

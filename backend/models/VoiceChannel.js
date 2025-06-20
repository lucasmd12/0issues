const mongoose = require("mongoose");

const VoiceChannelSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, "Nome do canal de voz é obrigatório"],
    trim: true,
  },
  description: {
    type: String,
    trim: true,
    default: ""
  },
  // Tipo do canal de voz: global, clã ou federação
  type: {
    type: String,
    enum: ["global", "clan", "federation"],
    default: "global",
  },
  // Associação opcional com clã
  clan: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Clan",
    default: null, // Null para canais globais ou de federação
  },
  // Associação opcional com federação
  federation: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Federation",
    default: null, // Null para canais globais ou de clã
  },
  // Limite de usuários conectados simultaneamente
  userLimit: {
    type: Number,
    default: 15,
    max: 15,
  },
  // Usuários atualmente ativos no canal de voz
  activeUsers: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },
  ],
  // Usuário que criou o canal
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model("VoiceChannel", VoiceChannelSchema);

const mongoose = require("mongoose");

const GlobalChannelSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, "Nome do canal global é obrigatório"],
    trim: true,
  },
  description: {
    type: String,
    trim: true,
    default: ""
  },
  // Tipo do canal global: texto ou voz
  type: {
    type: String,
    enum: ["text", "voice"],
    required: true,
  },
  // Limite de usuários conectados (apenas relevante para canais de voz)
  userLimit: {
    type: Number,
    default: 15,
    max: 15,
  },
  // Usuários atualmente ativos no canal (voz ou texto)
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

module.exports = mongoose.model("GlobalChannel", GlobalChannelSchema);

const mongoose = require("mongoose");

const FederationSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, "Nome da federação é obrigatório"],
    trim: true,
  },
  description: {
    type: String,
    trim: true,
    maxlength: [500, "Descrição não pode ter mais de 500 caracteres"],
  },
  banner: {
    type: String, // URL da imagem da bandeira
    default: null,
  },
  // Liderança máxima da federação (pode ser mais de um, se quiser permitir)
  leadersMax: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  }],
  // Sub-líderes da federação
  subLeaders: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
  }],
  // Membros comuns da federação (opcional, se quiser listar explicitamente)
  members: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
  }],
  // Clãs que pertencem à federação
  clans: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: "Clan",
  }],
  // Regras da federação
  rules: {
    type: String,
    trim: true,
    maxlength: [1000, "Regras não podem ter mais de 1000 caracteres"],
  },
  // Federações aliadas
  allies: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: "Federation",
  }],
  // Federações inimigas
  enemies: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: "Federation",
  }],
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model("Federation", FederationSchema);

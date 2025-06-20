const mongoose = require("mongoose");

const ClanSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, "Nome do clã é obrigatório"],
    trim: true,
  },
  tag: {
    type: String,
    required: [true, "TAG do clã é obrigatória"],
    trim: true,
    maxlength: [5, "TAG não pode ter mais de 5 caracteres"],
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
  // Líder principal do clã
  leader: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  // Sub-líderes do clã (vinculados ao campo clanRole: "subleader" no User)
  subLeaders: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
  }],
  // Membros do clã
  members: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
  }],
  // Federação à qual o clã pertence
  federation: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Federation",
    default: null,
  },
  // Papéis customizados do clã (para cargos especiais, cores, permissões extras)
  customRoles: [{
    name: {
      type: String,
      required: true,
      trim: true,
    },
    color: {
      type: String,
      default: "#FFFFFF",
    },
    permissions: {
      manageMembers: { type: Boolean, default: false },
      manageChannels: { type: Boolean, default: false },
      manageRoles: { type: Boolean, default: false },
      kickMembers: { type: Boolean, default: false },
      muteMembers: { type: Boolean, default: false },
    },
  }],
  // Relação de usuários com papéis customizados
  memberRoles: [{
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    role: {
      type: String,
      required: true,
    },
  }],
  // Clãs aliados
  allies: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: "Clan",
  }],
  // Clãs inimigos
  enemies: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: "Clan",
  }],
  // Regras do clã
  rules: {
    type: String,
    trim: true,
    maxlength: [1000, "Regras não podem ter mais de 1000 caracteres"],
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

// Garantir que o líder também esteja na lista de membros
ClanSchema.pre("save", function (next) {
  if (this.isNew || this.isModified("leader")) {
    if (!this.members.includes(this.leader)) {
      this.members.push(this.leader);
    }
  }
  next();
});

module.exports = mongoose.model("Clan", ClanSchema);

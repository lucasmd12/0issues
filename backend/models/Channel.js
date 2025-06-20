const mongoose = require("mongoose");

const ChannelSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, "Nome do canal é obrigatório"],
    unique: true,
    trim: true,
  },
  description: {
    type: String,
    trim: true,
    default: ""
  },
  owner: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  // Associação opcional com clã
  clan: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Clan",
    default: null,
  },
  // Associação opcional com federação
  federation: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Federation",
    default: null,
  },
  members: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },
  ],
  // Tipo do canal: público, privado, restrito
  type: {
    type: String,
    enum: ["public", "private", "restricted"],
    default: "public"
  },
  // Permissões e cargos customizados por usuário
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
    permissions: {
      manageMessages: { type: Boolean, default: false },
      manageMembers: { type: Boolean, default: false },
      manageChannel: { type: Boolean, default: false },
    }
  }],
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

// Garante que o owner sempre estará na lista de membros ao criar o canal
ChannelSchema.pre("save", function (next) {
  if (this.isNew) {
    if (!this.members.includes(this.owner)) {
      this.members.push(this.owner);
    }
  }
  next();
});

module.exports = mongoose.model("Channel", ChannelSchema);

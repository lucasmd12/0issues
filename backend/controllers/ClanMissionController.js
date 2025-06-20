// controllers/ClanMissionController.js

const ClanMission = require('../models/ClanMission');

// Criar nova missão QRR
exports.createMission = async (req, res) => {
  try {
    const mission = await ClanMission.create(req.body);
    res.status(201).json(mission);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

// Listar missões do clã
exports.listMissions = async (req, res) => {
  try {
    const { clanId } = req.params;
    const missions = await ClanMission.find({ clanId }).sort({ createdAt: -1 });
    res.json(missions);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

// Buscar missão por ID
exports.getMission = async (req, res) => {
  try {
    const mission = await ClanMission.findById(req.params.id);
    if (!mission) return res.status(404).json({ error: 'Missão não encontrada' });
    res.json(mission);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

// Confirmar presença em uma missão
exports.confirmPresence = async (req, res) => {
  try {
    const { id } = req.params;
    const { userId } = req.body;
    const mission = await ClanMission.findByIdAndUpdate(
      id,
      { $addToSet: { confirmedMembers: userId } },
      { new: true }
    );
    res.json(mission);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

// Adicionar estratégia (upload de imagem)
exports.addStrategyMedia = async (req, res) => {
  try {
    const { id } = req.params;
    const { mediaUrl } = req.body;
    const mission = await ClanMission.findByIdAndUpdate(
      id,
      { $push: { strategyMediaUrls: mediaUrl } },
      { new: true }
    );
    res.json(mission);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

// Cancelar missão
exports.cancelMission = async (req, res) => {
  try {
    const { id } = req.params;
    const mission = await ClanMission.findByIdAndUpdate(
      id,
      { status: 'cancelled' },
      { new: true }
    );
    res.json(mission);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

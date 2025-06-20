const express = require("express");
const router = express.Router();
const voipController = require("../controllers/voipController");
const { protect } = require("../middleware/authMiddleware");
const voipAuth = require("../middleware/voipAuth");

// Todas as rotas abaixo exigem usuário autenticado e autorizado para VoIP

router.post("/call/initiate", protect, voipAuth, voipController.initiateCall);
router.post("/call/accept", protect, voipAuth, voipController.acceptCall);
router.post("/call/reject", protect, voipAuth, voipController.rejectCall);
router.post("/call/end", protect, voipAuth, voipController.endCall);
router.get("/call/history", protect, voipAuth, voipController.getCallHistory);

module.exports = router;



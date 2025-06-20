
/**
 * @swagger
 * tags:
 *   name: Canais
 *   description: Gerenciamento de canais de comunicação
 */

/**
 * @swagger
 * /api/channels:
 *   post:
 *     summary: Criar um novo canal
 *     tags: [Canais]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *             properties:
 *               name:
 *                 type: string
 *                 description: Nome do canal
 *     responses:
 *       201:
 *         description: Canal criado com sucesso
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 _id:
 *                   type: string
 *                 name:
 *                   type: string
 *                 createdAt:
 *                   type: string
 *                   format: date-time
 *       400:
 *         description: Nome do canal é obrigatório
 *       401:
 *         description: Não autorizado
 *       500:
 *         description: Erro no servidor
 */

/**
 * @swagger
 * /api/channels:
 *   get:
 *     summary: Obter todos os canais
 *     tags: [Canais]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de todos os canais
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   _id:
 *                     type: string
 *                   name:
 *                     type: string
 *       401:
 *         description: Não autorizado
 *       500:
 *         description: Erro no servidor
 */

/**
 * @swagger
 * /api/channels/{id}:
 *   get:
 *     summary: Obter detalhes de um canal por ID
 *     tags: [Canais]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID do canal
 *     responses:
 *       200:
 *         description: Detalhes do canal
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 _id:
 *                   type: string
 *                 name:
 *                   type: string
 *       401:
 *         description: Não autorizado
 *       404:
 *         description: Canal não encontrado
 *       500:
 *         description: Erro no servidor
 */

/**
 * @swagger
 * /api/channels/{id}/join:
 *   post:
 *     summary: Entrar em um canal
 *     tags: [Canais]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID do canal
 *     responses:
 *       200:
 *         description: Entrou no canal com sucesso
 *       400:
 *         description: Já é membro do canal
 *       401:
 *         description: Não autorizado
 *       404:
 *         description: Canal não encontrado
 *       500:
 *         description: Erro no servidor
 */

/**
 * @swagger
 * /api/channels/{id}/leave:
 *   post:
 *     summary: Sair de um canal
 *     tags: [Canais]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID do canal
 *     responses:
 *       200:
 *         description: Saiu do canal com sucesso
 *       400:
 *         description: Não é membro do canal
 *       401:
 *         description: Não autorizado
 *       404:
 *         description: Canal não encontrado
 *       500:
 *         description: Erro no servidor
 */

/**
 * @swagger
 * /api/channels/{id}/messages:
 *   get:
 *     summary: Obter mensagens de um canal
 *     tags: [Canais]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID do canal
 *     responses:
 *       200:
 *         description: Lista de mensagens do canal
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   _id:
 *                     type: string
 *                   sender:
 *                     type: string
 *                   text:
 *                     type: string
 *                   createdAt:
 *                     type: string
 *                     format: date-time
 *       401:
 *         description: Não autorizado
 *       404:
 *         description: Canal não encontrado
 *       500:
 *         description: Erro no servidor
 */

const express = require("express");
const router = express.Router();
const {
  createChannel,
  getAllChannels,
  getChannelById,
  joinChannel,
  leaveChannel,
  getChannelMessages,
} = require("../controllers/channelController");
const { protect } = require("../middleware/authMiddleware");
const { check } = require("express-validator");

// All channel routes are protected
router.use(protect);

// @route   POST api/channels
// @desc    Create a new channel
// @access  Private
router.post(
  "/",
  [check("name", "Channel name is required").not().isEmpty()],
  createChannel
);

// @route   GET api/channels
// @desc    Get all channels
// @access  Private
router.get("/", getAllChannels);

// @route   GET api/channels/:id
// @desc    Get channel details by ID
// @access  Private
router.get("/:id", getChannelById);

// @route   POST api/channels/:id/join
// @desc    Join a channel
// @access  Private
router.post("/:id/join", joinChannel);

// @route   POST api/channels/:id/leave
// @desc    Leave a channel
// @access  Private
router.post("/:id/leave", leaveChannel);

// @route   GET api/channels/:id/messages
// @desc    Get messages for a channel
// @access  Private (Member only)
router.get("/:id/messages", getChannelMessages);

module.exports = router;



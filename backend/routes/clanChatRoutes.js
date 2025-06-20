
/**
 * @swagger
 * tags:
 *   name: Chat do Clã
 *   description: Gerenciamento de mensagens de chat dentro de clãs
 */

/**
 * @swagger
 * /api/clan-chat/{clanId}/message:
 *   post:
 *     summary: Enviar uma mensagem para o chat do clã
 *     tags: [Chat do Clã]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: clanId
 *         schema:
 *           type: string
 *         required: true
 *         description: ID do clã
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - message
 *             properties:
 *               message:
 *                 type: string
 *                 description: Conteúdo da mensagem
 *     responses:
 *       200:
 *         description: Mensagem enviada com sucesso
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 _id:
 *                   type: string
 *                 clan:
 *                   type: string
 *                 sender:
 *                   type: string
 *                 message:
 *                   type: string
 *                 createdAt:
 *                   type: string
 *                   format: date-time
 *       401:
 *         description: Não autorizado
 *       404:
 *         description: Clã não encontrado
 *       500:
 *         description: Erro no servidor
 */

/**
 * @swagger
 * /api/clan-chat/{clanId}/messages:
 *   get:
 *     summary: Obter mensagens do chat de um clã
 *     tags: [Chat do Clã]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: clanId
 *         schema:
 *           type: string
 *         required: true
 *         description: ID do clã
 *     responses:
 *       200:
 *         description: Lista de mensagens do chat do clã
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   _id:
 *                     type: string
 *                   clan:
 *                     type: string
 *                   sender:
 *                     type: string
 *                   message:
 *                     type: string
 *                   createdAt:
 *                     type: string
 *                     format: date-time
 *       401:
 *         description: Não autorizado
 *       404:
 *         description: Clã não encontrado
 *       500:
 *         description: Erro no servidor
 */

const express = require("express");
const router = express.Router();
const { protect } = require("../middleware/authMiddleware");
const clanChatController = require("../controllers/clanChatController");

// Enviar mensagem
router.post("/:clanId/message", protect, clanChatController.sendMessage);

// Buscar mensagens
router.get("/:clanId/messages", protect, clanChatController.getMessages);

module.exports = router;



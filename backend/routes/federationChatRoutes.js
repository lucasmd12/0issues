
/**
 * @swagger
 * tags:
 *   name: Chat da Federação
 *   description: Gerenciamento de mensagens de chat dentro de federações
 */

/**
 * @swagger
 * /api/federation-chat/{federationId}/message:
 *   post:
 *     summary: Enviar uma mensagem para o chat da federação
 *     tags: [Chat da Federação]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: federationId
 *         schema:
 *           type: string
 *         required: true
 *         description: ID da federação
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
 *                 federation:
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
 *         description: Federação não encontrada
 *       500:
 *         description: Erro no servidor
 */

/**
 * @swagger
 * /api/federation-chat/{federationId}/messages:
 *   get:
 *     summary: Obter mensagens do chat de uma federação
 *     tags: [Chat da Federação]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: federationId
 *         schema:
 *           type: string
 *         required: true
 *         description: ID da federação
 *     responses:
 *       200:
 *         description: Lista de mensagens do chat da federação
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   _id:
 *                     type: string
 *                   federation:
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
 *         description: Federação não encontrada
 *       500:
 *         description: Erro no servidor
 */

const express = require("express");
const router = express.Router();
const { protect } = require("../middleware/authMiddleware");
const federationChatController = require("../controllers/federationChatController");

// Enviar mensagem
router.post("/:federationId/message", protect, federationChatController.sendMessage);

// Buscar mensagens
router.get("/:federationId/messages", protect, federationChatController.getMessages);

module.exports = router;




/**
 * @swagger
 * tags:
 *   name: Missões do Clã
 *   description: Gerenciamento de missões QRR para clãs
 */

/**
 * @swagger
 * /api/clan-missions:
 *   post:
 *     summary: Criar uma nova missão QRR
 *     tags: [Missões do Clã]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - description
 *               - clanId
 *               - scheduledTime
 *             properties:
 *               name:
 *                 type: string
 *                 description: Nome da missão
 *               description:
 *                 type: string
 *                 description: Descrição detalhada da missão
 *               clanId:
 *                 type: string
 *                 description: ID do clã ao qual a missão pertence
 *               scheduledTime:
 *                 type: string
 *                 format: date-time
 *                 description: Data e hora programada para a missão
 *     responses:
 *       201:
 *         description: Missão criada com sucesso
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 _id:
 *                   type: string
 *                 name:
 *                   type: string
 *                 description:
 *                   type: string
 *                 clan:
 *                   type: string
 *                 scheduledTime:
 *                   type: string
 *                   format: date-time
 *       400:
 *         description: Dados inválidos
 *       500:
 *         description: Erro no servidor
 */

/**
 * @swagger
 * /api/clan-missions/clan/{clanId}:
 *   get:
 *     summary: Listar missões de um clã
 *     tags: [Missões do Clã]
 *     parameters:
 *       - in: path
 *         name: clanId
 *         schema:
 *           type: string
 *         required: true
 *         description: ID do clã
 *     responses:
 *       200:
 *         description: Lista de missões do clã
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
 *                   description:
 *                     type: string
 *                   clan:
 *                     type: string
 *                   scheduledTime:
 *                     type: string
 *                     format: date-time
 *       404:
 *         description: Clã não encontrado
 *       500:
 *         description: Erro no servidor
 */

/**
 * @swagger
 * /api/clan-missions/{id}:
 *   get:
 *     summary: Buscar missão por ID
 *     tags: [Missões do Clã]
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID da missão
 *     responses:
 *       200:
 *         description: Detalhes da missão
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 _id:
 *                   type: string
 *                 name:
 *                   type: string
 *                 description:
 *                   type: string
 *                 clan:
 *                   type: string
 *                 scheduledTime:
 *                   type: string
 *                   format: date-time
 *       404:
 *         description: Missão não encontrada
 *       500:
 *         description: Erro no servidor
 */

/**
 * @swagger
 * /api/clan-missions/{id}/confirm:
 *   post:
 *     summary: Confirmar presença em uma missão
 *     tags: [Missões do Clã]
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID da missão
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - userId
 *             properties:
 *               userId:
 *                 type: string
 *                 description: ID do usuário que está confirmando presença
 *     responses:
 *       200:
 *         description: Presença confirmada com sucesso
 *       400:
 *         description: Usuário já confirmou presença ou dados inválidos
 *       404:
 *         description: Missão não encontrada
 *       500:
 *         description: Erro no servidor
 */

/**
 * @swagger
 * /api/clan-missions/{id}/strategy:
 *   post:
 *     summary: Adicionar estratégia (upload de imagem) para uma missão
 *     tags: [Missões do Clã]
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID da missão
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               strategyImage:
 *                 type: string
 *                 format: binary
 *                 description: Imagem da estratégia
 *     responses:
 *       200:
 *         description: Estratégia adicionada com sucesso
 *       400:
 *         description: Nenhum arquivo enviado ou tipo de arquivo inválido
 *       404:
 *         description: Missão não encontrada
 *       500:
 *         description: Erro no servidor
 */

/**
 * @swagger
 * /api/clan-missions/{id}/cancel:
 *   post:
 *     summary: Cancelar uma missão
 *     tags: [Missões do Clã]
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID da missão
 *     responses:
 *       200:
 *         description: Missão cancelada com sucesso
 *       404:
 *         description: Missão não encontrada
 *       500:
 *         description: Erro no servidor
 */

// routes/clanMission.routes.js

const express = require("express");
const router = express.Router();
const ClanMissionController = require("../controllers/ClanMissionController");

// Criar missão QRR
router.post("/", ClanMissionController.createMission);

// Listar missões de um clã
router.get("/clan/:clanId", ClanMissionController.listMissions);

// Buscar missão por ID
router.get("/:id", ClanMissionController.getMission);

// Confirmar presença
router.post("/:id/confirm", ClanMissionController.confirmPresence);

// Adicionar estratégia (upload de imagem)
router.post("/:id/strategy", ClanMissionController.addStrategyMedia);

// Cancelar missão
router.post("/:id/cancel", ClanMissionController.cancelMission);

module.exports = router;



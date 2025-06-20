
/**
 * @swagger
 * tags:
 *   name: Autenticação
 *   description: Gerenciamento de usuários e autenticação
 */

/**
 * @swagger
 * /api/auth/register:
 *   post:
 *     summary: Registrar um novo usuário
 *     tags: [Autenticação]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - username
 *               - password
 *             properties:
 *               username:
 *                 type: string
 *                 description: Nome de usuário único
 *               password:
 *                 type: string
 *                 description: Senha com 6 ou mais caracteres
 *     responses:
 *       200:
 *         description: Usuário registrado com sucesso e token retornado
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 token:
 *                   type: string
 *                   description: Token de autenticação JWT
 *       400:
 *         description: Erro de validação ou usuário já existe
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 errors:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       msg:
 *                         type: string
 *                         description: Mensagem de erro
 *       500:
 *         description: Erro no servidor
 */

/**
 * @swagger
 * /api/auth/login:
 *   post:
 *     summary: Autenticar usuário e obter token
 *     tags: [Autenticação]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - username
 *               - password
 *             properties:
 *               username:
 *                 type: string
 *                 description: Nome de usuário
 *               password:
 *                 type: string
 *                 description: Senha do usuário
 *     responses:
 *       200:
 *         description: Autenticação bem-sucedida e token retornado
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 token:
 *                   type: string
 *                   description: Token de autenticação JWT
 *       400:
 *         description: Credenciais inválidas
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 errors:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       msg:
 *                         type: string
 *                         description: Mensagem de erro
 *       500:
 *         description: Erro no servidor
 */

/**
 * @swagger
 * /api/auth/profile:
 *   get:
 *     summary: Obter perfil do usuário autenticado
 *     tags: [Autenticação]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Perfil do usuário retornado com sucesso
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 _id:
 *                   type: string
 *                   description: ID do usuário
 *                 username:
 *                   type: string
 *                   description: Nome de usuário
 *                 email:
 *                   type: string
 *                   description: Email do usuário
 *                 avatar:
 *                   type: string
 *                   description: URL do avatar do usuário
 *                 clan:
 *                   type: string
 *                   description: ID do clã do usuário (se houver)
 *                 clanRole:
 *                   type: string
 *                   description: Papel do usuário no clã (se houver)
 *                 federationRole:
 *                   type: string
 *                   description: Papel do usuário na federação (se houver)
 *       401:
 *         description: Não autorizado, token ausente ou inválido
 *       500:
 *         description: Erro no servidor
 */

console.log("--- Loading authRoutes.js ---"); // Debug log
const express = require("express");
const router = express.Router();
const { registerUser, loginUser, getUserProfile } = require("../controllers/authController");
const { protect } = require("../middleware/authMiddleware");
const { check } = require("express-validator");

// @route   POST api/auth/register
// @desc    Register user (username/password only)
// @access  Public
router.post(
  "/register",
  [
    check("username", "Username is required").not().isEmpty(),
    // Removed email check
    check(
      "password",
      "Please enter a password with 6 or more characters"
    ).isLength({ min: 6 }),
  ],
  (req, res, next) => { // Add log inside route handler
    console.log("--- Route Hit: POST /api/auth/register ---");
    registerUser(req, res, next);
  }
);

// @route   POST api/auth/login
// @desc    Authenticate user & get token (username/password only)
// @access  Public
router.post(
  "/login",
  [
    check("username", "Username is required").not().isEmpty(), // Changed from email to username
    check("password", "Password is required").exists(),
  ],
   (req, res, next) => { // Add log inside route handler
    console.log("--- Route Hit: POST /api/auth/login ---");
    loginUser(req, res, next);
  }
);

// @route   GET api/auth/profile
// @desc    Get user profile
// @access  Private
router.get("/profile", protect, (req, res, next) => { // Add log inside route handler
    console.log("--- Route Hit: GET /api/auth/profile ---");
    getUserProfile(req, res, next);
});

module.exports = router;



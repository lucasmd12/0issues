# Lucas Beats Federação - Projeto Flutter

Este é o projeto Flutter do aplicativo FEDERACAOMAD, integrado com a API backend para funcionalidades de autenticação, perfil e gerenciamento de federações.

## Configuração da API

O projeto está configurado para se conectar com a API backend em:
- **URL Base**: `https://beckend-ydd1.onrender.com`

### Endpoints Principais Implementados:
- `POST /api/auth/register` - Registro de usuário
- `POST /api/auth/login` - Login de usuário
- `GET /api/auth/profile` - Obter perfil do usuário autenticado
- `GET /api/federations` - Listar todas as federações
- `POST /api/federations` - Criar nova federação
- `DELETE /api/federations/{id}` - Deletar federação

## Funcionalidades Implementadas

### Autenticação
- Tela de login com validação
- Tela de registro de usuário
- Gerenciamento de token JWT
- Logout automático quando token expira

### Perfil do Usuário
- Tela de perfil que busca dados da API
- Exibição de informações do usuário autenticado
- Atualização de perfil

### Gerenciamento de Federações
- Listagem de federações da API
- Criação de novas federações
- Exclusão de federações (apenas para usuários autorizados)
- Visualização de detalhes das federações

## Estrutura do Projeto

```
lib/
├── models/
│   ├── user_model.dart          # Modelo do usuário
│   └── federation_model.dart    # Modelo da federação
├── services/
│   ├── api_service.dart         # Serviço base para chamadas HTTP
│   ├── auth_service.dart        # Serviço de autenticação
│   └── federation_service.dart  # Serviço de federações
├── screens/
│   ├── login_screen.dart        # Tela de login
│   ├── register_screen.dart     # Tela de registro
│   └── profile_screen.dart      # Tela de perfil
├── widgets/
│   ├── federation_management.dart # Widget de gerenciamento de federações
│   └── custom_snackbar.dart     # Widget para notificações
└── utils/
    ├── constants.dart           # Constantes da aplicação
    └── logger.dart             # Sistema de logs
```

## Build no Codemagic

### Pré-requisitos
1. Conta no Codemagic
2. Repositório Git com o código
3. Configuração de assinatura Android (se necessário)

### Configuração
O projeto inclui um arquivo `codemagic.yaml` configurado para:
- Build automático para Android
- Testes unitários
- Análise de código Flutter
- Geração de APK de release

### Passos para Build
1. Faça upload do projeto para um repositório Git
2. Conecte o repositório ao Codemagic
3. O build será executado automaticamente usando a configuração em `codemagic.yaml`

## Dependências Principais

- `http: ^1.2.1` - Para chamadas HTTP à API
- `provider: ^6.1.2` - Gerenciamento de estado
- `shared_preferences: ^2.5.3` - Armazenamento local
- `flutter_secure_storage: ^9.2.2` - Armazenamento seguro de tokens

## Configurações de Segurança

- Tokens JWT são armazenados de forma segura usando `flutter_secure_storage`
- Todas as chamadas à API incluem headers de autenticação quando necessário
- Validação de token expirado com logout automático

## Testando a Integração

### Login de Teste
Use as credenciais que você criou na API:
- **Usuário**: `idcloned`
- **Senha**: `30092010`

### Funcionalidades para Testar
1. **Registro**: Crie um novo usuário
2. **Login**: Faça login com usuário existente
3. **Perfil**: Visualize o perfil do usuário logado
4. **Federações**: Liste, crie e gerencie federações

## Notas Importantes

- O projeto está configurado para usar a API em produção (`https://beckend-ydd1.onrender.com`)
- Certifique-se de que a API esteja online antes de testar
- O token JWT tem validade limitada - faça login novamente se necessário
- Todas as operações de federação requerem autenticação

## Troubleshooting

### Problemas Comuns
1. **Erro 401 (Unauthorized)**: Token expirado ou inválido - faça login novamente
2. **Erro de Conexão**: Verifique se a API está online
3. **Erro de CORS**: Já resolvido na configuração da API

### Logs
O projeto inclui sistema de logs detalhado. Verifique o console para informações de debug.


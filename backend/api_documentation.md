# Documentação da API Backend VoIP (Node.js)

Este documento descreve os endpoints REST e os eventos Socket.IO disponíveis no backend Node.js para o aplicativo VoIP.

**URL Base:** A URL base dependerá de onde o backend está hospedado (ex: `https://seu-servico.onrender.com`). Todas as rotas REST são prefixadas com `/api`.

**Autenticação:**

*   **REST API:** A maioria das rotas REST é protegida e requer um JSON Web Token (JWT) válido. O token deve ser enviado no cabeçalho `Authorization` como um Bearer token:
    ```
    Authorization: Bearer <seu_token_jwt>
    ```
*   **Socket.IO:** A conexão Socket.IO requer autenticação. O token JWT deve ser enviado no objeto `auth` durante a inicialização da conexão no cliente:
    ```javascript
    // Exemplo no cliente (Dart com socket_io_client)
    IO.io('URL_DO_SEU_BACKEND', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {
        'token': seuTokenJWT // Envie o token aqui
      }
    });
    ```

## Endpoints REST API

### Autenticação (`/api/auth`)

1.  **Registrar Usuário**
    *   **Método:** `POST`
    *   **Path:** `/api/auth/register`
    *   **Acesso:** Público
    *   **Corpo da Requisição (JSON):**
        ```json
        {
          "username": "nome_usuario",
          "email": "usuario@email.com",
          "password": "senha_min_6_chars"
        }
        ```
    *   **Resposta Sucesso (201 Created):**
        ```json
        {
          "_id": "id_do_usuario",
          "username": "nome_usuario",
          "email": "usuario@email.com",
          "token": "seu_token_jwt"
        }
        ```
    *   **Respostas Erro:** `400 Bad Request` (Dados inválidos, usuário já existe), `500 Internal Server Error`.

2.  **Login de Usuário**
    *   **Método:** `POST`
    *   **Path:** `/api/auth/login`
    *   **Acesso:** Público
    *   **Corpo da Requisição (JSON):**
        ```json
        {
          "email": "usuario@email.com",
          "password": "senha"
        }
        ```
    *   **Resposta Sucesso (200 OK):**
        ```json
        {
          "_id": "id_do_usuario",
          "username": "nome_usuario",
          "email": "usuario@email.com",
          "token": "seu_token_jwt"
        }
        ```
    *   **Respostas Erro:** `400 Bad Request` (Credenciais inválidas), `500 Internal Server Error`.

3.  **Obter Perfil do Usuário**
    *   **Método:** `GET`
    *   **Path:** `/api/auth/profile`
    *   **Acesso:** Privado (Requer JWT)
    *   **Resposta Sucesso (200 OK):** Retorna o objeto do usuário logado (sem a senha).
        ```json
        {
          "_id": "id_do_usuario",
          "username": "nome_usuario",
          "email": "usuario@email.com",
          "createdAt": "timestamp"
          // ... outros campos do usuário
        }
        ```
    *   **Respostas Erro:** `401 Unauthorized` (Token inválido ou ausente), `404 Not Found` (Usuário não encontrado), `500 Internal Server Error`.

### Canais (`/api/channels`)

*Nota: Todas as rotas de canais são privadas e requerem um JWT válido.*

1.  **Criar Novo Canal**
    *   **Método:** `POST`
    *   **Path:** `/api/channels`
    *   **Acesso:** Privado
    *   **Corpo da Requisição (JSON):**
        ```json
        {
          "name": "nome_do_canal",
          "description": "descrição opcional"
        }
        ```
    *   **Resposta Sucesso (201 Created):** Retorna o objeto do canal criado.
        ```json
        {
          "_id": "id_do_canal",
          "name": "nome_do_canal",
          "description": "descrição opcional",
          "owner": "id_do_dono",
          "members": ["id_do_dono"],
          "createdAt": "timestamp"
        }
        ```
    *   **Respostas Erro:** `400 Bad Request` (Nome já existe, dados inválidos), `401 Unauthorized`, `500 Internal Server Error`.

2.  **Listar Todos os Canais**
    *   **Método:** `GET`
    *   **Path:** `/api/channels`
    *   **Acesso:** Privado
    *   **Resposta Sucesso (200 OK):** Retorna um array de objetos de canal (com owner populado).
        ```json
        [
          {
            "_id": "id_do_canal_1",
            "name": "Canal 1",
            "owner": { "_id": "id_dono_1", "username": "dono1" },
            // ... outros campos
          },
          // ... mais canais
        ]
        ```
    *   **Respostas Erro:** `401 Unauthorized`, `500 Internal Server Error`.

3.  **Obter Detalhes de um Canal**
    *   **Método:** `GET`
    *   **Path:** `/api/channels/:id` (onde `:id` é o ID do canal)
    *   **Acesso:** Privado
    *   **Resposta Sucesso (200 OK):** Retorna o objeto do canal com owner e members populados.
        ```json
        {
          "_id": "id_do_canal",
          "name": "nome_do_canal",
          "description": "descrição",
          "owner": { "_id": "id_dono", "username": "dono", "email": "dono@email.com" },
          "members": [
            { "_id": "id_membro1", "username": "membro1" },
            { "_id": "id_membro2", "username": "membro2" }
          ],
          "createdAt": "timestamp"
        }
        ```
    *   **Respostas Erro:** `401 Unauthorized`, `404 Not Found` (Canal não encontrado), `500 Internal Server Error`.

4.  **Entrar em um Canal**
    *   **Método:** `POST`
    *   **Path:** `/api/channels/:id/join`
    *   **Acesso:** Privado
    *   **Resposta Sucesso (200 OK):**
        ```json
        {
          "msg": "Successfully joined channel",
          "members": ["id_membro1", "id_membro2", "id_novo_membro"]
        }
        ```
    *   **Respostas Erro:** `400 Bad Request` (Usuário já está no canal), `401 Unauthorized`, `404 Not Found`, `500 Internal Server Error`.

5.  **Sair de um Canal**
    *   **Método:** `POST`
    *   **Path:** `/api/channels/:id/leave`
    *   **Acesso:** Privado
    *   **Resposta Sucesso (200 OK):**
        ```json
        {
          "msg": "Successfully left channel",
          "members": ["id_membro1", "id_membro2"]
        }
        ```
    *   **Respostas Erro:** `400 Bad Request` (Usuário não está no canal), `401 Unauthorized`, `404 Not Found`, `500 Internal Server Error`.

6.  **Obter Mensagens de um Canal**
    *   **Método:** `GET`
    *   **Path:** `/api/channels/:id/messages`
    *   **Acesso:** Privado (Apenas membros do canal)
    *   **Resposta Sucesso (200 OK):** Retorna um array de objetos de mensagem, ordenados do mais antigo para o mais recente.
        ```json
        [
          {
            "_id": "id_msg1",
            "channel": "id_do_canal",
            "sender": { "_id": "id_remetente1", "username": "remetente1" },
            "content": "Olá!",
            "timestamp": "timestamp1"
          },
          {
            "_id": "id_msg2",
            "channel": "id_do_canal",
            "sender": { "_id": "id_remetente2", "username": "remetente2" },
            "content": "Tudo bem?",
            "timestamp": "timestamp2"
          }
          // ... mais mensagens
        ]
        ```
    *   **Respostas Erro:** `401 Unauthorized`, `403 Forbidden` (Usuário não é membro), `404 Not Found`, `500 Internal Server Error`.

## Eventos Socket.IO

*Nota: A conexão requer autenticação via JWT (ver início da documentação).*

### Eventos Cliente -> Servidor

1.  **`join_channel`**
    *   **Propósito:** Entrar em uma sala de chat/canal e receber o histórico de mensagens.
    *   **Payload:** `{ channelId: string }`
    *   **Callback:** `(response) => { ... }`
        *   **Sucesso:** `response = { status: 'ok', messages: Array<MessageObject> }` (mensagens ordenadas da mais antiga para a mais recente)
        *   **Erro:** `response = { status: 'error', message: string }`

2.  **`send_message`**
    *   **Propósito:** Enviar uma mensagem para um canal.
    *   **Payload:** `{ channelId: string, content: string }`
    *   **Callback:** `(response) => { ... }`
        *   **Sucesso:** `response = { status: 'ok', message: MessageObject }` (mensagem enviada e salva)
        *   **Erro:** `response = { status: 'error', message: string }`

3.  **`signal`** (WebRTC)
    *   **Propósito:** Enviar dados de sinalização WebRTC (offer, answer, candidate) para outros usuários no canal.
    *   **Payload:** `{ channelId: string, signalData: any }`
    *   **Callback:** Nenhum.

4.  **`leave_channel`**
    *   **Propósito:** Sair de uma sala de chat/canal.
    *   **Payload:** `{ channelId: string }`
    *   **Callback:** Nenhum.

### Eventos Servidor -> Cliente

1.  **`receive_message`**
    *   **Propósito:** Notificar o cliente sobre uma nova mensagem recebida no canal.
    *   **Payload:** `MessageObject` (objeto da mensagem com sender populado)
        ```json
        {
          "_id": "id_nova_msg",
          "channel": "id_do_canal",
          "sender": { "_id": "id_remetente", "username": "remetente" },
          "content": "Nova mensagem!",
          "timestamp": "timestamp"
        }
        ```

2.  **`signal`** (WebRTC)
    *   **Propósito:** Entregar dados de sinalização WebRTC de outro usuário no canal.
    *   **Payload:** `{ userId: string, signalData: any }` (onde `userId` é o ID do usuário que enviou o sinal)

3.  **`connect_error`**
    *   **Propósito:** Notificar o cliente sobre um erro durante a tentativa de conexão (ex: token inválido).
    *   **Payload:** Objeto de erro.

4.  **`disconnect`**
    *   **Propósito:** Evento padrão do Socket.IO disparado quando a conexão é perdida.
    *   **Payload:** `reason` (string descrevendo o motivo).

*(Opcional: Eventos como `user_joined` e `user_left` podem ser adicionados se necessário para notificar sobre entrada/saída de usuários nas salas.)*

## Considerações Adicionais

*   **CORS:** A configuração atual do CORS no `server.js` (`origin: "*"`) é permissiva. Em produção, restrinja para a URL do seu frontend Flutter (se aplicável a web builds) ou domínios confiáveis.
*   **Variáveis de Ambiente:** Certifique-se de configurar `MONGO_URI`, `JWT_SECRET` e `PORT` como variáveis de ambiente na sua plataforma de hospedagem (Render).
*   **Logging:** Logs são gerados em `combined.log` e `error.log` no diretório do backend.


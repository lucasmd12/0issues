# Plano de Correção Detalhado - V2 (Protocolo REVISTA GERAL)

Baseado na análise detalhada (`analysis_summary_v2.md`) dos 487 issues encontrados, este plano prioriza a correção dos erros críticos para estabilizar o projeto.

**Bloco 1: Correção de Erros Críticos - Imports e Sintaxe**

1.  **Arquivo: `lib/services/clan_service.dart`**
    *   **Erro:** `Undefined class 'User'` (linhas 48, 77, 97, 138, 166)
    *   **Ação:** Adicionar `import 'package:lucasbeatsfederacao/models/user_model.dart';` no início do arquivo.

2.  **Arquivo: `lib/services/federation_service.dart`**
    *   **Erro:** `Undefined class 'User'` (linhas 37, 68, 89)
    *   **Ação:** Adicionar `import 'package:lucasbeatsfederacao/models/user_model.dart';` no início do arquivo.

3.  **Arquivo: `lib/services/chat_service.dart`**
    *   **Erro:** `Undefined name 'Logger'` (linhas 18, 38, 51)
    *   **Ação:** Adicionar `import 'package:lucasbeatsfederacao/utils/logger.dart';` no início do arquivo.
    *   **Erro:** `The name 'MessageModel' isn't a type...` (linha 37)
    *   **Ação:** Adicionar `import 'package:lucasbeatsfederacao/models/message_model.dart';` no início do arquivo.

4.  **Arquivo: `lib/services/signaling_service.dart`**
    *   **Erro:** `Expected to find ';'` (linha 4)
    *   **Ação:** Corrigir a linha 4, garantindo que o import de `logger.dart` termine com `;` e a declaração da classe `SignalingService` comece em uma nova linha.

**Bloco 2: Correção de Erros Críticos - Implementação de Modelos e Providers**

1.  **Arquivo: `lib/models/mission_model.dart` (Necessário Criar ou Modificar)**
    *   **Erro:** Métodos `toJson` e `fromJson` não definidos (chamados em `mission_service.dart`).
    *   **Ação:** Verificar se o arquivo `lib/models/mission_model.dart` existe. Se sim, implementar os métodos `Map<String, dynamic> toJson()` e `factory MissionModel.fromJson(Map<String, dynamic> json)` na classe `MissionModel`. Se não existir, criar o arquivo e a classe com a estrutura básica e os métodos necessários.

2.  **Arquivo: `lib/providers/call_provider.dart`**
    *   **Erro:** Múltiplos métodos não definidos (e.g., `_handleIncomingSignal`, `atualizarStatusPresenca`, `_initializeWebRTC`, etc.).
    *   **Ação:** Implementar os métodos listados em `analysis_summary_v2.md` dentro da classe `CallProvider`. Como a lógica WebRTC é complexa, iniciar com implementações placeholder (e.g., apenas logando a chamada do método) para resolver os erros de compilação. A lógica completa pode ser adicionada posteriormente.
        *   **Nota:** Verificar se o método `atualizarStatusPresenca` já existe em `ChatService` e se a chamada em `CallProvider` está correta ou se deveria chamar o método do `ChatService` injetado.

3.  **Arquivo: `lib/src/features/chat/presentation/screens/chat_screen.dart`**
    *   **Erro:** Métodos `addListener` / `removeListener` não definidos para `ChatService` (linhas 48, 75).
    *   **Ação:** Revisar a lógica em `initState` e `dispose`. Garantir que `Provider.of<ChatService>(context, listen: false)` seja chamado *após* o primeiro frame (usando `WidgetsBinding.instance.addPostFrameCallback`) e que `ChatService` esteja corretamente registrado como `ChangeNotifierProvider` na árvore de widgets (provavelmente em `main.dart` ou um ponto superior).

**Bloco 3: Correção de Avisos (Warnings)**

1.  **Remover Imports Não Utilizados (`unused_import`):**
    *   **Arquivos:** `mission_service.dart`, `profile_screen.dart`, `socket_service.dart`, `app_lifecycle_reactor.dart`.
    *   **Ação:** Remover as linhas de `import` marcadas.

2.  **Remover Campos Não Utilizados (`unused_field`):**
    *   **Arquivo:** `lib/services/socket_service.dart`
    *   **Ação:** Remover a declaração do campo `_authService`.

3.  **Corrigir Comparações/Verificações Nulas Desnecessárias (`unnecessary_null_comparison`):**
    *   **Arquivos:** `notification_service.dart`, `profile_screen.dart`.
    *   **Ação:** Simplificar as condições lógicas.

4.  **Corrigir Verificação de Tipo Desnecessária (`unnecessary_type_check`):**
    *   **Arquivo:** `lib/src/features/chat/presentation/screens/chat_screen.dart`.
    *   **Ação:** Remover a verificação `is DateTime` se a variável já for desse tipo.

**Bloco 4: Aplicação de Boas Práticas (Infos)**

1.  **Usar Super Parâmetros (`use_super_parameters`):**
    *   **Arquivo:** `lib/src/shared/widgets/button_custom.dart`.
    *   **Ação:** Refatorar o construtor.

2.  **Corrigir Uso de Membros Depreciados (`deprecated_member_use`):**
    *   **Arquivo:** `lib/utils/theme_constants.dart`.
    *   **Ação:** Substituir `background` por `surface`.

3.  **Corrigir Nomes Fora do Padrão (`library_prefixes`):**
    *   **Arquivo:** `lib/services/socket_service.dart`.
    *   **Ação:** Renomear o prefixo `IO` para `io`.

**Próximo Passo (Plano 005):** Executar as correções seguindo a ordem e o detalhamento deste plano (V2). Após a execução, rodar `flutter analyze` novamente para validação.

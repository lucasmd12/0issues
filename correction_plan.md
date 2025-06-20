# Plano de Correção - Protocolo REVISTA GERAL

Este plano detalha as correções a serem realizadas com base na análise estática (`flutter analyze`) que identificou 530 pontos de atenção. As correções serão feitas em blocos, priorizando erros críticos.

**Bloco 1: Correção de Erros Críticos**

1.  **Arquivo: `lib/services/notification_service.dart`**
    *   **Erro:** `missing_const_final_var_or_type` (linha 5)
        *   **Ação:** Adicionar `final` ou tipo explícito às variáveis `flutterLocalNotificationsPlugin` e `TargetPlatform`.
    *   **Erro:** `non_constant_identifier_names` (linha 5)
        *   **Ação:** Renomear a variável `TargetPlatform` para `targetPlatform` (seguindo lowerCamelCase).
    *   **Erro:** `directive_after_declaration` (linhas 7, 11, 14, 17)
        *   **Ação:** Mover todas as diretivas `import` para o topo do arquivo, antes de qualquer declaração de classe ou variável.
    *   **Erro:** `not_a_type` (linha 120)
        *   **Ação:** Investigar o uso de `TargetPlatform` como tipo. Provavelmente deveria ser uma verificação de plataforma (e.g., `Platform.isAndroid`, `Platform.isIOS` ou `Theme.of(context).platform`). Corrigir a lógica conforme necessário.

2.  **Arquivo: `lib/src/features/chat/presentation/screens/chat_screen.dart`**
    *   **Erro:** `undefined_method` (`addListener` na linha 48, `removeListener` na linha 75)
        *   **Ação:** Investigar a classe `ChatService`. Verificar se ela deveria implementar `ChangeNotifier` (e, portanto, ter `addListener`/`removeListener`) ou se a lógica em `chat_screen.dart` está incorreta e deveria usar outra forma de observar mudanças no `ChatService` (e.g., `StreamBuilder`, `Consumer` de Provider se `ChatService` for um `ChangeNotifierProvider`). Implementar ou corrigir a lógica.

**Bloco 2: Correção de Avisos Importantes (Warnings)**

1.  **Remover Imports Não Utilizados (`unused_import`):**
    *   **Arquivos:** `permission_service.dart`, `questionnaire_service.dart`, `role_service.dart`, `signaling_service.dart`, `socket_service.dart`, `profile_screen.dart`, `app_lifecycle_reactor.dart`.
    *   **Ação:** Remover as linhas de `import` marcadas como não utilizadas em cada um desses arquivos.

2.  **Remover Campos Não Utilizados (`unused_field`):**
    *   **Arquivo:** `lib/services/socket_service.dart`
    *   **Ação:** Remover a declaração do campo `_authService` (linha 14) após confirmar que ele não é usado em nenhum lugar da classe.

3.  **Corrigir Comparações/Verificações Nulas Desnecessárias (`unnecessary_null_comparison`, `dead_null_aware_expression`, `unnecessary_type_check`):**
    *   **Arquivos:** `notification_service.dart` (linhas 82, 86), `profile_screen.dart` (linhas 152, 181), `chat_screen.dart` (linha 254).
    *   **Ação:** Revisar e simplificar as condições lógicas onde essas verificações desnecessárias ocorrem.

4.  **Corrigir Uso de Membros Depreciados (`deprecated_member_use`):**
    *   **Arquivo:** `lib/utils/theme_constants.dart`
    *   **Ação:** Substituir `Theme.of(context).colorScheme.background` por `Theme.of(context).colorScheme.surface` (linha 22).

**Bloco 3: Aplicação de Boas Práticas (Infos)**

1.  **Adicionar Tipagem Explícita (`prefer_typing_uninitialized_variables`, `strict_top_level_inference`):**
    *   **Ação:** Adicionar tipos explícitos a variáveis não inicializadas e declarações de nível superior onde a inferência não é estrita (conforme apontado pela análise, e.g., em `notification_service.dart`).

2.  **Corrigir Nomes Fora do Padrão (`non_constant_identifier_names`, `library_prefixes`):**
    *   **Ação:** Renomear identificadores para seguir as convenções do Dart (lowerCamelCase para variáveis/métodos, lower_case_with_underscores para prefixos de biblioteca), conforme apontado pela análise (e.g., `notification_service.dart`, `socket_service.dart`).

3.  **Usar Super Parâmetros (`use_super_parameters`):**
    *   **Ação:** Refatorar construtores para usar super parâmetros onde aplicável, conforme sugerido pela análise (e.g., `button_custom.dart`).

**Próximo Passo (Plano 005):** Executar as correções seguindo a ordem e o detalhamento deste plano.

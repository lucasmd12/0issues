# Resumo da Análise Estática (flutter analyze)

Foram encontrados 530 pontos de atenção no código. Abaixo estão as categorias principais de erros e avisos identificados, que serão abordados na próxima etapa de correção:

**Erros Críticos:**

*   **Métodos Não Definidos:**
    *   `addListener` e `removeListener` em `ChatService` (usados em `chat_screen.dart`). É necessário implementar esses métodos ou ajustar a lógica que os chama.
*   **Tipos Incorretos/Não Encontrados:**
    *   Uso de `TargetPlatform` como tipo em `notification_service.dart`.
*   **Declarações Inválidas:**
    *   Variáveis declaradas sem `const`, `final`, `var` ou tipo (`missing_const_final_var_or_type` em `notification_service.dart`).
    *   Diretivas (`import`, `export`, `part`) aparecendo após declarações de código (`directive_after_declaration` em `notification_service.dart`).

**Avisos Importantes (Warnings):**

*   **Imports Não Utilizados (`unused_import`):** Presente em diversos arquivos (e.g., `permission_service.dart`, `questionnaire_service.dart`, `role_service.dart`, `signaling_service.dart`, `socket_service.dart`, `profile_screen.dart`, `app_lifecycle_reactor.dart`). Devem ser removidos para limpar o código.
*   **Campos Não Utilizados (`unused_field`):**
    *   `_authService` em `socket_service.dart`.
*   **Comparações/Verificações Nulas Desnecessárias (`unnecessary_null_comparison`, `dead_null_aware_expression`, `unnecessary_type_check`):** Presente em `notification_service.dart`, `profile_screen.dart`, `chat_screen.dart`. Indicam lógica que pode ser simplificada ou corrigida.
*   **Uso de Membros Depreciados (`deprecated_member_use`):**
    *   Uso de `background` em `ThemeData` (`theme_constants.dart`). Deve ser substituído por `surface`.

**Informações (Infos) / Boas Práticas:**

*   **Tipagem Explícita Faltante (`prefer_typing_uninitialized_variables`, `strict_top_level_inference`):** Sugestões para melhorar a clareza e segurança do código.
*   **Nomes Fora do Padrão (`non_constant_identifier_names`, `library_prefixes`):** Sugestões para seguir as convenções de nomenclatura do Dart.
*   **Uso de Super Parâmetros (`use_super_parameters`):** Sugestão de modernização na declaração de construtores.

**Próximo Passo (Plano 004):** Planejar a correção em bloco, priorizando os erros críticos e depois abordando os avisos e sugestões de boas práticas de forma sistemática.

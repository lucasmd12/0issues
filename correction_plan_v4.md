# Plano de Correção Estrutural - V4 (Foco em Resolução de Imports)

Baseado na análise V4 (`analysis_summary_v4.md`), que aponta problemas sistêmicos na resolução de imports como causa raiz, este plano foca em restaurar a integridade da estrutura do projeto e a capacidade do analisador de encontrar as definições corretas.

**Bloco 1: Limpeza e Restauração do Ambiente**

1.  **Ação:** Executar `flutter clean` no diretório `/home/ubuntu/lucasbeats_v4/project_android` para remover builds antigos e caches.
2.  **Ação:** Executar `flutter pub get` no mesmo diretório para baixar novamente as dependências e reconstruir arquivos de configuração.
3.  **Ação:** Rodar `flutter analyze` para verificar se a limpeza teve algum impacto inicial.

**Bloco 2: Verificação e Correção do `pubspec.yaml` e Imports**

1.  **Ação:** Ler o arquivo `pubspec.yaml`.
2.  **Ação:** Verificar se o `name:` está correto (`lucasbeatsfederacao`).
3.  **Ação:** Verificar se as dependências essenciais (`flutter`, `provider`, `http`, etc.) estão presentes.
4.  **Ação:** Revisar **explicitamente** os imports nos arquivos com erros críticos de definição (`clan_service.dart`, `federation_service.dart`, `chat_service.dart`):
    *   Garantir que `import 'package:lucasbeatsfederacao/models/user_model.dart';` esteja presente e correto em `clan_service.dart` e `federation_service.dart`.
    *   Garantir que `import 'package:lucasbeatsfederacao/utils/logger.dart';` esteja presente e correto em `chat_service.dart`.
    *   Garantir que `import 'package:lucasbeatsfederacao/models/message_model.dart';` esteja presente e correto em `chat_service.dart`.
    *   Garantir que `import 'package:flutter/material.dart';` (ou `foundation.dart`) esteja presente e correto em `chat_service.dart`.
5.  **Ação:** Rodar `flutter analyze` novamente.

**Bloco 3: Correção Estrutural de `ChatService`**

1.  **Arquivo:** `lib/services/chat_service.dart`
    *   **Ação 1:** Confirmar/Corrigir a declaração da classe para `class ChatService extends ChangeNotifier { ... }`.
    *   **Ação 2:** Remover quaisquer definições duplicadas ou imports conflitantes identificados no Bloco 2.
    *   **Ação 3:** Garantir que `notifyListeners()` e as referências a `MessageModel` e `Logger` estejam corretas após a validação dos imports.
2.  **Arquivo:** `lib/src/features/chat/presentation/screens/chat_screen.dart`
    *   **Ação:** Confirmar que as chamadas a `addListener` e `removeListener` no `ChatService` são válidas (depende da correção do Bloco 3.1).
3.  **Ação:** Rodar `flutter analyze` pela última vez nesta fase.

**Próximo Passo (Plano 006):**
*   Executar as correções dos Blocos 1, 2 e 3 deste plano, **em sequência**, rodando a análise após cada bloco conforme indicado.
*   Se a análise final do Bloco 3 mostrar **apenas warnings e infos**, avançar para o passo 007 (Validação Funcional).
*   Se **erros críticos persistirem**, retornar ao passo 004 para uma nova análise de dependências, considerando problemas mais complexos.

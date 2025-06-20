# Plano de Correção Estrutural - V3

Baseado na análise V3 (`analysis_summary_v3.md`), este plano foca **exclusivamente** em resolver os erros críticos estruturais relacionados a imports e definições de classe.

**Bloco 1: Correção de Imports Essenciais**

1.  **Arquivo: `lib/services/clan_service.dart`**
    *   **Ação:** Garantir que `import 'package:lucasbeatsfederacao/models/user_model.dart';` esteja presente no topo do arquivo.

2.  **Arquivo: `lib/services/federation_service.dart`**
    *   **Ação:** Garantir que `import 'package:lucasbeatsfederacao/models/user_model.dart';` esteja presente no topo do arquivo.

3.  **Arquivo: `lib/services/chat_service.dart`**
    *   **Ação 1:** Garantir que `import 'package:lucasbeatsfederacao/utils/logger.dart';` esteja presente no topo do arquivo.
    *   **Ação 2:** Garantir que `import 'package:lucasbeatsfederacao/models/message_model.dart';` esteja presente no topo do arquivo.
    *   **Ação 3:** Garantir que `import 'package:flutter/foundation.dart';` (ou `import 'package:flutter/material.dart';`) esteja presente no topo do arquivo para habilitar `ChangeNotifier`.

**Bloco 2: Correção da Estrutura da Classe `ChatService`**

1.  **Arquivo: `lib/services/chat_service.dart`**
    *   **Ação 1:** Verificar e corrigir a declaração da classe para `class ChatService extends ChangeNotifier { ... }`.
    *   **Ação 2:** Remover quaisquer definições duplicadas da classe `MessageModel` dentro deste arquivo.
    *   **Ação 3:** Confirmar que os métodos que usam `MessageModel` (como `getMessagesForChannel`, `sendMessage`) estão corretos após a verificação do import.
    *   **Ação 4:** Confirmar que `notifyListeners()` está sendo chamado corretamente dentro dos métodos da classe.

**Bloco 3: Correção da Estrutura da Classe `ChatScreen` (Dependente do Bloco 2)**

1.  **Arquivo: `lib/src/features/chat/presentation/screens/chat_screen.dart`**
    *   **Ação:** Revisar as chamadas a `addListener` e `removeListener` em `initState` e `dispose`. Garantir que `Provider.of<ChatService>(context, listen: false)` seja usado corretamente e que `ChatService` esteja registrado como `ChangeNotifierProvider` na árvore de widgets.

**Próximo Passo (Plano 005):**
1.  Executar as correções **apenas** dos Blocos 1, 2 e 3 deste plano.
2.  Rodar `flutter analyze` imediatamente após essas correções.
3.  **NÃO** corrigir warnings ou infos nesta etapa. O objetivo é zerar os **erros críticos** primeiro.
4.  Se a análise mostrar apenas warnings e infos, avançar para o passo 006 (Validação). Se erros críticos persistirem, retornar ao passo 003 para nova análise detalhada.

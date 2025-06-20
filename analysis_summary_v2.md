# Resumo Detalhado da Análise Estática (flutter analyze) - V2

Foram encontrados **487** pontos de atenção na análise estática mais recente. Esta análise detalhada categoriza os problemas para guiar um plano de correção mais eficaz.

**1. Erros Críticos: Classes e Métodos Não Definidos**

*   **Classes Não Definidas:**
    *   `User`: Não encontrada em `lib/services/clan_service.dart` (linhas 48, 77, 97, 138, 166) e `lib/services/federation_service.dart` (linhas 37, 68, 89).
        *   **Causa Provável:** Falta do import `package:lucasbeatsfederacao/models/user_model.dart` nesses arquivos.
*   **Identificadores Não Definidos:**
    *   `Logger`: Não encontrado em `lib/services/chat_service.dart` (linhas 18, 38, 51).
        *   **Causa Provável:** Falta do import `package:lucasbeatsfederacao/utils/logger.dart`.
*   **Métodos Não Definidos em Classes Existentes:**
    *   `addListener` / `removeListener` em `ChatService` (chamados em `lib/src/features/chat/presentation/screens/chat_screen.dart` linhas 48, 75).
        *   **Causa Provável:** Embora `ChatService` estenda `ChangeNotifier`, a forma como `Provider.of<ChatService>(context)` está sendo usada em `initState` e `dispose` pode estar incorreta ou ocorrendo em um momento inadequado do ciclo de vida.
    *   `toJson` / `fromJson` em `MissionModel` (chamados em `lib/services/mission_service.dart` linhas 17, 20, 38, 58).
        *   **Causa Provável:** A classe `MissionModel` (provavelmente em `lib/models/mission_model.dart`) não implementa os métodos `toJson()` e `fromJson(Map<String, dynamic> json)` necessários para serialização/desserialização com a API.
    *   Múltiplos métodos em `CallProvider` (chamados em `lib/providers/call_provider.dart`):
        *   `_handleIncomingSignal` (linha 80)
        *   `atualizarStatusPresenca` (linha 103)
        *   `_initializeWebRTC` (linha 116)
        *   `_hangUp` (linha 130)
        *   `_createPeerConnection` (linha 170)
        *   `_registerPeerConnectionListeners` (linha 176)
        *   `_setRemoteDescription` (linha 223)
        *   `_addCandidate` (linha 235)
        *   `_createOffer` (linha 249)
        *   `_createAnswer` (linha 264)
        *   `_getMedia` (linha 294)
        *   `_closeMediaStream` (linha 312)
        *   `_closePeerConnection` (linha 320)
        *   `_notifyListeners` (linha 331)
        *   **Causa Provável:** Implementação incompleta da classe `CallProvider`. Esses métodos, provavelmente relacionados à lógica WebRTC, precisam ser implementados ou o código que os chama precisa ser ajustado/removido.
*   **Nomes Não São Tipos:**
    *   `MessageModel` usado como argumento de tipo em `lib/services/chat_service.dart` (linha 37).
        *   **Causa Provável:** Falta do import `package:lucasbeatsfederacao/models/message_model.dart`.

**2. Erros Críticos: Sintaxe**

*   **Ponto e Vírgula Esperado (`;`)**
    *   `lib/services/signaling_service.dart` (linha 4).
        *   **Causa Provável:** Erro introduzido na edição anterior ao remover um import, deixando a declaração da classe na mesma linha do import removido.

**3. Avisos Importantes (Warnings)**

*   **Imports Não Utilizados (`unused_import`):**
    *   `package:flutter/material.dart` em `lib/services/mission_service.dart`.
    *   `dart:io` em `lib/src/features/auth/presentation/screens/profile_screen.dart`.
    *   `package:lucasbeatsfederacao/utils/log.dart` em `lib/services/socket_service.dart`.
    *   `package:lucasbeatsfederacao/providers/call_provider.dart` em `lib/widgets/app_lifecycle_reactor.dart`.
*   **Campos Não Utilizados (`unused_field`):**
    *   `_authService` em `lib/services/socket_service.dart`.
*   **Comparações/Verificações Nulas Desnecessárias (`unnecessary_null_comparison`):**
    *   `lib/services/notification_service.dart` (linhas 70, 76).
    *   `lib/src/features/auth/presentation/screens/profile_screen.dart` (linhas 152, 181).
*   **Verificação de Tipo Desnecessária (`unnecessary_type_check`):**
    *   `lib/src/features/chat/presentation/screens/chat_screen.dart` (linha 254).

**4. Informações (Infos) / Boas Práticas**

*   **Uso de Super Parâmetros (`use_super_parameters`):**
    *   `lib/src/shared/widgets/button_custom.dart` (linha 11).
*   **Uso de Membros Depreciados (`deprecated_member_use`):**
    *   `background` em `ThemeData` (`lib/utils/theme_constants.dart` linha 22). Substituir por `surface`.
*   **Nomes Fora do Padrão (`library_prefixes`):**
    *   Prefixo `IO` em `lib/services/socket_service.dart` (linha 2). Renomear para `io`.

**Próximo Passo (Plano 004):** Com base nesta análise detalhada, criar um novo plano de correção (`correction_plan_v2.md`) priorizando os erros críticos (Classes/Métodos/Tipos não definidos, Erros de Sintaxe) e depois abordando os avisos e sugestões.

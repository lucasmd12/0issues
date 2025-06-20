# Lista de Correções e Aprimoramentos - LucasBeats

- [x] Criar estrutura básica da pasta `ios` para compatibilidade.
- [x] Corrigir `main.dart`: Injetar `AuthService` na criação de `ChatService`.
- [x] Definir/Importar enum `Role` e adicionar propriedade `clanId` no `models/user_model.dart`.
- [x] Corrigir `services/auth_service.dart`: Usar a definição correta de `Role`.
- [x] Corrigir `services/federation_service.dart`: Acessar `currentUser.id` em vez de `currentUser['id']`.
- [x] Corrigir `providers/connectivity_provider.dart`: Lidar com `List<ConnectivityResult>` em vez de `ConnectivityResult`.
- [x] Corrigir `services/chat_service.dart`: Adicionar método `atualizarStatusPresenca` e garantir que o construtor receba `AuthService`.
- [x] Corrigir `widgets/app_lifecycle_reactor.dart`: Injetar `AuthService` na criação de `ChatService` e chamar o método correto (`atualizarStatusPresenca`).
- [x] Corrigir `services/clan_service.dart`: Adicionar método `getClanChannels`.
- [x] Corrigir `screens/tabs/chat_list_tab.dart`: Usar `currentUser.clanId` e chamar `getClanChannels` corretamente.
- [x] Revisão geral: Verificar imports não utilizados, possíveis erros de nulo e outras melhorias.
- [x] Validar estrutura final do projeto.
- [ ] Compactar projeto corrigido em ZIP.
- [ ] Enviar ZIP ao usuário.

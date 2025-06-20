# Lista de Tarefas - Projeto Flutter Lucas Beats

- [X] Analisar todas as instruções e erros recebidos.
- [X] Reverter modificação na tela de registro (`register_screen.dart`): remover campo de e-mail e ajustar chamada da função `register`.
- [X] Ajustar a função `register` em `auth_service.dart` para aceitar apenas `username` e `password` e chamar a API corretamente.
- [X] Revisar e corrigir `clan_management_screen.dart`: substituir `await authService.getCurrentUser()` por `authService.currentUser`.
- [X] Revisar e corrigir `federation_service.dart`: substituir todas as instâncias de `await _authService.getCurrentUser()` por `_authService.currentUser`.
- [X] Revisar e corrigir `clan_service.dart`: substituir todas as instâncias de `await _authService.getCurrentUser()` por `_authService.currentUser`.
- [X] Revisar e corrigir `call_provider.dart`: substituir todas as instâncias de `await _authService.getCurrentUser()` por `_authService.currentUser`.
- [X] Revisar conexão entre frontend e backend (análise de código nos serviços).
- [X] Validar integridade e funcionalidade do projeto (revisão de código, sem compilar).
- [X] Gerar arquivo zip com todos os arquivos do projeto atualizados.
- [X] Reportar conclusão e enviar arquivo zip ao usuário.

# Integração Jitsi Meet + Firebase - FEDERACAOMad

## Resumo das Implementações

Este projeto foi atualizado para integrar o **Jitsi Meet** para chamadas de voz e o **Firebase** para mensagens em tempo real, seguindo a hierarquia de usuários do FEDERACAOMad.

## 🎯 Funcionalidades Implementadas

### 1. Sistema de Chamadas de Voz com Jitsi Meet

- **Salas por Hierarquia:**
  - **Clã:** `voz_clan_{idDoClan}_{numeroDaSala}` (até 5 salas por clã)
  - **Federação:** `voz_fed_{idFederacao}_{numeroDaSala}` (até 3 salas por federação)
  - **Global:** `voz_global_{idUsuario}_{uuid}` (qualquer usuário pode criar)
  - **Admin:** `voz_adm_{contexto}_{id}_{uuid}` (apenas ADMs)

- **Permissões por Role:**
  - **ADM:** Pode criar e entrar em qualquer sala
  - **Líder:** Pode criar salas do clã/federação, entrar em salas da federação
  - **Membro:** Pode entrar em salas do clã, criar salas globais

### 2. Sistema de Mensagens em Tempo Real com Firebase

- **Chat por Contexto:**
  - Chat do Clã
  - Chat da Federação  
  - Chat Global
  
- **Funcionalidades:**
  - Mensagens em tempo real
  - Persistência no Firebase Realtime Database
  - Fallback para API REST quando Firebase não disponível
  - Controle de permissões por role

### 3. Sistema de Permissões Robusto

- **PermissionService:** Centraliza toda lógica de permissões
- **PermissionWidget:** Widget para mostrar/ocultar UI baseado em permissões
- **RoleBasedWidget:** Widget para diferentes conteúdos por role
- **RoleBadge:** Badge visual para identificar roles

## 📁 Arquivos Principais Criados/Modificados

### Novos Arquivos:
- `lib/services/firebase_service.dart` - Serviço Firebase para mensagens e salas
- `lib/services/permission_service.dart` - Lógica de permissões
- `lib/widgets/voice_room_widget.dart` - Widget para salas de voz
- `lib/widgets/permission_widget.dart` - Widgets de controle de permissão
- `lib/widgets/chat_widget.dart` - Widget de chat com Firebase
- `lib/screens/voice_rooms_screen.dart` - Tela principal de salas de voz
- `FIREBASE_SETUP.md` - Guia de configuração do Firebase

### Arquivos Modificados:
- `pubspec.yaml` - Adicionadas dependências Jitsi e Firebase
- `lib/main.dart` - Integração dos novos serviços
- `lib/services/voip_service.dart` - Adaptado para Jitsi Meet
- `lib/services/chat_service.dart` - Integração com Firebase
- `lib/providers/call_provider.dart` - Simplificado para Jitsi
- `lib/screens/call_page.dart` - Adaptado para Jitsi
- `lib/screens/home_screen.dart` - Adicionado botão de salas de voz

## 🚀 Como Usar

### 1. Configurar Firebase
Siga as instruções em `FIREBASE_SETUP.md` para configurar o Firebase.

### 2. Instalar Dependências
```bash
flutter pub get
```

### 3. Executar o App
```bash
flutter run
```

### 4. Testar Funcionalidades

#### Salas de Voz:
1. Na tela principal, toque no ícone de microfone no AppBar
2. Escolha a aba correspondente (Clã, Federação, Global, Admin)
3. Clique em "Criar Sala" ou "Entrar em Sala"
4. O Jitsi Meet será aberto automaticamente

#### Chat em Tempo Real:
1. Use o `ChatWidget` em qualquer tela
2. As mensagens são sincronizadas em tempo real via Firebase
3. Fallback automático para API REST se Firebase não disponível

## 🔐 Sistema de Permissões

### Exemplo de Uso:
```dart
// Mostrar botão apenas para líderes
PermissionWidget(
  requiredAction: 'create_clan_voice_room',
  clanId: clanId,
  child: ElevatedButton(
    onPressed: () => createRoom(),
    child: Text('Criar Sala do Clã'),
  ),
)

// Conteúdo diferente por role
RoleBasedWidget(
  adminWidget: AdminPanel(),
  leaderWidget: LeaderPanel(),
  memberWidget: MemberPanel(),
)
```

## 🎨 Hierarquia de Permissões

### ADM (Admin):
- ✅ Criar/entrar em qualquer sala de voz
- ✅ Enviar mensagens em qualquer chat
- ✅ Gerenciar clãs e federações
- ✅ Promover/remover usuários
- ✅ Acessar painel administrativo
- ✅ Ver estatísticas globais
- ✅ Moderar todos os chats
- ✅ Encerrar salas de outros usuários

### Líder:
- ✅ Criar salas de voz do clã/federação
- ✅ Entrar em salas da federação
- ✅ Gerenciar próprio clã
- ✅ Convidar/expulsar membros do clã
- ✅ Moderar chat do clã/federação
- ✅ Criar salas globais

### Membro:
- ✅ Entrar em salas do clã
- ✅ Enviar mensagens no chat do clã
- ✅ Criar/entrar em salas globais
- ✅ Enviar mensagens globais

## 🔧 Configurações Técnicas

### Dependências Adicionadas:
```yaml
# Firebase
firebase_core: ^2.32.0
firebase_database: ^10.5.7
firebase_messaging: ^14.9.4
firebase_auth: ^4.20.0

# Jitsi Meet
jitsi_meet_wrapper: ^0.0.10
```

### Estrutura Firebase:
```
/users/{userId}
  - fcmToken
  - role
  - ...

/voiceRooms/{roomId}
  - roomName
  - roomType
  - creatorId
  - participants/
  - isActive

/rooms/{roomId}/messages/
  - senderId
  - senderName
  - message
  - timestamp

/messages/ (mensagens diretas)
  - senderId
  - receiverId
  - message
  - timestamp
```

## 📱 Interface do Usuário

### Tela de Salas de Voz:
- **4 Abas:** Clã, Federação, Global, Admin
- **Botões dinâmicos** baseados em permissões
- **Lista de salas ativas** em tempo real
- **Contador de participantes** por sala

### Chat Widget:
- **Mensagens em tempo real** via Firebase
- **Fallback automático** para API REST
- **Indicadores de permissão** para envio
- **Formatação de timestamp** inteligente

### Controles de Permissão:
- **Widgets condicionais** baseados em role
- **Badges visuais** para identificar roles
- **Mensagens de erro** quando sem permissão

## 🔄 Fluxo de Integração

1. **Usuário autentica** → AuthService carrega dados
2. **Firebase inicializa** → FirebaseService configura listeners
3. **Permissões calculadas** → PermissionService valida ações
4. **UI atualizada** → Widgets mostram/ocultam baseado em permissões
5. **Ações executadas** → Jitsi/Firebase processam conforme hierarquia

## 🎯 Próximos Passos Sugeridos

1. **Configurar Firebase** seguindo o guia
2. **Testar em dispositivos reais** para validar Jitsi
3. **Configurar notificações push** para mensagens
4. **Implementar moderação** de chat avançada
5. **Adicionar gravação** de chamadas (se necessário)
6. **Otimizar performance** do Firebase
7. **Implementar analytics** de uso das salas

## 📞 Suporte

Para dúvidas sobre a implementação, consulte:
- Documentação do Jitsi Meet: https://jitsi.github.io/handbook/
- Documentação do Firebase: https://firebase.google.com/docs
- Logs do app via `Logger.info()` para debug

---

**Implementação concluída com sucesso! 🎉**

O projeto agora possui um sistema completo de comunicação por voz e mensagens em tempo real, respeitando a hierarquia de usuários do FEDERACAOMad.


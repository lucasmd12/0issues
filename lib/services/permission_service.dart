import 'package:lucasbeatsfederacao/models/user_model.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class PermissionService {
  // Verificar se o usuário pode criar salas de voz
  static bool canCreateVoiceRoom(UserModel user, String roomType) {
    switch (roomType) {
      case 'clan':
        return user.role == Role.clanLeader || user.role == Role.federationAdmin;
      case 'federation':
        return user.role == Role.clanLeader || user.role == Role.federationAdmin;
      case 'global':
        return true; // Qualquer usuário pode criar salas globais
      case 'admin':
        return user.role == Role.federationAdmin;
      default:
        return false;
    }
  }

  // Verificar se o usuário pode entrar em salas de voz
  static bool canJoinVoiceRoom(UserModel user, String roomType, {String? clanId, String? federationId}) {
    switch (roomType) {
      case 'clan':
        // Deve estar no mesmo clã ou ser admin
        return user.clan == clanId || user.role == Role.federationAdmin;
      case 'federation':
        // Deve ser líder ou admin, e estar na mesma federação
        return (user.role == Role.clanLeader || user.role == Role.federationAdmin) && 
               (user.federation == federationId || user.role == Role.federationAdmin);
      case 'global':
        return true; // Qualquer usuário pode entrar
      case 'admin':
        return user.role == Role.federationAdmin;
      default:
        return false;
    }
  }

  // Verificar se o usuário pode enviar mensagens em um chat
  static bool canSendMessage(UserModel user, String chatType, {String? clanId, String? federationId}) {
    switch (chatType) {
      case 'clan':
        // Deve estar no mesmo clã ou ser admin
        return user.clan == clanId || user.role == Role.federationAdmin;
      case 'federation':
        // Deve estar na mesma federação ou ser admin
        return user.federation == federationId || user.role == Role.federationAdmin;
      case 'global':
        return true; // Qualquer usuário pode enviar mensagens globais
      default:
        return false;
    }
  }

  // Verificar se o usuário pode gerenciar um clã
  static bool canManageClan(UserModel user, String? clanId) {
    if (user.role == Role.federationAdmin) return true;
    if (user.role == Role.clanLeader && user.clan == clanId) return true;
    return false;
  }

  // Verificar se o usuário pode gerenciar uma federação
  static bool canManageFederation(UserModel user, String? federationId) {
    if (user.role == Role.federationAdmin) return true;
    // Apenas admins podem gerenciar federações
    return false;
  }

  // Verificar se o usuário pode promover outros usuários
  static bool canPromoteUser(UserModel promoter, UserModel target, Role newRole) {
    // Apenas admins podem promover
    if (promoter.role != Role.federationAdmin) return false;

    // Não pode promover a si mesmo
    if (promoter.id == target.id) return false;

    // Não pode promover para admin (apenas outros admins podem fazer isso)
    if (newRole == Role.federationAdmin && promoter.role != Role.federationAdmin) return false;

    return true;
  }

  // Verificar se o usuário pode remover outros usuários
  static bool canRemoveUser(UserModel remover, UserModel target) {
    // Apenas admins podem remover usuários
    if (remover.role != Role.federationAdmin) return false;

    // Não pode remover a si mesmo
    if (remover.id == target.id) return false;

    return true;
  }

  // Verificar se o usuário pode acessar o painel administrativo
  static bool canAccessAdminPanel(UserModel user) {
    return user.role == Role.federationAdmin;
  }

  // Verificar se o usuário pode criar clãs
  static bool canCreateClan(UserModel user) {
    return user.role == Role.federationAdmin || user.role == Role.clanLeader;
  }

  // Verificar se o usuário pode criar federações
  static bool canCreateFederation(UserModel user) {
    return user.role == Role.federationAdmin;
  }

  // Verificar se o usuário pode convidar outros para o clã
  static bool canInviteToClan(UserModel user, String? clanId) {
    if (user.role == Role.federationAdmin) return true;
    if (user.role == Role.clanLeader && user.clan == clanId) return true;
    return false;
  }

  // Verificar se o usuário pode expulsar membros do clã
  static bool canKickFromClan(UserModel kicker, UserModel target, String? clanId) {
    // Apenas admins ou líderes do mesmo clã podem expulsar
    if (kicker.role == Role.federationAdmin) return true;
    if (kicker.role == Role.clanLeader && kicker.clan == clanId && target.clan == clanId) {
      // Líder não pode expulsar outro líder
      return target.role != Role.clanLeader;
    }
    return false;
  }

  // Verificar se o usuário pode ver estatísticas globais
  static bool canViewGlobalStats(UserModel user) {
    return user.role == Role.federationAdmin;
  }

  // Verificar se o usuário pode moderar chats
  static bool canModerateChat(UserModel user, String chatType, {String? clanId, String? federationId}) {
    if (user.role == Role.federationAdmin) return true;

    switch (chatType) {
      case 'clan':
        return user.role == Role.clanLeader && user.clan == clanId;
      case 'federation':
        return user.role == Role.clanLeader && user.federation == federationId;
      case 'global':
        return user.role == Role.federationAdmin; // Apenas admins podem moderar chat global
      default:
        return false;
    }
  }

  // Verificar se o usuário pode encerrar salas de voz de outros
  static bool canEndOthersVoiceRoom(UserModel user, String roomType, String creatorId, {String? clanId, String? federationId}) {
    // Admin pode encerrar qualquer sala
    if (user.role == Role.federationAdmin) return true;

    // Criador pode encerrar sua própria sala
    if (user.id == creatorId) return true;

    // Líder pode encerrar salas do seu clã/federação
    switch (roomType) {
      case 'clan':
        return user.role == Role.clanLeader && user.clan == clanId;
      case 'federation':
        return user.role == Role.clanLeader && user.federation == federationId;
      default:
        return false;
    }
  }

  // Obter lista de ações disponíveis para o usuário
  static List<String> getAvailableActions(UserModel user) {
    List<String> actions = [];

    // Ações básicas para todos os usuários
    actions.addAll([
      'send_global_message',
      'join_global_voice_room',
      'create_global_voice_room',
    ]);

    // Ações para membros de clã
    if (user.clan != null) {
      actions.addAll([
        'send_clan_message',
        'join_clan_voice_room',
      ]);
    }

    // Ações para membros de federação
    if (user.federation != null) {
      actions.addAll([
        'send_federation_message',
      ]);
    }

    // Ações para líderes
    if (user.role == Role.clanLeader) {
      actions.addAll([
        'create_clan_voice_room',
        'manage_clan',
        'invite_to_clan',
        'kick_from_clan',
        'moderate_clan_chat',
        'join_federation_voice_room',
        'create_federation_voice_room',
        'moderate_federation_chat',
      ]);
    }

    // Ações para admins
    if (user.role == Role.federationAdmin) {
      actions.addAll([
        'access_admin_panel',
        'create_clan',
        'create_federation',
        'manage_any_clan',
        'manage_any_federation',
        'promote_user',
        'remove_user',
        'view_global_stats',
        'moderate_global_chat',
        'create_admin_voice_room',
        'join_admin_voice_room',
        'end_any_voice_room',
      ]);
    }

    Logger.info('Available actions for user ${user.username} (${user.role}): $actions');
    return actions;
  }

  // Verificar se o usuário tem uma ação específica
  static bool hasAction(UserModel user, String action) {
    return getAvailableActions(user).contains(action);
  }
}



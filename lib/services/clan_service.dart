import 'package:lucasbeatsfederacao/models/clan_model.dart';
import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/services/auth_service.dart';
import 'package:lucasbeatsfederacao/models/channel_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart'; // Importar Role
import 'package:lucasbeatsfederacao/models/member_model.dart'; // Importar Member

class ClanService { // Adicionei 'ClanService' para corrigir o lint de nome
  final ApiService _apiService;
  final AuthService _authService;

  ClanService(this._apiService, this._authService);

  Future<Clan?> getClanDetails(String clanId) async {
    try {
      final response = await _apiService.get('/api/clans/$clanId', requireAuth: true);
      if (response != null) {
        return Clan.fromJson(response);
      }
    } catch (e) {
      Logger.error('Error fetching clan details for $clanId: $e');
    }
    return null;
  }

  Future<List<Member>> getClanMembers(String clanId) async {
    try {
      final response = await _apiService.get('/api/clans/$clanId/members', requireAuth: true);
      if (response != null && response is Map<String, dynamic> && response.containsKey('members') && response['members'] is List) {
        final membersData = response['members'] as List;
        List<Member> members = [];
        for (var memberJson in membersData) {
          // Assuming memberJson is a Map<String, dynamic> representing a User or Member
          // If the backend returns full User objects, adjust Member.fromJson accordingly
          members.add(Member.fromJson(memberJson));
        }
        Logger.info('Fetched ${members.length} members for clan $clanId.');
        return members;
      } else {
        Logger.warning('Unexpected response format when fetching members for clan $clanId: $response');
      }
    } catch (e, s) {
      Logger.error('Error fetching members for clan $clanId', error: e, stackTrace: s);
    }
    return [];
  }

  Future<List<Channel>> getClanChannels(String clanId) async {
    try {
      final endpoint = '/api/voice-channels/clan/$clanId';
      final response = await _apiService.get(endpoint, requireAuth: true);
      if (response != null && response is Map<String, dynamic> && response.containsKey('clanVoiceChannels') && response['clanVoiceChannels'] is List) {
        final channels = (response['clanVoiceChannels'] as List).map((data) => Channel.fromMap(data)).toList();
        Logger.info('Fetched ${channels.length} voice channels for clan $clanId.');
        return channels;
      } else {
        Logger.warning('Unexpected response format when fetching voice channels for clan $clanId: $response');
      }
    } catch (e, s) {
      Logger.error('Error fetching voice channels for clan $clanId', error: e, stackTrace: s);
    }
    return [];
  }

  Future<bool> addMember(String clanId, String userIdToAdd) async {
    final currentUser = _authService.currentUser;
    final clan = await getClanDetails(clanId);
    if (currentUser == null || clan == null) return false;

    String? currentUserRoleInClan;
    if (clan.memberRoles != null) {
      for (var roleMap in clan.memberRoles!) {
        if (roleMap['user'] == currentUser.id) {
          currentUserRoleInClan = roleMap['role'];
          break;
        }
      }
    }

    bool isLeader = currentUser.id == clan.leaderId;
    bool isSubLeader = currentUserRoleInClan == roleToString(Role.subLeader);

    if (!(isLeader || isSubLeader)) {
      Logger.warning('Permission Denied [Add Member]: Only Leader/SubLeader can add members.');
      return false;
    }

    try {
      final response = await _apiService.post('/api/clans/$clanId/members', {'userId': userIdToAdd}, requireAuth: true);
      return response != null;
    } catch (e) {
      Logger.error('Error adding member $userIdToAdd to clan $clanId: $e');
      return false;
    }
  }

  Future<bool> removeMember(String clanId, String userIdToRemove) async {
    final currentUser = _authService.currentUser;
    final clan = await getClanDetails(clanId);

    if (currentUser == null || clan == null) {
      Logger.warning("Permission Denied [Remove Member]: Cannot verify user or clan.");
      return false;
    }

    String? currentUserRoleInClan;
    if (clan.memberRoles != null) {
      for (var roleMap in clan.memberRoles!) {
        if (roleMap['user'] == currentUser.id) {
          currentUserRoleInClan = roleMap['role'];
          break;
        }
      }
    }

    bool isSelfRemoval = userIdToRemove == currentUser.id;
    bool isLeader = currentUser.id == clan.leaderId;
    bool isSubLeader = currentUserRoleInClan == roleToString(Role.subLeader);
    bool isLeaderOrSub = isLeader || isSubLeader;
    bool isRemovingLeader = userIdToRemove == clan.leaderId;
    bool canRemove = isSelfRemoval || (isLeaderOrSub && !isRemovingLeader);

    if (!canRemove) {
       Logger.warning("Permission Denied [Remove Member]: Action not allowed.");
       return false;
    }

    try {
      await _apiService.delete('/api/clans/$clanId/members/$userIdToRemove', requireAuth: true);
      return true;
    } catch (e) {
      Logger.error('Error removing member $userIdToRemove from clan $clanId: $e');
      return false;
    }
  }

  // TODO: REVISAR: O backend não tem um endpoint direto para 'updateMemberRole'.
  // A gestão de roles pode ser feita via 'memberRoles' no ClanModel ou por endpoints específicos de promoção/rebaixamento.
  // Esta função pode ser removida ou adaptada para usar os endpoints de federação/clã para promoção/rebaixamento.
  /*
  Future<bool> updateMemberRole(String clanId, String userId, Role newRole) async {
    if (newRole == Role.federationAdmin || newRole == Role.guest) {
        Logger.warning("Invalid role assignment.");
        return false;
    }

    final UserModel? currentUser = _authService.currentUser;
    final Clan? clan = await getClanDetails(clanId);
    if (currentUser == null || clan == null || currentUser.id != clan.leaderId) {
      Logger.warning("Permission Denied [Update Role]: Only Leader can change roles.");
      return false;
    }
    if (userId == clan.leaderId) {
       Logger.warning("Cannot change the leader's role directly via this method.");
       return false;
    }
    try {
      final response = await _apiService.put(
        '/api/clans/$clanId/members/$userId/role',
        {'role': roleToString(newRole)},
        requireAuth: true
      );
      return response != null;
    } catch (e) {
      Logger.error('Error updating role for member $userId in clan $clanId: $e');
      return false;
    }
  }
  */

  Future<Clan?> getClanById(String clanId) async {
    return await getClanDetails(clanId);
  }

  Future<Clan?> updateClanDetails(String clanId, {String? name, String? bannerImageUrl, String? tag}) async {
    final currentUser = _authService.currentUser;
    final clan = await getClanDetails(clanId);
    if (currentUser == null || clan == null) return null;

    String? currentUserRoleInClan;
    if (clan.memberRoles != null) {
      for (var roleMap in clan.memberRoles!) {
        if (roleMap['user'] == currentUser.id) {
          currentUserRoleInClan = roleMap['role'];
          break;
        }
      }
    }

    bool isLeader = currentUser.id == clan.leaderId;
    bool isSubLeader = currentUserRoleInClan == roleToString(Role.subLeader);

    if (!(isLeader || isSubLeader)) {
      Logger.warning('Permission Denied [Update Clan Details]: Only Leader/SubLeader can update details.');
      return null;
    }

    Map<String, dynamic> dataToUpdate = {};
    if (name != null) dataToUpdate['name'] = name;
    if (bannerImageUrl != null) dataToUpdate['bannerImageUrl'] = bannerImageUrl;
    if (tag != null) dataToUpdate['tag'] = tag;

    if (dataToUpdate.isEmpty) {
      Logger.info('No details provided to update for clan $clanId.');
      return clan;
    }

    try {
      final response = await _apiService.put('/api/clans/$clanId', dataToUpdate, requireAuth: true);
      if (response != null) {
        return Clan.fromJson(response);
      }
    } catch (e) {
      Logger.error('Error updating details for clan $clanId: $e');
    }
    return null;
  }
}



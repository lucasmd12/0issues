// lib/services/cache_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class CacheService {
  static const String _userKey = 'cached_user';
  static const String _statsKey = 'cached_stats';
  static const String _membersKey = 'cached_members';
  static const String _lastUpdateKey = 'last_update_';
  
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Cache do usuário
  static Future<void> cacheUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());
      await prefs.setString(_userKey, userJson);
      await prefs.setString('${_lastUpdateKey}user', DateTime.now().toIso8601String());
      Logger.info('Usuário cacheado com sucesso');
    } catch (e) {
      Logger.error('Erro ao cachear usuário: $e');
    }
  }

  static Future<UserModel?> getCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      final lastUpdate = prefs.getString('${_lastUpdateKey}user');
      
      if (userJson == null || lastUpdate == null) return null;
      
      final updateTime = DateTime.parse(lastUpdate);
      if (DateTime.now().difference(updateTime) > _cacheExpiry) {
        Logger.info('Cache do usuário expirado');
        return null;
      }
      
      final userMap = jsonDecode(userJson);
      return UserModel.fromJson(userMap);
    } catch (e) {
      Logger.error('Erro ao recuperar usuário do cache: $e');
      return null;
    }
  }

  // Cache de estatísticas
  static Future<void> cacheStats(Map<String, dynamic> stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = jsonEncode(stats);
      await prefs.setString(_statsKey, statsJson);
      await prefs.setString('${_lastUpdateKey}stats', DateTime.now().toIso8601String());
      Logger.info('Estatísticas cacheadas com sucesso');
    } catch (e) {
      Logger.error('Erro ao cachear estatísticas: $e');
    }
  }

  static Future<Map<String, dynamic>?> getCachedStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(_statsKey);
      final lastUpdate = prefs.getString('${_lastUpdateKey}stats');
      
      if (statsJson == null || lastUpdate == null) return null;
      
      final updateTime = DateTime.parse(lastUpdate);
      if (DateTime.now().difference(updateTime) > _cacheExpiry) {
        Logger.info('Cache de estatísticas expirado');
        return null;
      }
      
      return Map<String, dynamic>.from(jsonDecode(statsJson));
    } catch (e) {
      Logger.error('Erro ao recuperar estatísticas do cache: $e');
      return null;
    }
  }

  // Cache de membros
  static Future<void> cacheMembers(List<Map<String, dynamic>> members) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final membersJson = jsonEncode(members);
      await prefs.setString(_membersKey, membersJson);
      await prefs.setString('${_lastUpdateKey}members', DateTime.now().toIso8601String());
      Logger.info('Membros cacheados com sucesso');
    } catch (e) {
      Logger.error('Erro ao cachear membros: $e');
    }
  }

  static Future<List<Map<String, dynamic>>?> getCachedMembers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final membersJson = prefs.getString(_membersKey);
      final lastUpdate = prefs.getString('${_lastUpdateKey}members');
      
      if (membersJson == null || lastUpdate == null) return null;
      
      final updateTime = DateTime.parse(lastUpdate);
      if (DateTime.now().difference(updateTime) > _cacheExpiry) {
        Logger.info('Cache de membros expirado');
        return null;
      }
      
      return List<Map<String, dynamic>>.from(jsonDecode(membersJson));
    } catch (e) {
      Logger.error('Erro ao recuperar membros do cache: $e');
      return null;
    }
  }

  // Limpar cache específico
  static Future<void> clearCache(String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      switch (type) {
        case 'user':
          await prefs.remove(_userKey);
          await prefs.remove('${_lastUpdateKey}user');
          break;
        case 'stats':
          await prefs.remove(_statsKey);
          await prefs.remove('${_lastUpdateKey}stats');
          break;
        case 'members':
          await prefs.remove(_membersKey);
          await prefs.remove('${_lastUpdateKey}members');
          break;
      }
      Logger.info('Cache $type limpo com sucesso');
    } catch (e) {
      Logger.error('Erro ao limpar cache $type: $e');
    }
  }

  // Limpar todo o cache
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Logger.info('Todo o cache foi limpo');
    } catch (e) {
      Logger.error('Erro ao limpar todo o cache: $e');
    }
  }

  // Verificar se o cache está válido
  static Future<bool> isCacheValid(String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getString('$_lastUpdateKey$type');
      
      if (lastUpdate == null) return false;
      
      final updateTime = DateTime.parse(lastUpdate);
      return DateTime.now().difference(updateTime) <= _cacheExpiry;
    } catch (e) {
      Logger.error('Erro ao verificar validade do cache $type: $e');
      return false;
    }
  }
}


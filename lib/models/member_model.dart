import 'role_model.dart';

class Member {
  final String userId;        // Sempre o ObjectId do usuário (backend: user)
  final String username;      // Nome do usuário (populado do User)
  final Role role;            // Cargo no clã (enum alinhado ao backend)
  final bool isOnline;        // Status online (populado do User/status em tempo real)
  final String? avatar;       // URL do avatar (populado do User)

  Member({
    required this.userId,
    required this.username,
    required this.role,
    this.isOnline = false,
    this.avatar,
  });

  /// Factory aceita tanto:
  /// - { user: { _id, username, avatar, status }, role }
  /// - { user: 'id', username, avatar, role, isOnline }
  factory Member.fromJson(Map<String, dynamic> json) {
    // Caso venha populado (user é objeto)
    if (json['user'] is Map) {
      final user = json['user'];
      return Member(
        userId: user['_id'] ?? '',
        username: user['username'] ?? 'Usuário Desconhecido',
        avatar: user['avatar'],
        isOnline: user['status'] == 'online' || json['isOnline'] == true,
        role: roleFromString(json['role']),
      );
    }
    // Caso venha só o ID e campos soltos
    return Member(
      userId: json['user'] ?? json['userId'] ?? '',
      username: json['username'] ?? 'Usuário Desconhecido',
      avatar: json['avatar'] ?? json['avatarUrl'],
      isOnline: json['isOnline'] ?? false,
      role: roleFromString(json['role']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': userId,
      'username': username,
      'role': roleToString(role),
      'isOnline': isOnline,
      'avatar': avatar,
    };
  }
}

import 'package:lucasbeatsfederacao/models/role_model.dart';

class UserModel {
  final String id; // _id do backend
  final String username;
  final String? avatar; // Alinhado ao backend
  final String? clan; // ObjectId do clã
  final String? clanName;
  final String? clanRole; // Cargo no clã (string, pode ser convertido para enum Role)
  final String? federation; // ObjectId da federação
  final String? federationName;
  final String? federationRole; // Cargo na federação

  // Campos exclusivos do frontend (anotar para futura integração no backend)
  final String? bio;
  final String? status;
  final bool? online;
  final String? ultimaAtividade;
  final String? tag;
  final String? email;
  final bool? isOnline;

  final DateTime? createdAt;
  final Role role; // Enum alinhado ao backend

  UserModel({
    required this.id,
    required this.username,
    this.avatar,
    this.clan,
    this.clanName,
    this.clanRole,
    this.federation,
    this.federationName,
    this.federationRole,
    this.bio,
    this.status,
    this.online,
    this.ultimaAtividade,
    this.createdAt,
    this.role = Role.user,
    this.tag,
    this.email,
    this.isOnline,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json["_id"] ?? json["uid"] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      username: json["username"] ?? "Usuário Desconhecido",
      avatar: json["avatar"],
      clan: json["clan"],
      clanName: json["clanName"],
      clanRole: json["clanRole"],
      federation: json["federation"],
      federationName: json["federationName"],
      federationRole: json["federationRole"],
      bio: json["bio"], // Exclusivo do frontend
      status: json["status"], // Exclusivo do frontend
      online: json["online"], // Exclusivo do frontend
      ultimaAtividade: json["ultimaAtividade"], // Exclusivo do frontend
      createdAt: json["createdAt"] != null ? DateTime.tryParse(json["createdAt"]) : null,
      role: roleFromString(json["role"]),
      tag: json["tag"], // Exclusivo do frontend
      email: json["email"], // Adicionado
      isOnline: json["isOnline"], // Adicionado
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "username": username,
      "avatar": avatar,
      "clan": clan,
      "clanRole": clanRole,
      "federation": federation,
      "federationRole": federationRole,
      "bio": bio,
      "status": status,
      "online": online,
      "ultimaAtividade": ultimaAtividade,
      "createdAt": createdAt?.toIso8601String(),
      "role": roleToString(role),
      "tag": tag,
    };
  }
}


import 'dart:convert';

class Message {
  final String id;
  final String? clanId; // Pode ser nulo se for mensagem global ou de federação
  final String? federationId; // Adicionado para mensagens de federação
  final String senderId;
  final String senderName; // Adicionado
  final String message;
  final DateTime createdAt;
  final String? fileUrl;
  final String? type;

  Message({
    required this.id,
    this.clanId,
    this.federationId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.createdAt,
    this.fileUrl,
    this.type = 'text',
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['_id'] ?? '',
      clanId: map['clanId'],
      federationId: map['federationId'],
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Usuário Desconhecido',
      message: map['message'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      fileUrl: map['fileUrl'],
      type: map['type'] ?? 'text',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'clanId': clanId,
      'federationId': federationId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (type != null) 'type': type,
    };
  }

  factory Message.fromJson(String source) => Message.fromMap(json.decode(source));
  String toJson() => json.encode(toMap());

  // Adicionando o getter 'timestamp' para compatibilidade
  DateTime get timestamp => createdAt;
}



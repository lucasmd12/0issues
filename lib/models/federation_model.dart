// Assuming Clan model is needed for FederationClan
// Assuming User model is needed for FederationLeader

class FederationLeader {
  final String id;
  final String username;
  final String? avatar;

  FederationLeader({
    required this.id,
    required this.username,
    this.avatar,
  });

  factory FederationLeader.fromJson(Map<String, dynamic> json) {
    return FederationLeader(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['username'] ?? 'Unknown',
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'avatar': avatar,
    };
  }
}

class FederationClan {
  final String id;
  final String name;
  final String? tag;

  FederationClan({
    required this.id,
    required this.name,
    this.tag,
  });

  factory FederationClan.fromJson(Map<String, dynamic> json) {
    return FederationClan(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Unknown Clan',
      tag: json['tag'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'tag': tag,
    };
  }
}

class FederationAlly {
  final String id;
  final String name;

  FederationAlly({
    required this.id,
    required this.name,
  });

  factory FederationAlly.fromJson(Map<String, dynamic> json) {
    return FederationAlly(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Unknown Federation',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
    };
  }
}

class Federation {
  final String id;
  final String name;
  final FederationLeader leader; // Changed from List<FederationLeader> leaders
  final List<FederationClan> clans;
  final List<FederationAlly> allies;
  final List<FederationAlly> enemies;
  final String? description; // From PUT API
  final String? rules; // From PUT API
  final String? banner; // From PUT API

  Federation({
    required this.id,
    required this.name,
    required this.leader,
    required this.clans,
    required this.allies,
    required this.enemies,
    this.description,
    this.rules,
    this.banner,
  });

  factory Federation.fromJson(Map<String, dynamic> json) {
    return Federation(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Default Federation Name',
      leader: FederationLeader.fromJson(json['leader'] ?? {}), // Handle potential null leader
      clans: (json['clans'] as List? ?? [])
          .map((i) => FederationClan.fromJson(i))
          .toList(),
      allies: (json['allies'] as List? ?? [])
          .map((i) => FederationAlly.fromJson(i))
          .toList(),
      enemies: (json['enemies'] as List? ?? [])
          .map((i) => FederationAlly.fromJson(i))
          .toList(),
      description: json['description'],
      rules: json['rules'],
      banner: json['banner'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'leader': leader.toJson(),
      'clans': clans.map((clan) => clan.toJson()).toList(),
      'allies': allies.map((ally) => ally.toJson()).toList(),
      'enemies': enemies.map((enemy) => enemy.toJson()).toList(),
      if (description != null) 'description': description,
      if (rules != null) 'rules': rules,
      if (banner != null) 'banner': banner,
    };
  }
}



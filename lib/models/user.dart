class User {
  final String userId;
  final String email;
  final String? username;
  final int streak;
  final int longestStreak;
  final UserLocation? location;
  final UserSettings? settings;
  final int? createdAt;
  final int? lastActive;
  final bool isPublicProfile;
  final String? profileImageUrl;

  User({
    required this.userId,
    required this.email,
    this.username,
    required this.streak,
    required this.longestStreak,
    this.location,
    this.settings,
    this.createdAt,
    this.lastActive,
    this.isPublicProfile = false,
    this.profileImageUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] ?? '',
      email: json['email'] ?? '',
      username: json['name'] ?? json['username'],
      streak: json['streak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      location: json['location'] != null
          ? UserLocation.fromJson(json['location'])
          : null,
      settings: json['settings'] != null
          ? UserSettings.fromJson(json['settings'])
          : null,
      createdAt: (() {
        final raw = json['createdAt'];
        if (raw == null) return null;
        return raw < 1000000000000 ? raw * 1000 : raw;
      })(),

      lastActive: json['lastActive'],
      isPublicProfile: json['isPublicProfile'] ?? false,
      profileImageUrl: json['profileImageUrl'],
    );
  }

  String get displayName => username ?? email.split('@').first;
  
  String get memberSince {
    if (createdAt == null) return 'Unknown';
    final date = DateTime.fromMillisecondsSinceEpoch(createdAt!);
    return '${_monthName(date.month)} ${date.year}';
  }
  
  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

class UserLocation {
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? timezone;

  UserLocation({
    this.latitude,
    this.longitude,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.timezone,
  });

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      city: json['city'],
      state: json['state'],
      country: json['country'],
      postalCode: json['postalCode'],
      timezone: json['timezone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      if (postalCode != null) 'postalCode': postalCode,
      if (timezone != null) 'timezone': timezone,
    };
  }

  String get displayLocation {
    final parts = <String>[
      if (city != null && city!.isNotEmpty) city!,
      if (state != null && state!.isNotEmpty) state!,
      if (country != null && country!.isNotEmpty) country!,
    ];
    return parts.isEmpty ? 'Not set' : parts.join(', ');
  }
}

class UserSettings {
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;
  final bool waterReminderEnabled;
  final String? preferredUnits; // metric or imperial
  final String? theme;

  UserSettings({
    this.pushNotificationsEnabled = true,
    this.emailNotificationsEnabled = true,
    this.waterReminderEnabled = true,
    this.preferredUnits = 'metric',
    this.theme = 'light',
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      pushNotificationsEnabled: json['pushNotificationsEnabled'] ?? true,
      emailNotificationsEnabled: json['emailNotificationsEnabled'] ?? true,
      waterReminderEnabled: json['waterReminderEnabled'] ?? true,
      preferredUnits: json['preferredUnits'] ?? 'metric',
      theme: json['theme'] ?? 'light',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'emailNotificationsEnabled': emailNotificationsEnabled,
      'waterReminderEnabled': waterReminderEnabled,
      'preferredUnits': preferredUnits,
      'theme': theme,
    };
  }
}

class Friend {
  final String odIn;
  final String odInname;
  final String email;
  final int streak;
  final String status; // pending, accepted, blocked
  final bool isRequester;
  final String? profileImageUrl;
  final int? friendSince;

  Friend({
    required this.odIn,
    required this.odInname,
    required this.email,
    required this.streak,
    required this.status,
    required this.isRequester,
    this.profileImageUrl,
    this.friendSince,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      odIn: json['friendId'] ?? json['userId'] ?? '',
      odInname: json['username'] ?? json['email']?.split('@').first ?? 'Unknown',
      email: json['email'] ?? '',
      streak: json['streak'] ?? 0,
      status: json['status'] ?? 'pending',
      isRequester: json['isRequester'] ?? false,
      profileImageUrl: json['profileImageUrl'],
      friendSince: json['friendSince'],
    );
  }
}

class FriendRequest {
  final String requestId;
  final String fromUserId;
  final String fromUsername;
  final String? fromProfileImage;
  final int streak;
  final int createdAt;

  FriendRequest({
    required this.requestId,
    required this.fromUserId,
    required this.fromUsername,
    this.fromProfileImage,
    required this.streak,
    required this.createdAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      requestId: json['requestId'] ?? '',
      fromUserId: json['fromUserId'] ?? '',
      fromUsername: json['fromUsername'] ?? 'Unknown',
      fromProfileImage: json['fromProfileImage'],
      streak: json['streak'] ?? 0,
      createdAt: (() {
        final raw = json['createdAt'];
        if (raw == null) return 0;
        return raw < 1000000000000 ? raw * 1000 : raw;
      })(),
    );
  }
}

class LeaderboardEntry {
  final int rank;
  final String odIn;
  final String odInname;
  final int streak;
  final int plantCount;
  final String? profileImageUrl;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.rank,
    required this.odIn,
    required this.odInname,
    required this.streak,
    required this.plantCount,
    this.profileImageUrl,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    return LeaderboardEntry(
      rank: json['rank'] ?? 0,
      odIn: json['userId'] ?? '',
      odInname: json['username'] ?? 'Anonymous',
      streak: json['streak'] ?? 0,
      plantCount: json['plantCount'] ?? 0,
      profileImageUrl: json['profileImageUrl'],
      isCurrentUser: json['userId'] == currentUserId,
    );
  }
}
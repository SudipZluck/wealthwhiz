import 'package:cloud_firestore/cloud_firestore.dart';

enum Currency { usd, eur, gbp, inr, jpy, aud, cad }

class User {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final Currency preferredCurrency;
  final bool isDarkMode;
  final bool enableNotifications;
  final DateTime? createdAt;
  DateTime? updatedAt;
  final Map<String, dynamic>? preferences;

  User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.preferredCurrency = Currency.usd,
    this.isDarkMode = false,
    this.enableNotifications = true,
    this.createdAt,
    this.updatedAt,
    this.preferences,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'preferredCurrency': preferredCurrency.toString(),
      'isDarkMode': isDarkMode,
      'enableNotifications': enableNotifications,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'preferences': preferences,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      preferredCurrency: Currency.values.firstWhere(
        (e) => e.toString() == map['preferredCurrency'],
        orElse: () => Currency.usd,
      ),
      isDarkMode: map['isDarkMode'] ?? false,
      enableNotifications: map['enableNotifications'] ?? true,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.parse(map['createdAt'] as String))
          : null,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is Timestamp
              ? (map['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(map['updatedAt'] as String))
          : null,
      preferences: map['preferences'],
    );
  }

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    Currency? preferredCurrency,
    bool? isDarkMode,
    bool? enableNotifications,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? preferences,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
    );
  }
}

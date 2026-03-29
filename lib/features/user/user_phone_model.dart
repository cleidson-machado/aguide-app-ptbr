import 'dart:convert';

/// Model para representar um telefone do usuário
class UserPhoneModel {
  final String id;
  final String fullNumber;
  final String formattedNumber;
  final String type; // 'MOBILE', 'LANDLINE'
  final bool isPrimary;
  final bool isVerified;
  final bool hasWhatsApp;
  final bool hasTelegram;
  final bool hasSignal;
  final DateTime createdAt;

  const UserPhoneModel({
    required this.id,
    required this.fullNumber,
    required this.formattedNumber,
    required this.type,
    required this.isPrimary,
    required this.isVerified,
    required this.hasWhatsApp,
    required this.hasTelegram,
    required this.hasSignal,
    required this.createdAt,
  });

  UserPhoneModel copyWith({
    String? id,
    String? fullNumber,
    String? formattedNumber,
    String? type,
    bool? isPrimary,
    bool? isVerified,
    bool? hasWhatsApp,
    bool? hasTelegram,
    bool? hasSignal,
    DateTime? createdAt,
  }) {
    return UserPhoneModel(
      id: id ?? this.id,
      fullNumber: fullNumber ?? this.fullNumber,
      formattedNumber: formattedNumber ?? this.formattedNumber,
      type: type ?? this.type,
      isPrimary: isPrimary ?? this.isPrimary,
      isVerified: isVerified ?? this.isVerified,
      hasWhatsApp: hasWhatsApp ?? this.hasWhatsApp,
      hasTelegram: hasTelegram ?? this.hasTelegram,
      hasSignal: hasSignal ?? this.hasSignal,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'fullNumber': fullNumber,
      'formattedNumber': formattedNumber,
      'type': type,
      'isPrimary': isPrimary,
      'isVerified': isVerified,
      'hasWhatsApp': hasWhatsApp,
      'hasTelegram': hasTelegram,
      'hasSignal': hasSignal,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserPhoneModel.fromMap(Map<String, dynamic> map) {
    return UserPhoneModel(
      id: map['id'] ?? '',
      fullNumber: map['fullNumber'] ?? '',
      formattedNumber: map['formattedNumber'] ?? '',
      type: map['type'] ?? 'MOBILE',
      isPrimary: map['isPrimary'] ?? false,
      isVerified: map['isVerified'] ?? false,
      hasWhatsApp: map['hasWhatsApp'] ?? false,
      hasTelegram: map['hasTelegram'] ?? false,
      hasSignal: map['hasSignal'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory UserPhoneModel.fromJson(String source) =>
      UserPhoneModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'UserPhoneModel(id: $id, formattedNumber: $formattedNumber, type: $type, isPrimary: $isPrimary)';
  }

  @override
  bool operator ==(covariant UserPhoneModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.fullNumber == fullNumber &&
        other.formattedNumber == formattedNumber &&
        other.type == type &&
        other.isPrimary == isPrimary &&
        other.isVerified == isVerified &&
        other.hasWhatsApp == hasWhatsApp &&
        other.hasTelegram == hasTelegram &&
        other.hasSignal == hasSignal;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        fullNumber.hashCode ^
        formattedNumber.hashCode ^
        type.hashCode ^
        isPrimary.hashCode ^
        isVerified.hashCode ^
        hasWhatsApp.hashCode ^
        hasTelegram.hashCode ^
        hasSignal.hashCode;
  }
}

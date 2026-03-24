/// Value Object: Metadados de Contexto Temporal
/// 
/// Representa informações imutáveis sobre contexto temporal (hora, dia, semana).
/// Usado para telemetria e analytics na feature de User Engagement.
class UserEngagementContextModel {
  final DateTime timestamp;
  final int hourOfDay;
  final String dayOfWeek;
  final int dayOfMonth;
  final int month;
  final int year;
  final bool isWeekend;
  final bool isBusinessHours;
  final String timezone;
  final int timezoneOffset;

  const UserEngagementContextModel({
    required this.timestamp,
    required this.hourOfDay,
    required this.dayOfWeek,
    required this.dayOfMonth,
    required this.month,
    required this.year,
    required this.isWeekend,
    required this.isBusinessHours,
    required this.timezone,
    required this.timezoneOffset,
  });

  /// Factory: Cria a partir de DateTime
  factory UserEngagementContextModel.fromDateTime(DateTime dateTime) {
    final isWeekend = dateTime.weekday >= 6; // Sábado = 6, Domingo = 7
    final isBusinessHours = dateTime.hour >= 9 && dateTime.hour < 17;

    return UserEngagementContextModel(
      timestamp: dateTime,
      hourOfDay: dateTime.hour,
      dayOfWeek: _getWeekdayName(dateTime.weekday),
      dayOfMonth: dateTime.day,
      month: dateTime.month,
      year: dateTime.year,
      isWeekend: isWeekend,
      isBusinessHours: isBusinessHours,
      timezone: dateTime.timeZoneName,
      timezoneOffset: dateTime.timeZoneOffset.inHours,
    );
  }

  /// Factory: Cria com timestamp atual
  factory UserEngagementContextModel.now() {
    return UserEngagementContextModel.fromDateTime(DateTime.now());
  }

  /// Factory: Cria a partir de Map JSON
  factory UserEngagementContextModel.fromJson(Map<String, dynamic> json) {
    return UserEngagementContextModel(
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      hourOfDay: json['hourOfDay'] as int? ?? 0,
      dayOfWeek: json['dayOfWeek'] as String? ?? 'Unknown',
      dayOfMonth: json['dayOfMonth'] as int? ?? 1,
      month: json['month'] as int? ?? 1,
      year: json['year'] as int? ?? 2024,
      isWeekend: json['isWeekend'] as bool? ?? false,
      isBusinessHours: json['isBusinessHours'] as bool? ?? false,
      timezone: json['timezone'] as String? ?? 'UTC',
      timezoneOffset: json['timezoneOffset'] as int? ?? 0,
    );
  }

  /// Serializa para JSON
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'hourOfDay': hourOfDay,
      'dayOfWeek': dayOfWeek,
      'dayOfMonth': dayOfMonth,
      'month': month,
      'year': year,
      'isWeekend': isWeekend,
      'isBusinessHours': isBusinessHours,
      'timezone': timezone,
      'timezoneOffset': timezoneOffset,
    };
  }

  /// Helper: Converte número do dia da semana em nome
  static String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  @override
  String toString() {
    return 'UserEngagementContextMetadata(dayOfWeek: $dayOfWeek, hour: $hourOfDay)';
  }
}

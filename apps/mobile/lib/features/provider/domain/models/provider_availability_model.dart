class ProviderAvailability {
  final String id;
  final String providerId;
  final int? dayOfWeek; // 0=Sunday, 1=Monday, ..., 6=Saturday
  final String startTime;
  final String endTime;
  final DateTime? specificDate;
  final bool isAvailable;
  final DateTime createdAt;

  ProviderAvailability({
    required this.id,
    required this.providerId,
    this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.specificDate,
    this.isAvailable = true,
    required this.createdAt,
  });

  factory ProviderAvailability.fromJson(Map<String, dynamic> json) {
    return ProviderAvailability(
      id: json['id'] as String,
      providerId: json['provider_id'] as String,
      dayOfWeek: json['day_of_week'] as int?,
      startTime: json['start_time'] as String? ?? '09:00:00',
      endTime: json['end_time'] as String? ?? '22:00:00',
      specificDate: json['specific_date'] != null
          ? DateTime.tryParse(json['specific_date'] as String)
          : null,
      isAvailable: json['is_available'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider_id': providerId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'specific_date': specificDate?.toIso8601String().split('T').first,
      'is_available': isAvailable,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

abstract class BaseModel {
  final int? id;
  final String? cloudId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  BaseModel({
    this.id,
    this.cloudId,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap();

  static DateTime parseDate(String s) => DateTime.parse(s);
  static String formatDate(DateTime d) => d.toIso8601String();
}

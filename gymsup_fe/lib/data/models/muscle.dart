class Muscle {
  final String id;
  final String name;
  final String category;

  Muscle({
    required this.id,
    required this.name,
    required this.category,
  });

  factory Muscle.fromJson(Map<String, dynamic> json) {
    return Muscle(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
    );
  }
}

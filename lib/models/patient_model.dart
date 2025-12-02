class Patient {
  final String ehrId;
  final String name;
  final DateTime createdAt;
  final String? sex; 

  Patient({
    required this.ehrId,
    required this.name,
    required this.createdAt,
    this.sex,
  });

  // Convertir a JSON para guardar
  Map<String, dynamic> toJson() {
    return {
      'ehrId': ehrId,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'sex': sex, // ← NUEVO
    };
  }

  // Crear desde JSON al cargar
  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      ehrId: json['ehrId'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      sex: json['sex'] as String?, // ← NUEVO
    );
  }

  // Helper para saber si es mujer
  bool get isFemale => sex?.toUpperCase() == 'F';
  
  // Helper para saber si es hombre
  bool get isMale => sex?.toUpperCase() == 'M';

  @override
  String toString() {
    return 'Patient(ehrId: $ehrId, name: $name, sex: $sex, createdAt: $createdAt)';
  }
}
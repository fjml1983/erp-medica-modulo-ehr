class Validators {
  // Validar que un campo no esté vacío
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }
  
  // Validar nombre (solo letras y espacios)
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es requerido';
    }
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value)) {
      return 'El nombre solo debe contener letras';
    }
    return null;
  }
  
  // Validar número
  static String? number(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    if (double.tryParse(value) == null) {
      return '$fieldName debe ser un número válido';
    }
    return null;
  }
  
  // Validar rango numérico
  static String? numberInRange(String? value, String fieldName, double min, double max) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    final numValue = double.tryParse(value);
    if (numValue == null) {
      return '$fieldName debe ser un número válido';
    }
    if (numValue < min || numValue > max) {
      return '$fieldName debe estar entre $min y $max';
    }
    return null;
  }
  
  // Validar presión arterial
  static String? bloodPressure(String? value, bool isSystolic) {
    if (value == null || value.trim().isEmpty) {
      return 'La presión es requerida';
    }
    final numValue = double.tryParse(value);
    if (numValue == null) {
      return 'Debe ser un número válido';
    }
    if (isSystolic) {
      if (numValue < 70 || numValue > 250) {
        return 'Presión sistólica debe estar entre 70 y 250 mmHg';
      }
    } else {
      if (numValue < 40 || numValue > 150) {
        return 'Presión diastólica debe estar entre 40 y 150 mmHg';
      }
    }
    return null;
  }
  
  // Validar frecuencia cardíaca
  static String? heartRate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La frecuencia cardíaca es requerida';
    }
    final numValue = double.tryParse(value);
    if (numValue == null) {
      return 'Debe ser un número válido';
    }
    if (numValue < 30 || numValue > 250) {
      return 'Frecuencia cardíaca debe estar entre 30 y 250 lpm';
    }
    return null;
  }
  
  // Validar frecuencia respiratoria
  static String? respiratoryRate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La frecuencia respiratoria es requerida';
    }
    final numValue = double.tryParse(value);
    if (numValue == null) {
      return 'Debe ser un número válido';
    }
    if (numValue < 8 || numValue > 60) {
      return 'Frecuencia respiratoria debe estar entre 8 y 60 rpm';
    }
    return null;
  }
  
  // Validar temperatura
  static String? temperature(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La temperatura es requerida';
    }
    final numValue = double.tryParse(value);
    if (numValue == null) {
      return 'Debe ser un número válido';
    }
    if (numValue < 30 || numValue > 45) {
      return 'Temperatura debe estar entre 30 y 45 °C';
    }
    return null;
  }
  
  // Validar peso
  static String? weight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El peso es requerido';
    }
    final numValue = double.tryParse(value);
    if (numValue == null) {
      return 'Debe ser un número válido';
    }
    if (numValue < 0.5 || numValue > 300) {
      return 'Peso debe estar entre 0.5 y 300 kg';
    }
    return null;
  }
  
  // Validar altura
  static String? height(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La altura es requerida';
    }
    final numValue = double.tryParse(value);
    if (numValue == null) {
      return 'Debe ser un número válido';
    }
    if (numValue < 30 || numValue > 250) {
      return 'Altura debe estar entre 30 y 250 cm';
    }
    return null;
  }
  
  // Validar fecha (no puede ser futura para fecha de nacimiento)
  static String? pastDate(DateTime? value) {
    if (value == null) {
      return 'La fecha es requerida';
    }
    if (value.isAfter(DateTime.now())) {
      return 'La fecha no puede ser futura';
    }
    return null;
  }
}
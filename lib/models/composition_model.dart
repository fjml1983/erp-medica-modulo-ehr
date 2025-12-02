import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

class CompositionModel {
  Map<String, dynamic> data;
  
  CompositionModel({required this.data});

  /// Cargar template base desde assets
  /// Cargar template base desde assets
static Future<CompositionModel> loadTemplate({
  required String composerName,
  String facilityName = 'ITSUR',
}) async {
  // Cargar el JSON del template
  final String jsonString = await rootBundle.loadString('assets/composition_template.json');
  final Map<String, dynamic> templateData = jsonDecode(jsonString);
  
  // Actualizar campos dinámicos
  final now = DateTime.now().toUtc().toIso8601String();
  final uuid = const Uuid();
  
  // Actualizar fechas y nombres
  templateData['his_medica_itsur.historia_clinica_nom004.v1/context/start_time'] = now;
  templateData['his_medica_itsur.historia_clinica_nom004.v1/context/_end_time'] = now;
  templateData['his_medica_itsur.historia_clinica_nom004.v1/context/_health_care_facility|name'] = facilityName;
  templateData['his_medica_itsur.historia_clinica_nom004.v1/composer|name'] = composerName;
  
  // NO agregamos name aquí, se agrega en ehr_service.dart antes de enviar
  
  // Actualizar todos los UUIDs de _work_flow_id y _guideline_id
  templateData.forEach((key, value) {
    if (key.contains('_work_flow_id|id') || key.contains('_guideline_id|id')) {
      templateData[key] = uuid.v4();
    }
    // Actualizar todas las fechas dinámicas
    if (key.contains('/last_updated') || 
        key.contains('/time') ||
        key.contains('start_time') ||
        key.contains('date_of_birth') || 
        key.contains('date_of_death')) {
      if (value is String && value.contains('2022-02-03')) {
        templateData[key] = now;
      }
    }
  });
  
  // Remover el _uid si existe (solo para composiciones nuevas)
  templateData.remove('his_medica_itsur.historia_clinica_nom004.v1/_uid');
  
  return CompositionModel(data: templateData);
}

  /// Cargar desde JSON existente (para editar)
  factory CompositionModel.fromJson(Map<String, dynamic> json) {
    return CompositionModel(data: json);
  }

  /// Convertir a JSON para enviar a EHRbase
  Map<String, dynamic> toJson() {
    // Asegurar que siempre tenga name|value
    if (!data.containsKey('his_medica_itsur.historia_clinica_nom004.v1/name|value') ||
        data['his_medica_itsur.historia_clinica_nom004.v1/name|value'] == null ||
        data['his_medica_itsur.historia_clinica_nom004.v1/name|value'] == '') {
      data['his_medica_itsur.historia_clinica_nom004.v1/name|value'] = 'Historia Clínica';
    }
    
    // Remover _name si existe (formato incorrecto)
    data.remove('his_medica_itsur.historia_clinica_nom004.v1/name|value');
    data.remove('his_medica_itsur.historia_clinica_nom004.v1/_name');
    
    return data;
  }

  /// Actualizar un campo específico
  void updateField(String key, dynamic value) {
    data[key] = value;
  }

  /// Obtener un campo específico
  dynamic getField(String key) => data[key];
  
  /// Obtener UID de la composición (si existe)
  String? get uid => data['his_medica_itsur.historia_clinica_nom004.v1/_uid'];
  
  /// Obtener fecha de inicio
  String? get startTime => data['his_medica_itsur.historia_clinica_nom004.v1/context/start_time'];
  
  /// Obtener nombre del compositor
  String? get composerName => data['his_medica_itsur.historia_clinica_nom004.v1/composer|name'];
  
  /// Obtener motivo de consulta
  String? get reasonForEncounter => 
      data['his_medica_itsur.historia_clinica_nom004.v1/reason_for_encounter/presenting_problem:0'];
}
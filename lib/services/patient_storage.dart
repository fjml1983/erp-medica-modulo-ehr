import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient_model.dart';

class PatientStorage {
  static const String _key = 'patients_list';

  // Guardar lista de pacientes
  static Future<void> savePatients(List<Patient> patients) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final patientsJson = patients.map((p) => p.toJson()).toList();
      final jsonString = jsonEncode(patientsJson);
      
      print('💾 Guardando ${patients.length} pacientes...');
      print('📝 JSON a guardar: $jsonString');
      
      final success = await prefs.setString(_key, jsonString);
      
      if (success) {
        print('✅ ${patients.length} pacientes guardados exitosamente');
      } else {
        print('❌ Error al guardar pacientes');
      }
    } catch (e) {
      print('❌ Excepción al guardar pacientes: $e');
    }
  }

  // Cargar lista de pacientes
  static Future<List<Patient>> loadPatients() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? patientsString = prefs.getString(_key);
      
      print('📂 Intentando cargar pacientes...');
      
      if (patientsString == null || patientsString.isEmpty) {
        print('📭 No hay pacientes guardados en SharedPreferences');
        return [];
      }

      print('📝 JSON cargado: $patientsString');

      final List<dynamic> patientsJson = jsonDecode(patientsString);
      final patients = patientsJson
          .map((json) => Patient.fromJson(json as Map<String, dynamic>))
          .toList();
      
      print('✅ ${patients.length} pacientes cargados correctamente');
      for (var p in patients) {
        print('   - ${p.name} (${p.ehrId})');
      }
      
      return patients;
    } catch (e, stackTrace) {
      print('❌ Error al cargar pacientes: $e');
      print('📍 StackTrace: $stackTrace');
      return [];
    }
  }

  // Agregar un paciente nuevo
  static Future<void> addPatient(Patient patient) async {
    print('➕ Agregando paciente: ${patient.name}');
    final patients = await loadPatients();
    patients.add(patient);
    print('📊 Total de pacientes después de agregar: ${patients.length}');
    await savePatients(patients);
  }

  // Eliminar un paciente
  static Future<void> removePatient(String ehrId) async {
    print('➖ Eliminando paciente con EHR ID: $ehrId');
    final patients = await loadPatients();
    final initialCount = patients.length;
    patients.removeWhere((p) => p.ehrId == ehrId);
    print('📊 Pacientes eliminados: ${initialCount - patients.length}');
    await savePatients(patients);
  }

  // Limpiar todos los pacientes (útil para testing)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    print('🗑️ Todos los pacientes eliminados del storage');
  }

  // Buscar un paciente por EHR ID
  static Future<Patient?> findPatientByEhrId(String ehrId) async {
    final patients = await loadPatients();
    try {
      return patients.firstWhere((p) => p.ehrId == ehrId);
    } catch (e) {
      print('⚠️ Paciente con EHR ID $ehrId no encontrado');
      return null;
    }
  }

  // DEBUG: Ver el contenido crudo de SharedPreferences
  static Future<void> debugPrintStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    print('🔍 === DEBUG SHAREDPREFERENCES ===');
    print('Total de keys: ${keys.length}');
    for (var key in keys) {
      print('  Key: $key');
      print('  Value: ${prefs.get(key)}');
    }
    print('================================');
  }
}
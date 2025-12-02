import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class AppConstants {
  static const String appTitle = 'HIS Médica ITSUR';
  
  // Template ID de EHRbase
  static const String templateId = 'his_medica_itsur.historia_clinica_nom004.v1';
  
  // ========== URLs DINÁMICAS ==========
  
  // URL base de EHRbase (dinámica según plataforma)
  static String get ehrbaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8081';
    } else {
      try {
        if (Platform.isAndroid) {
          return 'http://10.0.2.2:8081';
        } else {
          return 'http://localhost:8081';
        }
      } catch (e) {
        return 'http://localhost:8081';
      }
    }
  }
  
  // Rutas base
  static const String ehrbaseBasePath = '/ehrbase/rest/openehr/v1';
  
// Endpoints dinámicos (getters)
static String get ehrEndpoint => '$ehrbaseUrl$ehrbaseBasePath/ehr';
static String get compositionEndpoint => '$ehrbaseUrl$ehrbaseBasePath/composition';
static String get queryEndpoint => '$ehrbaseUrl$ehrbaseBasePath/query/aql';
static String get templateEndpoint => '$ehrbaseUrl$ehrbaseBasePath/definition/template/adl1.4/$templateId/example';





// Endpoint de composición para un EHR específico
static String compositionEndpointForEhr(String ehrId) {
  // Codificar el template_id para URL
  final encodedTemplateId = Uri.encodeComponent(templateId);
  return '$ehrbaseUrl$ehrbaseBasePath/ehr/$ehrId/composition?format=FLAT&templateId=$encodedTemplateId';
}
  
  

  // Endpoint de creación de EHR con parámetro
  static String createEhrEndpoint({String? ehrId}) {
    if (ehrId != null) {
      return '$ehrbaseUrl$ehrbaseBasePath/ehr/$ehrId';
    }
    return '$ehrbaseUrl$ehrbaseBasePath/ehr';
  }
  
  // ========== CONSTANTES PARA COMPOSICIONES ==========
  
  // Headers JSON
  static Map<String, String> get jsonHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Headers para composiciones (formato estándar)
static Map<String, String> get compositionHeaders => {
  'Content-Type': 'application/json',  // ← Simple JSON
  'Accept': 'application/json',
  'Prefer': 'return=representation',
};

  // Headers para composiciones (formato FLAT requiere template ID)
static Map<String, String> compositionHeadersFlat() {
  return {
    'Content-Type': 'application/json',  // ✅ CORRECTO
    'Accept': 'application/json',
    'Prefer': 'return=representation',
  };
}
  
  // ========== CONFIGURACIÓN DE COMPOSICIONES ==========
  
  // Información de contexto de la composición
  static const String institutionName = 'ITSUR';
  static const String institutionShortName = 'ITSUR';
  static const String connectionInfo = 'Sistema HIS Médica ITSUR';
  
  // Configuración de idioma y territorio
  static const String defaultLanguage = 'es';
  static const String iso639Terminology = 'ISO_639-1';
  static const String defaultTerritory = 'MX';
  static const String iso3166Terminology = 'ISO_3166-1';
  
  // Template path para composiciones
  static const String templatePath = 'his_medica_itsur.historia_clinica_nom004.v1';
  
  // Terminología openEHR
  static const String openehrTerminology = 'openehr';
  
  // Códigos de categoría de eventos
  static const String eventCategoryCode = '433';
  static const String eventCategoryValue = 'event';
  
  // Códigos de configuración del sistema
  static const String homeSettingCode = 'at0004';
  static const String homeSettingValue = 'home';
  
  // Endpoint de lista de templates
  static String get templateListEndpoint => '$ehrbaseUrl$ehrbaseBasePath/definition/template/adl1.4';
  
  // Método para obtener el endpoint de un template específico
  static String templateExampleEndpoint(String templateId) {
    return '$ehrbaseUrl$ehrbaseBasePath/definition/template/adl1.4/$templateId/example';
  }
}
import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/ehr_service.dart';
import '../utils/constants.dart';
import 'patient_manager.dart';
import '../debug_template.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _ehrService = EhrService();
  bool _isConnected = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() => _isChecking = true);
    
    try {
      final connected = await _ehrService.validateConnection();
      if (mounted) {
        setState(() {
          _isConnected = connected;
          _isChecking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expediente Clínico HIS-MEDICA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkConnection,
            tooltip: 'Verificar conexión',
          ),
        ],
      ),
      body: _isChecking
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Verificando conexión con EHRbase...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Estado de conexión
                  Card(
                    color: _isConnected ? Colors.green[50] : Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            _isConnected ? Icons.check_circle : Icons.error,
                            color: _isConnected ? Colors.green : Colors.red,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isConnected
                                      ? 'Conectado a EHRbase'
                                      : 'Sin conexión a EHRbase',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppConstants.connectionInfo,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                if (!_isConnected) ...[
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Verifica que EHRbase esté corriendo en Docker',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Información del sistema
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_hospital, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  AppConstants.institutionName,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sistema de Expedientes Clínicos Electrónicos',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const Divider(height: 24),
                          _InfoRow(
                            icon: Icons.document_scanner,
                            label: 'Template',
                            value: AppConstants.templateId,
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.language,
                            label: 'Idioma',
                            value: 'Español (MX)',
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.description,
                            label: 'Norma',
                            value: 'NOM-004',
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Botón principal
                  ElevatedButton.icon(
                    onPressed: _isConnected
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PatientManager(),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.person_add, size: 24),
                    label: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Gestionar Pacientes',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ← BOTÓN NUEVO (TEMPORAL PARA DEBUG)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DebugTemplate(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Debug Template (Temporal)'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  ),


                  // Botón ver ejemplo
                  OutlinedButton.icon(
                    onPressed: _isConnected ? _loadTemplateExample : null,
                    icon: const Icon(Icons.file_download),
                    label: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Ver Ejemplo del Template',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Footer
                  Center(
                    child: Text(
                      'Versión 1.0.0 - ${AppConstants.institutionShortName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _loadTemplateExample() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final example = await _ehrService.getTemplateExample();
      if (!mounted) return;
      
      Navigator.pop(context); // Cerrar loading
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ejemplo del Template'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(
                const JsonEncoder.withIndent('  ').convert(example),
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar ejemplo: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }
}
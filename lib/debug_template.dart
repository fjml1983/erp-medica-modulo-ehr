import 'package:flutter/material.dart';
import 'dart:convert';
import 'services/ehr_service.dart';

class DebugTemplate extends StatefulWidget {
  const DebugTemplate({super.key});

  @override
  State<DebugTemplate> createState() => _DebugTemplateState();
}

class _DebugTemplateState extends State<DebugTemplate> {
  final _ehrService = EhrService();
  String _templateJson = 'Cargando...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    try {
      final template = await _ehrService.getTemplateExample();
      setState(() {
        _templateJson = const JsonEncoder.withIndent('  ').convert(template);
        _isLoading = false;
      });
      
      // Buscar campos relacionados con gineco-obstétricos
      print('🔍 ===== CAMPOS GINECO-OBSTÉTRICOS =====');
      template.forEach((key, value) {
        if (key.toLowerCase().contains('obstetric') ||
            key.toLowerCase().contains('menstrual') ||
            key.toLowerCase().contains('contraceptive') ||
            key.toLowerCase().contains('menstruation') ||
            key.toLowerCase().contains('pregnancy') ||
            key.toLowerCase().contains('gynec')) {
          print('✅ ENCONTRADO: $key = $value');
        }
      });
      print('======================================');
    } catch (e) {
      setState(() {
        _templateJson = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Template'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                _templateJson,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            ),
    );
  }
}
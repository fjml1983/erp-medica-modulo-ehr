import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/ehr_service.dart';

class CompositionDetail extends StatefulWidget {
  final String ehrId;  // ← NUEVO
  final String compositionUid;
  final String compositionTitle;

  const CompositionDetail({
    super.key,
    required this.ehrId,  // ← NUEVO
    required this.compositionUid,
    required this.compositionTitle,
  });

  @override
  State<CompositionDetail> createState() => _CompositionDetailState();
}

class _CompositionDetailState extends State<CompositionDetail> {
  final _ehrService = EhrService();
  Map<String, dynamic>? _compositionData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComposition();
  }

  Future<void> _loadComposition() async {
    setState(() => _isLoading = true);

    try {
      final data = await _ehrService.getCompositionByUidWithEhrId(
        widget.ehrId,
        widget.compositionUid,
      );
      setState(() {
        _compositionData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar composición: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Expediente Clínico'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadComposition,
            tooltip: 'Recargar',
          ),
          IconButton(
            icon: const Icon(Icons.code),
            onPressed: _showRawJson,
            tooltip: 'Ver JSON',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _compositionData == null
              ? const Center(
                  child: Text('No se pudo cargar la composición'),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        'Información General',
                        Icons.info_outline,
                        _buildGeneralInfo(),
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        'Motivo de Consulta',
                        Icons.message,
                        _buildReasonForEncounter(),
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        'Padecimiento Actual',
                        Icons.medical_information,
                        _buildStoryHistory(),
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        'Antecedentes Heredofamiliares',
                        Icons.family_restroom,
                        _buildFamilyHistory(),
                      ),
                      if (_hasGynecoObstetricData())
                          const SizedBox(height: 16),
                        if (_hasGynecoObstetricData())
                          _buildSection(
                            'Antecedentes Gineco-Obstétricos',
                            Icons.female,
                            _buildGynecoObstetric(),
                          ),

                        const SizedBox(height: 16),
                        _buildSection(
                          'Signos Vitales',
                          Icons.favorite,
                          _buildVitalSigns(),
                        ),
                      const SizedBox(height: 16),
                      _buildSection(
                        'Signos Vitales',
                        Icons.favorite,
                        _buildVitalSigns(),
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        'Diagnóstico',
                        Icons.local_hospital,
                        _buildDiagnosis(),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralInfo() {
    final composer = _compositionData?['his_medica_itsur.historia_clinica_nom004.v1/composer|name'] ?? 'N/A';
    final startTime = _compositionData?['his_medica_itsur.historia_clinica_nom004.v1/context/start_time'] ?? 'N/A';
    final facility = _compositionData?['his_medica_itsur.historia_clinica_nom004.v1/context/_health_care_facility|name'] ?? 'N/A';
    final uid = _compositionData?['his_medica_itsur.historia_clinica_nom004.v1/_uid'] ?? widget.compositionUid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Médico', composer),
        _buildInfoRow('Fecha', _formatDateTime(startTime)),
        _buildInfoRow('Institución', facility),
        _buildInfoRow('UID', uid, isCode: true),
      ],
    );
  }

  Widget _buildReasonForEncounter() {
    final reason = _compositionData?['his_medica_itsur.historia_clinica_nom004.v1/reason_for_encounter/presenting_problem:0'] ?? 'No especificado';
    final contactType = _compositionData?['his_medica_itsur.historia_clinica_nom004.v1/reason_for_encounter/contact_type:0'] ?? 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Tipo de Consulta', contactType),
        _buildInfoRow('Problema Presentado', reason),
      ],
    );
  }

  Widget _buildFamilyHistory() {
    final summary = _compositionData?['his_medica_itsur.historia_clinica_nom004.v1/family_history:0/summary'] ?? 'No especificado';
    
    return _buildInfoRow('Resumen', summary);
  }

  Widget _buildStoryHistory() {
    final story = _compositionData?['his_medica_itsur.historia_clinica_nom004.v1/story_history/any_event:0/story:0'] ?? 'No especificado';
    
    return Text(story);
  }

  Widget _buildVitalSigns() {
    final systolic = _compositionData?['his_medica_itsur.historia_clinica_nom004.v1/blood_pressure/any_event:0/systolic|magnitude'];
    final diastolic = _compositionData?['his_medica_itsur.historia_clinica_nom004.v1/blood_pressure/any_event:0/diastolic|magnitude'];
    final heartRate = _compositionData?['his_medica_itsur.historia_clinica_nom004.v1/pulse_heart_beat/any_event:0/rate|magnitude'];
    final respRate = _compositionData?['his_medica_itsur.historia_clinica_nom004.v1/respiration/any_event:0/rate|magnitude'];
    final temp = _compositionData?['his_medica_itsur.historia_clinica_nom004.v1/body_temperature/any_event:0/temperature|magnitude'];
    final weight = _compositionData?['his_medica_itsur.historia_clinica_nom004.v1/body_weight/any_event:0/weight|magnitude'];
    final height = _compositionData?['his_medica_itsur.historia_clinica_nom004.v1/height_length/any_event:0/height_length|magnitude'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (systolic != null && diastolic != null)
          _buildInfoRow('Presión Arterial', '$systolic/$diastolic mmHg'),
        if (heartRate != null)
          _buildInfoRow('Frecuencia Cardíaca', '$heartRate lpm'),
        if (respRate != null)
          _buildInfoRow('Frecuencia Respiratoria', '$respRate rpm'),
        if (temp != null)
          _buildInfoRow('Temperatura', '$temp °C'),
        if (weight != null)
          _buildInfoRow('Peso', '$weight kg'),
        if (height != null)
          _buildInfoRow('Talla', '$height cm'),
        if (systolic == null && heartRate == null && temp == null)
          const Text('No se registraron signos vitales'),
      ],
    );
  }

  Widget _buildDiagnosis() {
    final diagnosis = _compositionData?['his_medica_itsur.historia_clinica_nom004.v1/problem_diagnosis:0/problem_diagnosis_name'] ?? 'No especificado';
    final description = _compositionData?['his_medica_itsur.historia_clinica_nom004.v1/problem_diagnosis:0/clinical_description'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Diagnóstico', diagnosis),
        if (description.isNotEmpty)
          _buildInfoRow('Descripción', description),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isCode = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: isCode ? 'monospace' : null,
                fontSize: isCode ? 12 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dt = DateTime.parse(dateTimeStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  void _showRawJson() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('JSON Completo'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              const JsonEncoder.withIndent('  ').convert(_compositionData),
              style: const TextStyle(
                fontSize: 11,
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
  }

 // Verificar si hay datos AGO
bool _hasGynecoObstetricData() {
  if (_compositionData == null) return false;
  
  final fum = _compositionData?['his_medica_itsur.historia_clinica_nom004.v1/last_menstrual_period/date_of_onset_lmp'];
  final gravidity = _compositionData?['his_medica_itsur.historia_clinica_nom004.v1/obstetric_summary/gravidity'];
  
  return fum != null || gravidity != null;
}

// Construir la sección de AGO
Widget _buildGynecoObstetric() {
  final fum = _compositionData?['his_medica_itsur.historia_clinica_nom004.v1/last_menstrual_period/date_of_onset_lmp'] ?? 'No registrado';
  final menstruacion = _compositionData?['his_medica_itsur.historia_clinica_nom004.v1/menstruation_summary/overall_description'] ?? 'No registrado';
  final gravidity = _compositionData?['his_medica_itsur.historia_clinica_nom004.v1/obstetric_summary/gravidity'];
  final parity = _compositionData?['his_medica_itsur.historia_clinica_nom004.v1/obstetric_summary/parity'];
  final abortions = _compositionData?['his_medica_itsur.historia_clinica_nom004.v1/obstetric_summary/abortions'];
  final caesarean = _compositionData?['his_medica_itsur.historia_clinica_nom004.v1/obstetric_summary/caesarean_sections'];
  final liveBirths = _compositionData?['his_medica_itsur.historia_clinica_nom004.v1/obstetric_summary/live_births'];
  final contraceptive = _compositionData?['his_medica_itsur.historia_clinica_nom004.v1/contraceptive_use_summary/overall_description'] ?? 'No registrado';

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildInfoRow('FUM', fum),
      _buildInfoRow('Patrón Menstrual', menstruacion),
      const Divider(height: 24),
      if (gravidity != null || parity != null || abortions != null)
        Text(
          'Fórmula Obstétrica (GPAVC):',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
      if (gravidity != null)
        _buildInfoRow('Gestas (G)', gravidity.toString()),
      if (parity != null)
        _buildInfoRow('Partos (P)', parity.toString()),
      if (abortions != null)
        _buildInfoRow('Abortos (A)', abortions.toString()),
      if (liveBirths != null)
        _buildInfoRow('Hijos Vivos (V)', liveBirths.toString()),
      if (caesarean != null)
        _buildInfoRow('Cesáreas (C)', caesarean.toString()),
      const Divider(height: 24),
      _buildInfoRow('Método Anticonceptivo', contraceptive),
    ],
  );
}
}
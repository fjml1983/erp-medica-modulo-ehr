import 'package:flutter/material.dart';
import '../models/patient_model.dart';
import '../services/ehr_service.dart';
import 'composition_form/composition_form_wizard.dart';
import 'composition_detail.dart';

class CompositionList extends StatefulWidget {
  final Patient patient;

  const CompositionList({
    super.key,
    required this.patient,
  });

  @override
  State<CompositionList> createState() => _CompositionListState();
}

class _CompositionListState extends State<CompositionList> {
  final _ehrService = EhrService();
  List<Map<String, dynamic>> _compositions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompositions();
  }

  Future<void> _loadCompositions() async {
    setState(() => _isLoading = true);

    try {
      final compositions = await _ehrService.getCompositions(widget.patient.ehrId);
      setState(() {
        _compositions = compositions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar el expediente clínico: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patient.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCompositions,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _compositions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medical_information_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay expedientes clínicos',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crea el primer expediente clínico',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _compositions.length,
                  itemBuilder: (context, index) {
                    final comp = _compositions[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.description),
                        ),
                        title: Text(comp['reason'] ?? 'Sin motivo'),
                        subtitle: Text(
                          'Médico: ${comp['composer_name']}\n'
                          'Fecha: ${comp['start_time']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          final uid = comp['uid'] as String;
                          print('🎯 Abriendo composición con UID: $uid');
                          print('👤 EHR ID del paciente: ${widget.patient.ehrId}');
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CompositionDetail(
                                ehrId: widget.patient.ehrId,  // ← NUEVO
                                compositionUid: uid,
                                compositionTitle: comp['reason'] ?? 'Sin motivo',
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewComposition(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Expediente Clínico'),
      ),
    );
  }

  Future<void> _createNewComposition() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompositionFormWizard(
          patient: widget.patient,
        ),
      ),
    );

    if (result == true) {
      _loadCompositions();
    }
  }
}
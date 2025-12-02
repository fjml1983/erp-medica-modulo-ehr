import 'package:flutter/material.dart';
import '../../models/patient_model.dart';
import '../../models/composition_model.dart';
import '../../services/ehr_service.dart';

class CompositionFormWizard extends StatefulWidget {
  final Patient patient;

  const CompositionFormWizard({
    super.key,
    required this.patient,
  });

  @override
  State<CompositionFormWizard> createState() => _CompositionFormWizardState();
}

class _CompositionFormWizardState extends State<CompositionFormWizard> {
  final _ehrService = EhrService();
  final _pageController = PageController();

  int _currentStep = 0;
  final int _totalSteps = 9;

  CompositionModel? _compositionModel;
  bool _isLoading = true;
  bool _isSaving = false;

  // Controladores para campos principales
  final _composerNameController = TextEditingController(text: 'Dr. Arturo ITSUR');
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _composerNameController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplate() async {
    setState(() => _isLoading = true);

    try {
      final composition = await CompositionModel.loadTemplate(
        composerName: _composerNameController.text,
      );

      setState(() {
        _compositionModel = composition;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar template: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  //
  // Helper: eliminar claves/objetos relacionados con AGO del JSON de la composición
  //
  Map<String, dynamic> _removeAgoKeysRecursively(Map<String, dynamic> map) {
    const agoFragments = [
      'obstetric',
      'menstrual',
      'menstruation',
      'contraceptive',
      'last_menstrual',
      'obstetric_summary',
      'last_menstrual_period',
      'gpavc',
      'ago'
    ];

    final result = <String, dynamic>{};
    map.forEach((key, value) {
      final keyLower = key.toLowerCase();
      final matchesAgo = agoFragments.any((frag) => keyLower.contains(frag));
      if (matchesAgo) {
        // omit this key entirely
        return;
      }

      if (value is Map<String, dynamic>) {
        final cleaned = _removeAgoKeysRecursively(value);
        if (cleaned.isNotEmpty) result[key] = cleaned;
      } else if (value is List) {
        final newList = <dynamic>[];
        for (final e in value) {
          if (e is Map<String, dynamic>) {
            final cleaned = _removeAgoKeysRecursively(e);
            if (cleaned.isNotEmpty) newList.add(cleaned);
          } else {
            newList.add(e);
          }
        }
        if (newList.isNotEmpty) result[key] = newList;
      } else {
        result[key] = value;
      }
    });

    return result;
  }

  // Helper debug: encontrar claves AGO existentes en el mapa (para debug)
  List<String> _findAgoKeys(Map<String, dynamic> map, [String prefix = '']) {
    const agoFragments = [
      'obstetric',
      'menstrual',
      'menstruation',
      'contraceptive',
      'last_menstrual',
      'obstetric_summary',
      'last_menstrual_period',
      'gpavc',
      'ago'
    ];
    final found = <String>[];
    map.forEach((k, v) {
      final path = prefix.isEmpty ? k : '$prefix.$k';
      if (agoFragments.any((frag) => k.toLowerCase().contains(frag))) {
        found.add(path);
      }
      if (v is Map<String, dynamic>) {
        found.addAll(_findAgoKeys(v, path));
      } else if (v is List) {
        for (var i = 0; i < v.length; i++) {
          final e = v[i];
          if (e is Map<String, dynamic>) {
            found.addAll(_findAgoKeys(e, '$path[$i]'));
          }
        }
      }
    });
    return found;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expediente Clínico de ${widget.patient.name}'),
        actions: [
          if (!_isLoading && _compositionModel != null)
            TextButton.icon(
              onPressed: _isSaving ? null : _saveComposition,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(
                _isSaving ? 'Guardando...' : 'Guardar',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando template...'),
                ],
              ),
            )
          : Column(
              children: [
                // Indicador de progreso
                _buildProgressIndicator(),

                // Contenido del paso actual
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() => _currentStep = index);
                    },
                    children: [
                      _buildStep1BasicInfo(),
                      _buildStep2ReasonForEncounter(),
                      _buildStep3Story(),
                      _buildStep4FamilyHistory(),
                      _buildStep5PersonalHistory(),
                      _buildStep6GynecoObstetric(), // ← NUEVO
                      _buildStep7VitalSigns(),
                      _buildStep8PhysicalExam(),
                      _buildStep9Diagnosis(),
                    ],
                  ),
                ),

                // Botones de navegación
                _buildNavigationButtons(),
              ],
            ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / _totalSteps,
                  backgroundColor: Colors.grey[300],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Paso ${_currentStep + 1} de $_totalSteps',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getStepTitle(_currentStep),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Información Básica';
      case 1:
        return 'Motivo de Consulta';
      case 2:
        return 'Padecimiento Actual';
      case 3:
        return 'Antecedentes Heredofamiliares';
      case 4:
        return 'Antecedentes Personales';
      case 5:
        return 'Antecedentes Gineco-Obstétricos'; // ← NUEVO
      case 6:
        return 'Signos Vitales';
      case 7:
        return 'Exploración Física';
      case 8:
        return 'Diagnóstico y Plan';
      default:
        return '';
    }
  }

  Widget _buildStep1BasicInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información del Médico y Consulta',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _composerNameController,
            decoration: const InputDecoration(
              labelText: 'Nombre del Médico',
              prefixIcon: Icon(Icons.medical_services),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paciente',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Divider(),
                  Text('Nombre: ${widget.patient.name}'),
                  Text('EHR ID: ${widget.patient.ehrId}'),
                  Text('Fecha: ${DateTime.now().toString().split('.')[0]}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2ReasonForEncounter() {
    // Obtener el valor guardado (puede ser null o un valor no válido)
    final savedContactType = _compositionModel?.getField(
      'his_medica_itsur.historia_clinica_nom004.v1/reason_for_encounter/contact_type:0',
    );

    // Lista de valores válidos
    final validContactTypes = [
      'Primera vez',
      'Seguimiento',
      'Urgencia',
      'Consulta programada',
      'Control rutinario',
      'Consulta externa',
      'Telemedicina',
    ];

    // Validar que el valor guardado esté en la lista, si no, usar null
    final String? initialContactType =
        (savedContactType != null && validContactTypes.contains(savedContactType))
            ? savedContactType as String
            : null;

    final reasonController = TextEditingController(
      text: _compositionModel?.getField(
            'his_medica_itsur.historia_clinica_nom004.v1/reason_for_encounter/presenting_problem:0',
          ) ??
          '',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Motivo de Consulta',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Tipo de Consulta (Dropdown)
          DropdownButtonFormField<String>(
            initialValue: initialContactType,
            decoration: const InputDecoration(
              labelText: 'Tipo de Consulta',
              prefixIcon: Icon(Icons.medical_services),
              helperText: 'Selecciona el tipo de consulta',
            ),
            items: const [
              DropdownMenuItem(
                value: 'Primera vez',
                child: Text('Primera vez'),
              ),
              DropdownMenuItem(
                value: 'Seguimiento',
                child: Text('Seguimiento'),
              ),
              DropdownMenuItem(
                value: 'Urgencia',
                child: Text('Urgencia'),
              ),
              DropdownMenuItem(
                value: 'Consulta programada',
                child: Text('Consulta programada'),
              ),
              DropdownMenuItem(
                value: 'Control rutinario',
                child: Text('Control rutinario'),
              ),
              DropdownMenuItem(
                value: 'Consulta externa',
                child: Text('Consulta externa'),
              ),
              DropdownMenuItem(
                value: 'Telemedicina',
                child: Text('Telemedicina'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                _compositionModel?.updateField(
                  'his_medica_itsur.historia_clinica_nom004.v1/reason_for_encounter/contact_type:0',
                  value,
                );
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Selecciona el tipo de consulta';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Problema Presentado
          TextFormField(
            controller: reasonController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Problema Presentado',
              hintText: 'Ej: Dolor de cabeza intenso desde hace 3 días...',
              prefixIcon: Icon(Icons.description),
              alignLabelWithHint: true,
              helperText: 'Describe brevemente el motivo principal de la consulta',
            ),
            onChanged: (value) {
              _compositionModel?.updateField(
                'his_medica_itsur.historia_clinica_nom004.v1/reason_for_encounter/presenting_problem:0',
                value,
              );
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El problema presentado es requerido';
              }
              if (value.trim().length < 10) {
                return 'Describe con más detalle (mínimo 10 caracteres)';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Tarjeta informativa
          Card(
            color: Colors.blue[50],
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'El motivo de consulta debe ser claro y conciso para facilitar el diagnóstico.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Story() {
    final storyController = TextEditingController(
      text: _compositionModel?.getField(
            'his_medica_itsur.historia_clinica_nom004.v1/story_history/any_event:0/story:0',
          ) ??
          'Sin padecimiento actual reportado',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Padecimiento Actual',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Describe la evolución y características del problema de salud actual.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: storyController,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Historia del Padecimiento',
              hintText: 'Ej: Paciente refiere inicio hace 3 días con...',
              alignLabelWithHint: true,
            ),
            onChanged: (value) {
              _compositionModel?.updateField(
                'his_medica_itsur.historia_clinica_nom004.v1/story_history/any_event:0/story:0',
                value,
              );
            },
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.blue[50],
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.tips_and_updates, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Incluye: inicio, duración, evolución, síntomas asociados, tratamientos previos.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4FamilyHistory() {
    final summaryController = TextEditingController(
      text: _compositionModel?.getField(
            'his_medica_itsur.historia_clinica_nom004.v1/family_history:0/summary',
          ) ??
          'Sin antecedentes heredofamiliares relevantes',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Antecedentes Heredofamiliares',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enfermedades de familiares directos (padres, hermanos, abuelos).',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: summaryController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Resumen de Antecedentes Familiares',
              hintText: 'Ej: Padre diabético, madre hipertensa...',
              alignLabelWithHint: true,
            ),
            onChanged: (value) {
              _compositionModel?.updateField(
                'his_medica_itsur.historia_clinica_nom004.v1/family_history:0/summary',
                value,
              );
            },
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.orange[50],
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.family_restroom, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Incluye: diabetes, hipertensión, cáncer, enfermedades cardíacas, etc.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep5PersonalHistory() {
    final tobaccoController = TextEditingController(
      text: _compositionModel?.getField(
            'his_medica_itsur.historia_clinica_nom004.v1/smokeless_tobacco_summary:0/overall_description',
          ) ??
          'No fuma',
    );

    final alcoholController = TextEditingController(
      text: _compositionModel?.getField(
            'his_medica_itsur.historia_clinica_nom004.v1/alcohol_consumption_summary:0/overall_description',
          ) ??
          'No consume alcohol',
    );

    final housingController = TextEditingController(
      text: _compositionModel?.getField(
            'his_medica_itsur.historia_clinica_nom004.v1/housing_summary:0/description',
          ) ??
          'Casa propia, servicios básicos completos',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Antecedentes Personales No Patológicos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Tabaquismo
          TextFormField(
            controller: tobaccoController,
            decoration: const InputDecoration(
              labelText: 'Tabaquismo',
              hintText: 'Ej: Fuma 5 cigarros al día desde hace 10 años',
              prefixIcon: Icon(Icons.smoking_rooms),
            ),
            onChanged: (value) {
              _compositionModel?.updateField(
                'his_medica_itsur.historia_clinica_nom004.v1/smokeless_tobacco_summary:0/overall_description',
                value,
              );
            },
          ),
          const SizedBox(height: 16),

          // Alcoholismo
          TextFormField(
            controller: alcoholController,
            decoration: const InputDecoration(
              labelText: 'Alcoholismo',
              hintText: 'Ej: Consume ocasionalmente los fines de semana',
              prefixIcon: Icon(Icons.local_bar),
            ),
            onChanged: (value) {
              _compositionModel?.updateField(
                'his_medica_itsur.historia_clinica_nom004.v1/alcohol_consumption_summary:0/overall_description',
                value,
              );
            },
          ),
          const SizedBox(height: 16),

          // Vivienda
          TextFormField(
            controller: housingController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Vivienda',
              hintText: 'Ej: Casa propia, cuenta con agua potable, luz...',
              prefixIcon: Icon(Icons.home),
              alignLabelWithHint: true,
            ),
            onChanged: (value) {
              _compositionModel?.updateField(
                'his_medica_itsur.historia_clinica_nom004.v1/housing_summary:0/description',
                value,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep6GynecoObstetric() {
    // Verificar si el paciente es mujer
    if (!widget.patient.isFemale) {
      // Ocultar completamente si no es mujer (no mostrar tarjeta ni campos)
      return const SizedBox.shrink();
    }

    // Si es mujer, mostrar el formulario AGO
    final fumController = TextEditingController(
      text: _compositionModel?.getField(
            'his_medica_itsur.historia_clinica_nom004.v1/last_menstrual_period/date_of_onset_lmp',
          ) ??
          '',
    );

    final gravidityController = TextEditingController(
      text: _compositionModel
              ?.getField('his_medica_itsur.historia_clinica_nom004.v1/obstetric_summary/gravidity')
              ?.toString() ??
          '',
    );

    final parityController = TextEditingController(
      text: _compositionModel
              ?.getField('his_medica_itsur.historia_clinica_nom004.v1/obstetric_summary/parity')
              ?.toString() ??
          '',
    );

    final abortionsController = TextEditingController(
      text: _compositionModel
              ?.getField('his_medica_itsur.historia_clinica_nom004.v1/obstetric_summary/abortions')
              ?.toString() ??
          '',
    );

    final caesareanController = TextEditingController(
      text: _compositionModel
              ?.getField('his_medica_itsur.historia_clinica_nom004.v1/obstetric_summary/caesarean_sections')
              ?.toString() ??
          '',
    );

    final liveBirthsController = TextEditingController(
      text: _compositionModel
              ?.getField('his_medica_itsur.historia_clinica_nom004.v1/obstetric_summary/live_births')
              ?.toString() ??
          '',
    );

    final contraceptiveController = TextEditingController(
      text: _compositionModel?.getField(
            'his_medica_itsur.historia_clinica_nom004.v1/contraceptive_use_summary/overall_description',
          ) ??
          '',
    );

    final menstruationController = TextEditingController(
      text: _compositionModel?.getField(
            'his_medica_itsur.historia_clinica_nom004.v1/menstruation_summary/overall_description',
          ) ??
          '',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.female, color: Colors.pink, size: 28),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Antecedentes Gineco-Obstétricos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Información específica para pacientes de sexo femenino.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // FUM - Fecha de Última Menstruación
          TextFormField(
            controller: fumController,
            decoration: const InputDecoration(
              labelText: 'Fecha de Última Menstruación (FUM)',
              hintText: 'Ej: 2025-01-15',
              prefixIcon: Icon(Icons.calendar_today),
              helperText: 'Formato: YYYY-MM-DD',
            ),
            onChanged: (value) {
              _compositionModel?.updateField(
                'his_medica_itsur.historia_clinica_nom004.v1/last_menstrual_period/date_of_onset_lmp',
                value,
              );
            },
          ),
          const SizedBox(height: 16),

          // Patrón Menstrual
          TextFormField(
            controller: menstruationController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Patrón Menstrual',
              hintText: 'Ej: Regular, cada 28 días, duración 5 días',
              prefixIcon: Icon(Icons.history),
            ),
            onChanged: (value) {
              _compositionModel?.updateField(
                'his_medica_itsur.historia_clinica_nom004.v1/menstruation_summary/overall_description',
                value,
              );
            },
          ),
          const SizedBox(height: 24),

          const Divider(),
          const Text(
            'Antecedentes Obstétricos (GPAVC)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: gravidityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Gestas (G)',
                    hintText: '0',
                    helperText: 'Embarazos totales',
                  ),
                  onChanged: (value) {
                    final numValue = int.tryParse(value);
                    if (numValue != null) {
                      _compositionModel?.updateField(
                        'his_medica_itsur.historia_clinica_nom004.v1/obstetric_summary/gravidity',
                        numValue,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: parityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Partos (P)',
                    hintText: '0',
                    helperText: 'Partos totales',
                  ),
                  onChanged: (value) {
                    final numValue = int.tryParse(value);
                    if (numValue != null) {
                      _compositionModel?.updateField(
                        'his_medica_itsur.historia_clinica_nom004.v1/obstetric_summary/parity',
                        numValue,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: abortionsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Abortos (A)',
                    hintText: '0',
                  ),
                  onChanged: (value) {
                    final numValue = int.tryParse(value);
                    if (numValue != null) {
                      _compositionModel?.updateField(
                        'his_medica_itsur.historia_clinica_nom004.v1/obstetric_summary/abortions',
                        numValue,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: caesareanController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cesáreas (C)',
                    hintText: '0',
                  ),
                  onChanged: (value) {
                    final numValue = int.tryParse(value);
                    if (numValue != null) {
                      _compositionModel?.updateField(
                        'his_medica_itsur.historia_clinica_nom004.v1/obstetric_summary/caesarean_sections',
                        numValue,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Hijos Vivos
          TextFormField(
            controller: liveBirthsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Hijos Vivos (V)',
              hintText: '0',
              prefixIcon: Icon(Icons.child_care),
            ),
            onChanged: (value) {
              final numValue = int.tryParse(value);
              if (numValue != null) {
                _compositionModel?.updateField(
                  'his_medica_itsur.historia_clinica_nom004.v1/obstetric_summary/live_births',
                  numValue,
                );
              }
            },
          ),
          const SizedBox(height: 24),

          const Divider(),

          // Método Anticonceptivo
          TextFormField(
            controller: contraceptiveController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Método Anticonceptivo',
              hintText: 'Ej: DIU, Píldoras, Inyección, Ninguno...',
              prefixIcon: Icon(Icons.medical_information),
              alignLabelWithHint: true,
            ),
            onChanged: (value) {
              _compositionModel?.updateField(
                'his_medica_itsur.historia_clinica_nom004.v1/contraceptive_use_summary/overall_description',
                value,
              );
            },
          ),
          const SizedBox(height: 16),

          Card(
            color: Colors.pink[50],
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.pink),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'GPAVC: Gestas, Partos, Abortos, Vivos, Cesáreas',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep7VitalSigns() {
    final systolicController = TextEditingController(
      text: _compositionModel?.getField(
            'his_medica_itsur.historia_clinica_nom004.v1/blood_pressure/any_event:0/systolic|magnitude',
          )?.toString() ??
          '120',
    );

    final diastolicController = TextEditingController(
      text: _compositionModel?.getField(
            'his_medica_itsur.historia_clinica_nom004.v1/blood_pressure/any_event:0/diastolic|magnitude',
          )?.toString() ??
          '80',
    );

    final heartRateController = TextEditingController(
      text: _compositionModel?.getField(
            'his_medica_itsur.historia_clinica_nom004.v1/pulse_heart_beat/any_event:0/rate|magnitude',
          )?.toString() ??
          '75',
    );

    final respRateController = TextEditingController(
      text: _compositionModel?.getField(
            'his_medica_itsur.historia_clinica_nom004.v1/respiration/any_event:0/rate|magnitude',
          )?.toString() ??
          '18',
    );

    final tempController = TextEditingController(
      text: _compositionModel?.getField(
            'his_medica_itsur.historia_clinica_nom004.v1/body_temperature/any_event:0/temperature|magnitude',
          )?.toString() ??
          '36.5',
    );

    final weightController = TextEditingController(
      text: _compositionModel?.getField(
            'his_medica_itsur.historia_clinica_nom004.v1/body_weight/any_event:0/weight|magnitude',
          )?.toString() ??
          '70',
    );

    final heightController = TextEditingController(
      text: _compositionModel?.getField(
            'his_medica_itsur.historia_clinica_nom004.v1/height_length/any_event:0/height_length|magnitude',
          )?.toString() ??
          '170',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Signos Vitales',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Presión Arterial
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: systolicController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sistólica',
                    suffixText: 'mmHg',
                    prefixIcon: Icon(Icons.favorite),
                  ),
                  onChanged: (value) {
                    final numValue = double.tryParse(value);
                    if (numValue != null) {
                      _compositionModel?.updateField(
                        'his_medica_itsur.historia_clinica_nom004.v1/blood_pressure/any_event:0/systolic|magnitude',
                        numValue,
                      );
                      _compositionModel?.updateField(
                        'his_medica_itsur.historia_clinica_nom004.v1/blood_pressure/any_event:0/systolic|unit',
                        'mm[Hg]',
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: diastolicController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Diastólica',
                    suffixText: 'mmHg',
                  ),
                  onChanged: (value) {
                    final numValue = double.tryParse(value);
                    if (numValue != null) {
                      _compositionModel?.updateField(
                        'his_medica_itsur.historia_clinica_nom004.v1/blood_pressure/any_event:0/diastolic|magnitude',
                        numValue,
                      );
                      _compositionModel?.updateField(
                        'his_medica_itsur.historia_clinica_nom004.v1/blood_pressure/any_event:0/diastolic|unit',
                        'mm[Hg]',
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Frecuencia Cardíaca
          TextFormField(
            controller: heartRateController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Frecuencia Cardíaca',
              suffixText: 'lpm',
              prefixIcon: Icon(Icons.monitor_heart),
            ),
            onChanged: (value) {
              final numValue = double.tryParse(value);
              if (numValue != null) {
                _compositionModel?.updateField(
                  'his_medica_itsur.historia_clinica_nom004.v1/pulse_heart_beat/any_event:0/rate|magnitude',
                  numValue,
                );
                _compositionModel?.updateField(
                  'his_medica_itsur.historia_clinica_nom004.v1/pulse_heart_beat/any_event:0/rate|unit',
                  '/min',
                );
              }
            },
          ),
          const SizedBox(height: 16),

          // Frecuencia Respiratoria
          TextFormField(
            controller: respRateController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Frecuencia Respiratoria',
              suffixText: 'rpm',
              prefixIcon: Icon(Icons.air),
            ),
            onChanged: (value) {
              final numValue = double.tryParse(value);
              if (numValue != null) {
                _compositionModel?.updateField(
                  'his_medica_itsur.historia_clinica_nom004.v1/respiration/any_event:0/rate|magnitude',
                  numValue,
                );
                _compositionModel?.updateField(
                  'his_medica_itsur.historia_clinica_nom004.v1/respiration/any_event:0/rate|unit',
                  '/min',
                );
              }
            },
          ),
          const SizedBox(height: 16),

          // Temperatura
          TextFormField(
            controller: tempController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Temperatura',
              suffixText: '°C',
              prefixIcon: Icon(Icons.thermostat),
            ),
            onChanged: (value) {
              final numValue = double.tryParse(value);
              if (numValue != null) {
                _compositionModel?.updateField(
                  'his_medica_itsur.historia_clinica_nom004.v1/body_temperature/any_event:0/temperature|magnitude',
                  numValue,
                );
                _compositionModel?.updateField(
                  'his_medica_itsur.historia_clinica_nom004.v1/body_temperature/any_event:0/temperature|unit',
                  '°C',
                );
              }
            },
          ),
          const SizedBox(height: 16),

          // Peso
          TextFormField(
            controller: weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Peso',
              suffixText: 'kg',
              prefixIcon: Icon(Icons.monitor_weight),
            ),
            onChanged: (value) {
              final numValue = double.tryParse(value);
              if (numValue != null) {
                _compositionModel?.updateField(
                  'his_medica_itsur.historia_clinica_nom004.v1/body_weight/any_event:0/weight|magnitude',
                  numValue,
                );
                _compositionModel?.updateField(
                  'his_medica_itsur.historia_clinica_nom004.v1/body_weight/any_event:0/weight|unit',
                  'kg',
                );
              }
            },
          ),
          const SizedBox(height: 16),

          // Talla
          TextFormField(
            controller: heightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Talla',
              suffixText: 'cm',
              prefixIcon: Icon(Icons.height),
            ),
            onChanged: (value) {
              final numValue = double.tryParse(value);
              if (numValue != null) {
                _compositionModel?.updateField(
                  'his_medica_itsur.historia_clinica_nom004.v1/height_length/any_event:0/height_length|magnitude',
                  numValue,
                );
                _compositionModel?.updateField(
                  'his_medica_itsur.historia_clinica_nom004.v1/height_length/any_event:0/height_length|unit',
                  'cm',
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep8PhysicalExam() {
    final physicalExamController = TextEditingController(
      text: _compositionModel?.getField(
            'his_medica_itsur.historia_clinica_nom004.v1/physical_examination_findings:0/description:0',
          ) ??
          'Paciente consciente, orientado, bien hidratado, normocéfalo.',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Exploración Física',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hallazgos de la exploración física del paciente.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: physicalExamController,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: 'Descripción de la Exploración',
              hintText: 'Ej: Cabeza y cuello: sin alteraciones\nTórax: murmullo vesicular presente...',
              alignLabelWithHint: true,
            ),
            onChanged: (value) {
              _compositionModel?.updateField(
                'his_medica_itsur.historia_clinica_nom004.v1/physical_examination_findings:0/description:0',
                value,
              );
            },
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.green[50],
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.medical_services, color: Colors.green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Incluye: inspección, palpación, percusión y auscultación por sistemas.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep9Diagnosis() {
    final diagnosisController = TextEditingController(
      text: _compositionModel?.getField(
            'his_medica_itsur.historia_clinica_nom004.v1/problem_diagnosis:0/problem_diagnosis_name',
          ) ??
          'Pendiente de diagnóstico',
    );

    final clinicalDescController = TextEditingController(
      text: _compositionModel?.getField(
            'his_medica_itsur.historia_clinica_nom004.v1/problem_diagnosis:0/clinical_description',
          ) ??
          'En observación',
    );

    final medicationController = TextEditingController(
      text: _compositionModel?.getField(
            'his_medica_itsur.historia_clinica_nom004.v1/medication_statement:0/medication_item',
          ) ??
          'Sin medicación prescrita',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Diagnóstico y Plan de Tratamiento',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Diagnóstico
          TextFormField(
            controller: diagnosisController,
            decoration: const InputDecoration(
              labelText: 'Diagnóstico Principal',
              hintText: 'Ej: Hipertensión arterial sistémica',
              prefixIcon: Icon(Icons.medical_information),
            ),
            onChanged: (value) {
              _compositionModel?.updateField(
                'his_medica_itsur.historia_clinica_nom004.v1/problem_diagnosis:0/problem_diagnosis_name',
                value,
              );
            },
          ),
          const SizedBox(height: 16),

          // Descripción Clínica
          TextFormField(
            controller: clinicalDescController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Descripción Clínica',
              hintText: 'Detalles del diagnóstico...',
              alignLabelWithHint: true,
            ),
            onChanged: (value) {
              _compositionModel?.updateField(
                'his_medica_itsur.historia_clinica_nom004.v1/problem_diagnosis:0/clinical_description',
                value,
              );
            },
          ),
          const SizedBox(height: 16),

          // Medicación
          TextFormField(
            controller: medicationController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Medicación Prescrita',
              hintText: 'Ej: Losartán 50mg c/24hrs\nMetformina 850mg c/12hrs',
              prefixIcon: Icon(Icons.medication),
              alignLabelWithHint: true,
            ),
            onChanged: (value) {
              _compositionModel?.updateField(
                'his_medica_itsur.historia_clinica_nom004.v1/medication_statement:0/medication_item',
                value,
              );
            },
          ),
          const SizedBox(height: 24),

          // Resumen final
          Card(
            color: Colors.purple[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.purple[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Expediente Clínico Completo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  const Text(
                    'Revisa todos los datos y presiona "Guardar" en la parte superior para crear el expediente clínico en EHRbase.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousStep,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Anterior'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _currentStep < _totalSteps - 1 ? _nextStep : null,
              icon: const Icon(Icons.arrow_forward),
              label: Text(
                _currentStep < _totalSteps - 1 ? 'Siguiente' : 'Finalizado',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveComposition() async {
    if (_compositionModel == null) return;

    // Actualizar nombre del compositor
    _compositionModel!.updateField(
      'his_medica_itsur.historia_clinica_nom004.v1/composer|name',
      _composerNameController.text,
    );

    setState(() => _isSaving = true);

    try {
      // Obtener el JSON de la composición
      Map<String, dynamic> json = _compositionModel!.toJson();

      // Si el paciente NO es mujer, eliminamos cualquier clave/objeto AGO
      final bool isFemale = widget.patient.isFemale;
      if (!isFemale) {
        final before = _findAgoKeys(json);
        if (before.isNotEmpty) {
          debugPrint('DEBUG: claves AGO encontradas antes de limpiar: $before');
        }

        json = _removeAgoKeysRecursively(json);

        final after = _findAgoKeys(json);
        if (after.isNotEmpty) {
          debugPrint('DEBUG: AUN QUEDAN claves AGO después de limpiar: $after');
        } else {
          debugPrint('DEBUG: Se eliminaron las claves AGO correctamente.');
        }
      }

      await _ehrService.createComposition(
        widget.patient.ehrId,
        json,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro Clínico guardado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // Retornar true para recargar la lista
    } catch (e) {
      setState(() => _isSaving = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
import 'package:flutter/material.dart';
import '../services/ehr_service.dart';
import '../services/patient_storage.dart';
import '../models/patient_model.dart';
import 'composition_list.dart';

class PatientManager extends StatefulWidget {
  const PatientManager({super.key});

  @override
  State<PatientManager> createState() => _PatientManagerState();
}

class _PatientManagerState extends State<PatientManager> {
  final _ehrService = EhrService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  List<Patient> _patients = [];
  bool _isLoading = false;
  bool _isLoadingList = true;

  String? _selectedSex;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Cargar pacientes desde SharedPreferences
  Future<void> _loadPatients() async {
    setState(() => _isLoadingList = true);
    
    final patients = await PatientStorage.loadPatients();
    
    setState(() {
      _patients = patients;
      _isLoadingList = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Pacientes'),
        actions: [
          // Botón para limpiar todos los pacientes (útil para testing)
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearAllPatients,
            tooltip: 'Limpiar todos',
          ),
        ],
      ),
      body: Column(
        children: [
          // Formulario para crear nuevo paciente
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Registrar Nuevo Paciente',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    // Dentro del Card del formulario, después del TextFormField del nombre:
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre Completo del Paciente',
                        hintText: 'Ej: Juan Pérez García',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es requerido';
                        }
                        if (value.trim().length < 3) {
                          return 'El nombre debe tener al menos 3 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ← NUEVO: Selector de sexo
                    DropdownButtonFormField<String>(
                      value: _selectedSex,
                      decoration: const InputDecoration(
                        labelText: 'Sexo',
                        prefixIcon: Icon(Icons.wc),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'M',
                          child: Row(
                            children: [
                              Icon(Icons.male, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Masculino'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'F',
                          child: Row(
                            children: [
                              Icon(Icons.female, color: Colors.pink),
                              SizedBox(width: 8),
                              Text('Femenino'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedSex = value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Selecciona el sexo del paciente';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _createPatient,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.person_add),
                      label: Text(
                        _isLoading ? 'Creando...' : 'Crear Paciente',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Contador de pacientes
          if (_patients.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.people, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${_patients.length} paciente(s) registrado(s)',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 8),
          
          // Lista de pacientes
          Expanded(
            child: _isLoadingList
                ? const Center(child: CircularProgressIndicator())
                : _patients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay pacientes registrados',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Crea uno nuevo usando el formulario',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPatients,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _patients.length,
                          itemBuilder: (context, index) {
                            final patient = _patients[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  child: Text(
                                    patient.name[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  patient.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                // En el ListTile de cada paciente, actualiza el subtitle:
                                subtitle: Text(
                                  'Sexo: ${patient.isFemale ? "Femenino ♀" : patient.isMale ? "Masculino ♂" : "No especificado"}\n'
                                  'EHR ID: ${patient.ehrId}\n'
                                  'Creado: ${_formatDate(patient.createdAt)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                isThreeLine: true,
                                trailing: PopupMenuButton(
                                  icon: const Icon(Icons.more_vert),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'open',
                                      child: Row(
                                        children: [
                                          Icon(Icons.folder_open),
                                          SizedBox(width: 8),
                                          Text('Abrir'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'open') {
                                      _openPatientCompositions(patient);
                                    } else if (value == 'delete') {
                                      _deletePatient(patient);
                                    }
                                  },
                                ),
                                onTap: () => _openPatientCompositions(patient),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _createPatient() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    final patient = await _ehrService.createEhr(_nameController.text.trim());
    
    // Crear paciente con el sexo seleccionado
    final patientWithSex = Patient(
      ehrId: patient.ehrId,
      name: patient.name,
      createdAt: patient.createdAt,
      sex: _selectedSex, // ← NUEVO
    );
    
    // Guardar en SharedPreferences
    await PatientStorage.addPatient(patientWithSex);
    
    // Recargar la lista
    await _loadPatients();
    
    _nameController.clear();
    _selectedSex = null; // ← NUEVO: Limpiar selector
    setState(() => _isLoading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Paciente ${patientWithSex.name} creado exitosamente'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    setState(() => _isLoading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al crear paciente: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

  void _openPatientCompositions(Patient patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompositionList(patient: patient),
      ),
    );
  }

  Future<void> _deletePatient(Patient patient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Paciente'),
        content: Text(
          '¿Estás seguro de eliminar a ${patient.name}?\n\n'
          'Solo se eliminará de la app, el EHR seguirá en EHRbase.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await PatientStorage.removePatient(patient.ehrId);
      await _loadPatients();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${patient.name} eliminado de la app'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _clearAllPatients() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar Todos los Pacientes'),
        content: const Text(
          '¿Estás seguro de eliminar TODOS los pacientes de la app?\n\n'
          'Los EHRs seguirán en EHRbase.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Limpiar Todo'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await PatientStorage.clearAll();
      await _loadPatients();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos los pacientes eliminados de la app'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
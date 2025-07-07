import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../data/services/absence_service.dart';
import '../../core/constants/app_constants.dart';

/// **Diálogo para Nueva Ausencia**
///
/// Molécula que proporciona un diálogo modal para crear una nueva ausencia.
/// Incluye campos para seleccionar el tipo, fecha y motivo de la ausencia.
///
/// [absenceTypes] - Lista de tipos de ausencia disponibles
/// [onAbsenceCreated] - Callback que se ejecuta cuando se crea una ausencia
class NewAbsenceDialog extends StatefulWidget {
  /// Lista de tipos de ausencia disponibles con sus propiedades
  final List<Map<String, dynamic>> absenceTypes;

  /// Callback que se ejecuta cuando se completa la creación de una ausencia
  final Function(Map<String, dynamic>, File?) onAbsenceCreated;

  const NewAbsenceDialog({
    super.key,
    required this.absenceTypes,
    required this.onAbsenceCreated,
  });

  @override
  State<NewAbsenceDialog> createState() => _NewAbsenceDialogState();
}

class _NewAbsenceDialogState extends State<NewAbsenceDialog> {
  /// Controlador para el campo de texto del motivo
  final _reasonController = TextEditingController();

  /// Tipo de ausencia seleccionado actualmente
  String? _selectedType;

  /// Fecha seleccionada para la ausencia
  DateTime? _selectedDate;

  /// Fecha de inicio para rangos (vacaciones)
  DateTime? _startDate;

  /// Fecha de fin para rangos (vacaciones)
  DateTime? _endDate;

  /// Indica si se está procesando la creación de la ausencia
  bool _isCreating = false;

  /// Archivo de documento seleccionado (para tipos que requieren documento)
  File? _selectedDocument;

  /// Indica si se está subiendo el documento
  bool _isUploadingDocument = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva Ausencia'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeSelector(),
            const SizedBox(height: 16),
            _buildDateSelector(),
            const SizedBox(height: 16),
            _buildReasonField(),
            if (_selectedType != null &&
                AbsenceService.requiresDocument(_selectedType!)) ...[
              const SizedBox(height: 16),
              _buildDocumentSelector(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createAbsence,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFe67d21),
          ),
          child: _isCreating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Crear', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  /// Construye el selector de tipo de ausencia
  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de ausencia:',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFe67d21)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          hint: const Text('Selecciona el tipo'),
          items: widget.absenceTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type['type'],
              child: Row(
                children: [
                  Icon(type['icon'], size: 16, color: type['color']),
                  const SizedBox(width: 8),
                  Text(type['label']),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedType = value;
              // Limpiar fechas al cambiar tipo
              _selectedDate = null;
              _startDate = null;
              _endDate = null;
            });
          },
        ),
      ],
    );
  }

  /// Construye el selector de fecha
  Widget _buildDateSelector() {
    bool isVacation = _selectedType == 'vacation';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isVacation ? 'Período de vacaciones:' : 'Fecha:',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (isVacation) ...[
          // Selector de rango para vacaciones
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(isStart: true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Color(0xFFe67d21),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _startDate != null
                                ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                : 'Fecha inicio',
                            style: TextStyle(
                              color: _startDate != null
                                  ? Colors.black
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(isStart: false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Color(0xFFe67d21),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _endDate != null
                                ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                : 'Fecha fin',
                            style: TextStyle(
                              color: _endDate != null
                                  ? Colors.black
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          // Selector de fecha única para otros tipos
          InkWell(
            onTap: () => _selectDate(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Color(0xFFe67d21),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'Selecciona la fecha',
                    style: TextStyle(
                      color: _selectedDate != null
                          ? Colors.black
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Construye el campo de texto para el motivo
  Widget _buildReasonField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Motivo:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Describe el motivo de la ausencia',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFe67d21)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ),
      ],
    );
  }

  /// Construye el selector de documento
  Widget _buildDocumentSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Documento de respaldo:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _selectedDocument == null
              ? InkWell(
                  onTap: _isUploadingDocument ? null : _selectDocument,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Toca para seleccionar documento',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PDF, JPG, PNG - Máx. 5MB',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.description,
                          color: Colors.green,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedDocument!.path.split('/').last,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${(_selectedDocument!.lengthSync() / 1024 / 1024).toStringAsFixed(1)} MB',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedDocument = null;
                          });
                        },
                        icon: const Icon(Icons.close, color: Colors.grey),
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  /// Abre el selector de fecha
  Future<void> _selectDate({bool? isStart}) async {
    bool isVacation = _selectedType == 'vacation';

    DateTime? initialDate;
    DateTime? firstDate;
    DateTime? lastDate;

    if (isVacation && isStart != null) {
      // Para vacaciones con rango
      if (isStart) {
        initialDate = _startDate ?? DateTime.now();
        firstDate = DateTime.now();
        lastDate = DateTime.now().add(const Duration(days: 365));
      } else {
        initialDate =
            _endDate ??
            (_startDate?.add(const Duration(days: 1)) ?? DateTime.now());
        firstDate = _startDate ?? DateTime.now();
        lastDate = DateTime.now().add(const Duration(days: 365));
      }
    } else {
      // Para fecha única
      initialDate = _selectedDate ?? DateTime.now();
      firstDate = DateTime.now().subtract(const Duration(days: 30));
      lastDate = DateTime.now().add(const Duration(days: 365));
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: const Color(0xFFe67d21)),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        if (isVacation && isStart != null) {
          if (isStart) {
            _startDate = date;
            // Si la fecha de fin es anterior a la de inicio, resetearla
            if (_endDate != null && _endDate!.isBefore(date)) {
              _endDate = null;
            }
          } else {
            _endDate = date;
          }
        } else {
          _selectedDate = date;
        }
      });
    }
  }

  /// Seleccionar documento desde el dispositivo
  Future<void> _selectDocument() async {
    try {
      setState(() {
        _isUploadingDocument = true;
      });

      final ImagePicker picker = ImagePicker();

      // Mostrar opciones para seleccionar desde cámara o galería
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Seleccionar documento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Desde galería'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar foto'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source != null) {
        final XFile? pickedFile = await picker.pickImage(
          source: source,
          imageQuality: 85,
        );

        if (pickedFile != null) {
          final file = File(pickedFile.path);

          // Validar el archivo
          try {
            // Validar tamaño
            final fileSize = await file.length();
            if (fileSize > AppConfig.maxDocumentSize) {
              throw Exception(
                'El archivo es muy grande. Máximo 5MB permitido.',
              );
            }

            // Validar extensión
            final extension = pickedFile.path.split('.').last.toLowerCase();
            if (!AppConfig.validDocumentExtensions.contains(extension) &&
                !['jpg', 'jpeg', 'png'].contains(extension)) {
              throw Exception(
                'Formato no válido. Solo PDF, JPG y PNG permitidos.',
              );
            }

            setState(() {
              _selectedDocument = file;
            });
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString()),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar documento: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingDocument = false;
        });
      }
    }
  }

  /// Crea la nueva ausencia con los datos ingresados
  Future<void> _createAbsence() async {
    bool isVacation = _selectedType == 'vacation';

    // Validar que todos los campos estén completos
    if (_selectedType == null || _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar documento si es requerido
    if (AbsenceService.requiresDocument(_selectedType!) &&
        _selectedDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Este tipo de ausencia requiere un documento de respaldo',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar fechas según el tipo
    if (isVacation) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona el período de vacaciones'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_endDate!.isBefore(_startDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La fecha de fin debe ser posterior a la fecha de inicio',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona la fecha'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isCreating = true;
    });

    try {
      if (isVacation && _startDate != null && _endDate != null) {
        // Para vacaciones, crear múltiples ausencias (una por día)
        List<DateTime> dates = [];
        DateTime currentDate = _startDate!;

        while (currentDate.isBefore(_endDate!) ||
            currentDate.isAtSameMomentAs(_endDate!)) {
          // Solo agregar días laborables (lunes a viernes)
          if (currentDate.weekday >= 1 && currentDate.weekday <= 5) {
            dates.add(currentDate);
          }
          currentDate = currentDate.add(const Duration(days: 1));
        }

        // Crear ausencias para cada día
        for (DateTime date in dates) {
          final absenceData = {
            'type': _selectedType!,
            'date':
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
            'reason': _reasonController.text.trim(),
          };
          await widget.onAbsenceCreated(absenceData, _selectedDocument);
        }
      } else {
        // Para otros tipos, crear una sola ausencia
        final absenceData = {
          'type': _selectedType!,
          'date':
              '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
          'reason': _reasonController.text.trim(),
        };
        await widget.onAbsenceCreated(absenceData, _selectedDocument);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // El error ya se maneja en el widget padre
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/providers/auth_provider.dart';
import '../../data/providers/todo_provider.dart';
import '../../data/models/todo_model.dart';

/// Página temporal de demo para TODOs
/// Reemplaza temporalmente el home para la demostración del cliente
class DemoTodoPage extends StatefulWidget {
  final String token;

  const DemoTodoPage({super.key, required this.token});

  @override
  State<DemoTodoPage> createState() => _DemoTodoPageState();
}

class _DemoTodoPageState extends State<DemoTodoPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _editTitleController = TextEditingController();
  final _editDescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cargar TODOs al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TodoProvider>().loadTodos();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _editTitleController.dispose();
    _editDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Demo Tareas App',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    const Text('Perfil'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red[400]),
                    const SizedBox(width: 12),
                    Text('Cerrar Sesión', style: TextStyle(color: Colors.red[400])),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<TodoProvider>(
        builder: (context, todoProvider, child) {
          if (todoProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Column(
            children: [
              // Header con información de acciones
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestión de Tareas',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Funcionalidades disponibles:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildFeatureChip('Login/Register', Icons.account_circle),
                        _buildFeatureChip('Crear Tarea', Icons.add),
                        _buildFeatureChip('Descripción manual', Icons.edit_note),
                        _buildFeatureChip('Descripción automática', Icons.auto_awesome),
                        _buildFeatureChip('Editar Tarea', Icons.edit),
                        _buildFeatureChip('Eliminar Tarea', Icons.delete),
                      ],
                    ),
                  ],
                ),
              ),

              // Botón para crear nuevo Tarea
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateTodoDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Crear Nueva Tarea'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              // Lista de TODOs
              Expanded(
                child: todoProvider.todos.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: todoProvider.todos.length,
                        itemBuilder: (context, index) {
                          final todo = todoProvider.todos[index];
                          return _buildTodoCard(todo, todoProvider);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.blue[600]),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: Colors.blue[50],
      side: BorderSide(color: Colors.blue[200]!),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay Tareas aún',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primer Tarea para comenzar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoCard(Todo todo, TodoProvider todoProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: todo.isCompleted,
                  onChanged: (_) => todoProvider.toggleTodoComplete(todo.id),
                  activeColor: Colors.green[600],
                ),
                Expanded(
                  child: Text(
                    todo.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: todo.isCompleted 
                          ? TextDecoration.lineThrough 
                          : TextDecoration.none,
                      color: todo.isCompleted 
                          ? Colors.grey[500] 
                          : Colors.grey[800],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditTodoDialog(todo);
                    } else if (value == 'delete') {
                      _showDeleteConfirmDialog(todo, todoProvider);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isAutoGeneratedDescription(todo.description) 
                            ? Icons.auto_awesome 
                            : Icons.edit_note, 
                        size: 16, 
                        color: _isAutoGeneratedDescription(todo.description) 
                            ? Colors.purple[600] 
                            : Colors.green[600]
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isAutoGeneratedDescription(todo.description) 
                            ? 'Descripción generada automáticamente:'
                            : 'Descripción personalizada:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isAutoGeneratedDescription(todo.description) 
                              ? Colors.purple[600] 
                              : Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    todo.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Creado: ${_formatDateTime(todo.createdAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  bool _isAutoGeneratedDescription(String description) {
    // Lista de frases que aparecen en el Lorem Ipsum generado automáticamente
    final loremPhrases = [
      'Lorem ipsum dolor sit amet',
      'consectetur adipiscing elit',
      'Duis aute irure dolor',
      'Sed ut perspiciatis unde',
      'At vero eos et accusamus',
      'Temporibus autem quibusdam'
    ];
    
    return loremPhrases.any((phrase) => description.contains(phrase));
  }

  void _showCreateTodoDialog() {
    _titleController.clear();
    _descriptionController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Nueva Tarea'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título de la Tarea*',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  border: OutlineInputBorder(),
                  hintText: 'Deja vacío para generar automáticamente',
                ),
                maxLines: 3,
                minLines: 2,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Opciones de descripción:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Escribe tu propia descripción arriba\n• O deja vacío y al tocar "GENERAR" se creará automáticamente con Lorem Ipsum',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (_titleController.text.trim().isNotEmpty) {
                final customDescription = _descriptionController.text.trim().isEmpty 
                    ? null 
                    : _descriptionController.text.trim();
                
                context.read<TodoProvider>().addTodo(
                  _titleController.text.trim(),
                  customDescription: customDescription,
                );
                Navigator.pop(context);
                
                final message = customDescription != null 
                    ? 'Tarea creada con tu descripción personalizada'
                    : 'Tarea creada con descripción automática';
                    
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('CREAR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditTodoDialog(Todo todo) {
    _editTitleController.text = todo.title;
    _editDescriptionController.text = todo.description;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Tarea'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _editTitleController,
                decoration: const InputDecoration(
                  labelText: 'Título de la Tarea *',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _editDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                  hintText: 'Edita la descripción o deja vacío para generar nueva',
                ),
                maxLines: 4,
                minLines: 3,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit, color: Colors.orange[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Opciones de edición:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Modifica la descripción actual arriba\n• O borra todo y se generará una nueva automáticamente',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (_editTitleController.text.trim().isNotEmpty) {
                final customDescription = _editDescriptionController.text.trim().isEmpty 
                    ? null 
                    : _editDescriptionController.text.trim();
                
                context.read<TodoProvider>().editTodo(
                  todo.id, 
                  _editTitleController.text.trim(),
                  customDescription: customDescription,
                );
                Navigator.pop(context);
                
                final message = customDescription != null 
                    ? 'Tarea editada con tu descripción'
                    : 'Tarea editada con nueva descripción automática';
                    
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: Colors.blue,
                  ),
                );
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('GUARDAR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(Todo todo, TodoProvider todoProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Tarea'),
        content: Text('¿Estás seguro de que quieres eliminar "${todo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              todoProvider.deleteTodo(todo.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tarea eliminada'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('CERRAR SESIÓN'),
          ),
        ],
      ),
    );
  }
}

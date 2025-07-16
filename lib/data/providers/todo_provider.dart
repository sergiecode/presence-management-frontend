import 'package:flutter/foundation.dart';
import '../models/todo_model.dart';

/// Provider para gestionar el estado de los TODOs
class TodoProvider extends ChangeNotifier {
  final List<Todo> _todos = [];
  bool _isLoading = false;

  List<Todo> get todos => List.unmodifiable(_todos);
  bool get isLoading => _isLoading;

  /// Agregar un nuevo TODO
  void addTodo(String title, {String? customDescription}) {
    final todo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: customDescription ?? _generateLoremIpsum(),
      createdAt: DateTime.now(),
    );
    
    _todos.insert(0, todo);
    notifyListeners();
  }

  /// Generar descripción automática con Lorem Ipsum
  String _generateLoremIpsum() {
    final loremTexts = [
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.",
      "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim.",
      "Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae.",
      "At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident.",
      "Temporibus autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusandae. Itaque earum rerum hic tenetur a sapiente.",
    ];
    
    loremTexts.shuffle();
    return loremTexts.first;
  }

  /// Editar un TODO existente
  void editTodo(String id, String newTitle, {String? customDescription}) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      _todos[index] = _todos[index].copyWith(
        title: newTitle,
        description: customDescription ?? _generateLoremIpsum(), // Usa descripción personalizada o genera nueva
      );
      notifyListeners();
    }
  }

  /// Eliminar un TODO
  void deleteTodo(String id) {
    _todos.removeWhere((todo) => todo.id == id);
    notifyListeners();
  }

  /// Marcar/desmarcar TODO como completado
  void toggleTodoComplete(String id) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      _todos[index] = _todos[index].copyWith(
        isCompleted: !_todos[index].isCompleted,
      );
      notifyListeners();
    }
  }

  /// Simular carga de datos
  Future<void> loadTodos() async {
    _isLoading = true;
    notifyListeners();

    // Simular delay de carga
    await Future.delayed(const Duration(milliseconds: 500));

    // Agregar algunos TODOs de ejemplo si está vacío
    if (_todos.isEmpty) {
      _todos.addAll([
        Todo(
          id: '1',
          title: 'Ejemplo de TODO',
          description: _generateLoremIpsum(),
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        Todo(
          id: '2',
          title: 'Revisar documentación',
          description: _generateLoremIpsum(),
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
          isCompleted: true,
        ),
      ]);
    }

    _isLoading = false;
    notifyListeners();
  }
}

/// **ÁTOMO: Debug Panel**
///
/// Panel de debug reutilizable que muestra logs en tiempo real
/// para ayudar en el diagnóstico de problemas durante testing.
///
/// Autor: Equipo ABSTI
/// Fecha: 2025
library;

import 'package:flutter/material.dart';
import '../../core/utils/debug_logger.dart';

/// Panel de debug que muestra logs en tiempo real
class DebugPanel extends StatefulWidget {
  /// Título del panel
  final String title;
  
  /// Altura del panel
  final double height;
  
  /// Ancho del panel (null para ancho completo)
  final double? width;
  
  /// Si mostrar controles adicionales
  final bool showControls;
  
  /// Callback cuando se cierra el panel
  final VoidCallback? onClose;
  
  /// Si el panel está expandido por defecto
  final bool initiallyExpanded;

  const DebugPanel({
    super.key,
    this.title = '🔧 DEBUG LOGS',
    this.height = 200,
    this.width,
    this.showControls = true,
    this.onClose,
    this.initiallyExpanded = false,
  });

  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<DebugPanel> {
  bool _isExpanded = false;
  final ScrollController _scrollController = ScrollController();
  final DebugLogger _logger = DebugLogger();

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _logger.addListener(_onLogsChanged);
  }

  @override
  void dispose() {
    _logger.removeListener(_onLogsChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onLogsChanged() {
    if (mounted) {
      setState(() {});
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isExpanded ? widget.height : 60,
      width: widget.width,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header del panel
          _buildHeader(),
          
          // Contenido del panel (solo si está expandido)
          if (_isExpanded) ...[
            const SizedBox(height: 8),
            _buildContent(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Título
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          
          // Contador de logs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_logger.logs.length}',
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Botón expandir/contraer
          IconButton(
            icon: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.orange,
            ),
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
              if (_isExpanded) {
                _scrollToBottom();
              }
            },
            tooltip: _isExpanded ? 'Contraer' : 'Expandir',
          ),
          
          // Botón cerrar (si está habilitado)
          if (widget.onClose != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.orange),
              onPressed: widget.onClose,
              tooltip: 'Cerrar',
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: Column(
          children: [
            // Controles del panel
            if (widget.showControls) _buildControls(),
            
            // Lista de logs
            Expanded(
              child: _buildLogsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          // Filtro por nivel
          Expanded(
            child: _buildLevelFilter(),
          ),
          
          const SizedBox(width: 8),
          
          // Botón limpiar
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.white, size: 20),
            onPressed: () {
              _logger.clear();
            },
            tooltip: 'Limpiar logs',
          ),
          
          // Botón copiar
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white, size: 20),
            onPressed: () {
              final logs = _logger.getLogsAsText();
              // Aquí podrías implementar copia al portapapeles
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logs copiados al portapapeles'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Copiar logs',
          ),
        ],
      ),
    );
  }

  Widget _buildLevelFilter() {
    return DropdownButton<LogLevel>(
      value: _logger.currentLevel,
      dropdownColor: Colors.grey[900],
      style: const TextStyle(color: Colors.white, fontSize: 12),
      underline: Container(),
      items: LogLevel.values.map((level) {
        return DropdownMenuItem(
          value: level,
          child: Text(
            _getLevelLabel(level),
            style: TextStyle(
              color: _getLevelColor(level),
              fontSize: 12,
            ),
          ),
        );
      }).toList(),
      onChanged: (level) {
        if (level != null) {
          _logger.setLevel(level);
        }
      },
    );
  }

  Widget _buildLogsList() {
    final logs = _logger.logs;
    
    if (logs.isEmpty) {
      return const Center(
        child: Text(
          'No hay logs para mostrar',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return _buildLogEntry(log);
      },
    );
  }

  Widget _buildLogEntry(DebugLogEntry log) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getLogBackgroundColor(log.level),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _getLevelColor(log.level).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Línea principal del log
          Row(
            children: [
              Text(
                _getLevelIcon(log.level),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 4),
              Text(
                log.timestamp.toString().substring(11, 19),
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              if (log.tag != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    log.tag!,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 4),
          
          // Mensaje principal
          Text(
            log.message,
            style: TextStyle(
              color: _getLevelColor(log.level),
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
          
          // Datos adicionales
          if (log.data != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '📊 ${log.data}',
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
          
          // Error
          if (log.error != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '❌ ${log.error}',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getLevelLabel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍 Debug';
      case LogLevel.info:
        return 'ℹ️ Info';
      case LogLevel.warning:
        return '⚠️ Warning';
      case LogLevel.error:
        return '❌ Error';
      case LogLevel.critical:
        return '🚨 Critical';
    }
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.blue;
      case LogLevel.info:
        return Colors.green;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.critical:
        return Colors.purple;
    }
  }

  Color _getLogBackgroundColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.blue.withOpacity(0.05);
      case LogLevel.info:
        return Colors.green.withOpacity(0.05);
      case LogLevel.warning:
        return Colors.orange.withOpacity(0.05);
      case LogLevel.error:
        return Colors.red.withOpacity(0.05);
      case LogLevel.critical:
        return Colors.purple.withOpacity(0.05);
    }
  }

  String _getLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.critical:
        return '🚨';
    }
  }
}

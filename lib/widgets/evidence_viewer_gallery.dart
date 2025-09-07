import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:open_file/open_file.dart';
import 'package:inspecao/models/evidence.dart';

class EvidenceViewer extends StatefulWidget {
  final Evidence evidence;
  final bool showControls;

  const EvidenceViewer({
    super.key,
    required this.evidence,
    this.showControls = false,
  });

  @override
  State<EvidenceViewer> createState() => _EvidenceViewerState();
}

class _EvidenceViewerState extends State<EvidenceViewer> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  bool _showVideoControls = false;

  @override
  void initState() {
    super.initState();
    if (widget.evidence.type == EvidenceType.video) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.file(File(widget.evidence.filePath));
      await _videoController!.initialize();
      
      // Adicionar listeners para controle de estado
      _videoController!.addListener(() {
        if (mounted) {
          setState(() {
            _isPlaying = _videoController!.value.isPlaying;
          });
        }
      });
      
      if (mounted) {
        setState(() => _isVideoInitialized = true);
      }
    } catch (e) {
      print('Erro ao inicializar vídeo: $e');
    }
  }

  void _toggleVideoPlayback() {
    if (_videoController != null) {
      if (_isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    }
  }

  void _toggleVideoControls() {
    setState(() {
      _showVideoControls = !_showVideoControls;
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showControls) {
      // Modo galeria - tela cheia
      return _buildGalleryView();
    } else {
      // Modo dialog - visualização tradicional
      return _buildDialogView();
    }
  }

  Widget _buildGalleryView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          // Conteúdo principal
          Center(
            child: _buildContent(),
          ),
          
          // Controles de vídeo (apenas para vídeos)
          if (widget.evidence.type == EvidenceType.video && _isVideoInitialized)
            _buildVideoControls(),
        ],
      ),
    );
  }

  Widget _buildDialogView() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header com fundo azul
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getTypeIcon(widget.evidence.type),
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.evidence.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.evidence.typeText,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Conteúdo
            Expanded(
              child: _buildContent(),
            ),
            
            // Footer com informações
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Arquivo: ${_getFileName(widget.evidence.filePath)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enviado em: ${_formatDate(widget.evidence.uploadedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (widget.evidence.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Comentário:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.evidence.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (widget.evidence.type) {
      case EvidenceType.photo:
        return _buildPhotoView();
      case EvidenceType.video:
        return _buildVideoView();
      case EvidenceType.document:
        return _buildDocumentView();
    }
  }

  Widget _buildPhotoView() {
    if (widget.evidence.filePath.startsWith('/') || widget.evidence.filePath.contains('\\')) {
      final file = File(widget.evidence.filePath);
      if (file.existsSync()) {
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorView('Erro ao carregar imagem');
            },
          ),
        );
      }
    }
    return _buildErrorView('Arquivo não encontrado');
  }

  Widget _buildVideoView() {
    if (!_isVideoInitialized || _videoController == null) {
      return _buildLoadingView();
    }

    return GestureDetector(
      onTap: _toggleVideoControls,
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      ),
    );
  }

  Widget _buildDocumentView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getDocumentIcon(widget.evidence.filePath),
            size: 80,
            color: widget.showControls ? Colors.white : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            _getFileName(widget.evidence.filePath),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: widget.showControls ? Colors.white : null,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Toque para abrir o arquivo',
            style: TextStyle(
              color: widget.showControls ? Colors.white70 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _openFile(widget.evidence.filePath),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Abrir Arquivo'),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoControls() {
    if (!_showVideoControls) return const SizedBox.shrink();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () {
                final currentPosition = _videoController!.value.position;
                final newPosition = currentPosition - const Duration(seconds: 10);
                _videoController!.seekTo(newPosition);
              },
              icon: const Icon(Icons.replay_10, color: Colors.white),
              iconSize: 32,
            ),
            const SizedBox(width: 20),
            IconButton(
              onPressed: _toggleVideoPlayback,
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
              iconSize: 48,
            ),
            const SizedBox(width: 20),
            IconButton(
              onPressed: () {
                final currentPosition = _videoController!.value.position;
                final newPosition = currentPosition + const Duration(seconds: 10);
                _videoController!.seekTo(newPosition);
              },
              icon: const Icon(Icons.forward_10, color: Colors.white),
              iconSize: 32,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(EvidenceType type) {
    switch (type) {
      case EvidenceType.photo:
        return Icons.photo;
      case EvidenceType.document:
        return Icons.description;
      case EvidenceType.video:
        return Icons.videocam;
    }
  }

  IconData _getDocumentIcon(String filePath) {
    final extension = _getFileExtension(filePath).toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getFileName(String filePath) {
    return filePath.split('/').last.split('\\').last;
  }

  String _getFileExtension(String filePath) {
    final fileName = _getFileName(filePath);
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot == -1) return '';
    return fileName.substring(lastDot + 1);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _openFile(String filePath) async {
    try {
      await OpenFile.open(filePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir arquivo: $e')),
        );
      }
    }
  }
}

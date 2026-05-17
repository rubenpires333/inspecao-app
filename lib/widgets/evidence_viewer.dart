import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:open_file/open_file.dart';
import 'package:audioplayers/audioplayers.dart';
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

  // Controle de áudio
  AudioPlayer? _audioPlayer;
  bool _isAudioPlaying = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.evidence.type == EvidenceType.video) {
      _initializeVideo();
    } else if (widget.evidence.type == EvidenceType.audio) {
      _initializeAudio();
    }
  }

  Future<void> _initializeAudio() async {
    try {
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setSource(DeviceFileSource(widget.evidence.filePath));
      
      _audioPlayer!.onDurationChanged.listen((d) {
        if (mounted) setState(() => _audioDuration = d);
      });
      
      _audioPlayer!.onPositionChanged.listen((p) {
        if (mounted) setState(() => _audioPosition = p);
      });
      
      _audioPlayer!.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isAudioPlaying = state == PlayerState.playing;
          });
        }
      });
    } catch (e) {
      print('Erro ao inicializar áudio: $e');
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
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Content principal
            Expanded(
              child: _buildContent(context),
            ),
            
            // Footer com informações
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  // Descrição
                  if (widget.evidence.description.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Descrição:',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.evidence.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Informações do arquivo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateTime(widget.evidence.uploadedAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      if (widget.evidence.fileSize > 0)
                        Row(
                          children: [
                            Icon(
                              Icons.storage,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatFileSize(widget.evidence.fileSize),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                    ],
                  ),
                  
                  // Botões de ação
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openFile(context),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Abrir'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          label: const Text('Fechar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (widget.evidence.type == EvidenceType.photo) {
      return _buildImagePreview(context);
    } else if (widget.evidence.type == EvidenceType.video) {
      return _buildVideoPreview(context);
    } else if (widget.evidence.type == EvidenceType.audio) {
      return _buildAudioPreview(context);
    } else {
      return _buildDocumentPreview(context);
    }
  }

  Widget _buildAudioPreview(BuildContext context) {
    final posMinutes = _audioPosition.inMinutes.toString().padLeft(2, '0');
    final posSeconds = (_audioPosition.inSeconds % 60).toString().padLeft(2, '0');
    final durMinutes = _audioDuration.inMinutes.toString().padLeft(2, '0');
    final durSeconds = (_audioDuration.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Microfone em destaque
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.mic,
                size: 64,
                color: Colors.orange.shade800,
              ),
            ),
            const SizedBox(height: 32),
            // Slider / Seekbar
            Slider(
              value: _audioPosition.inMilliseconds.toDouble(),
              max: _audioDuration.inMilliseconds > 0 
                  ? _audioDuration.inMilliseconds.toDouble() 
                  : 1.0,
              activeColor: Colors.orange.shade800,
              inactiveColor: Colors.orange.shade100,
              onChanged: (value) async {
                if (_audioPlayer != null) {
                  await _audioPlayer!.seek(Duration(milliseconds: value.toInt()));
                }
              },
            ),
            // Timestamps
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$posMinutes:$posSeconds',
                    style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '$durMinutes:$durSeconds',
                    style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Controles de Play / Pause / Stop
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    if (_audioPlayer != null) {
                      if (_isAudioPlaying) {
                        await _audioPlayer!.pause();
                      } else {
                        await _audioPlayer!.resume();
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                  ),
                  child: Icon(
                    _isAudioPlaying ? Icons.pause : Icons.play_arrow,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () async {
                    if (_audioPlayer != null) {
                      await _audioPlayer!.stop();
                    }
                  },
                  icon: const Icon(Icons.stop),
                  iconSize: 32,
                  color: Colors.grey.shade700,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildImageWidget(context),
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(BuildContext context) {
    // Tentar carregar como arquivo local primeiro
    if (widget.evidence.filePath.startsWith('/') || widget.evidence.filePath.contains('\\')) {
      final file = File(widget.evidence.filePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget(context, 'Erro ao carregar imagem');
          },
        );
      }
    }
    
    // Se não for arquivo local, mostrar ícone
    return _buildErrorWidget(context, 'Imagem não encontrada');
  }

  Widget _buildVideoPreview(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildVideoWidget(context),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoWidget(BuildContext context) {
    if (_videoController != null && _isVideoInitialized) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Stack(
          children: [
            VideoPlayer(_videoController!),
            Center(
              child: FloatingActionButton(
                onPressed: () {
                  setState(() {
                    if (_videoController!.value.isPlaying) {
                      _videoController!.pause();
                    } else {
                      _videoController!.play();
                    }
                  });
                },
                child: Icon(
                  _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        height: 200,
        color: Theme.of(context).colorScheme.surfaceVariant,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'Carregando vídeo...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDocumentPreview(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getDocumentIcon(widget.evidence.filePath),
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _getFileName(widget.evidence.filePath),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Arquivo: ${_getFileExtension(widget.evidence.filePath).toUpperCase()}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openFile(context),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
           '${dateTime.month.toString().padLeft(2, '0')}/'
           '${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  IconData _getTypeIcon(EvidenceType type) {
    switch (type) {
      case EvidenceType.photo:
        return Icons.photo;
      case EvidenceType.video:
        return Icons.videocam;
      case EvidenceType.audio:
        return Icons.mic;
      case EvidenceType.document:
        return Icons.description;
    }
  }

  Future<void> _openFile(BuildContext context) async {
    try {
      final result = await OpenFile.open(widget.evidence.filePath);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir arquivo: ${result.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao abrir arquivo: $e')),
      );
    }
  }
}

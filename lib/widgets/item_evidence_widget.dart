import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:inspecao/models/evidence.dart';
import 'package:inspecao/models/user.dart';
import 'package:inspecao/services/data_service.dart';
import 'package:inspecao/screens/evidence_gallery_screen.dart';

class ItemEvidenceWidget extends StatefulWidget {
  final String inspectionId;
  final String itemId;
  final String itemTitle;
  final Function(List<Evidence>) onEvidencesChanged;
  final bool enabled;
  final bool allowDeletion; // Nova propriedade para controlar exclusão

  const ItemEvidenceWidget({
    super.key,
    required this.inspectionId,
    required this.itemId,
    required this.itemTitle,
    required this.onEvidencesChanged,
    this.enabled = true,
    this.allowDeletion = true, // Por padrão permite exclusão
  });

  @override
  State<ItemEvidenceWidget> createState() => _ItemEvidenceWidgetState();
}

class _ItemEvidenceWidgetState extends State<ItemEvidenceWidget> {
  final _dataService = DataService();
  final _commentController = TextEditingController();
  final _imagePicker = ImagePicker();
  
  User? _currentUser;
  List<Evidence> _evidences = [];
  bool _isLoading = false;
  String? _selectedImagePath;
  String? _selectedImageSource;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadEvidences();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await _dataService.getCurrentUser();
    if (mounted) {
      setState(() => _currentUser = user);
    }
  }

  Future<void> _loadEvidences() async {
    final evidences = await _dataService.getEvidencesByInspection(widget.inspectionId);
    final itemEvidences = evidences.where((e) => e.description.contains('Item: ${widget.itemId}')).toList();
    if (mounted) {
      setState(() => _evidences = itemEvidences);
    }
  }

  Future<void> _takePhoto() async {
    try {
      Navigator.pop(context); // Fechar diálogo primeiro
      
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
          _selectedImageSource = 'Foto da câmera';
        });
        _showSaveDialog();
      }
    } catch (e) {
      _showSnackBar('Erro ao tirar foto: ${e.toString()}');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      Navigator.pop(context); // Fechar diálogo primeiro
      
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
          _selectedImageSource = 'Foto da galeria';
        });
        _showSaveDialog();
      }
    } catch (e) {
      _showSnackBar('Erro ao selecionar foto: ${e.toString()}');
    }
  }

  Future<void> _pickFile() async {
    try {
      Navigator.pop(context); // Fechar diálogo primeiro
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: false,
        withReadStream: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;
        
        // Determinar o tipo baseado na extensão
        String extension = file.extension?.toLowerCase() ?? '';
        String sourceType;
        
        if (['mp4', 'avi', 'mov', 'mkv', 'wmv'].contains(extension)) {
          sourceType = 'Vídeo';
        } else if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension)) {
          sourceType = 'Foto da galeria';
        } else {
          sourceType = 'Documento';
        }
        
        setState(() {
          _selectedImagePath = file.path ?? file.name;
          _selectedImageSource = sourceType;
        });
        _showSaveDialog();
      }
    } catch (e) {
      _showSnackBar('Erro ao selecionar arquivo: ${e.toString()}');
    }
  }

  Future<void> _addEvidence() async {
    if (_currentUser == null || _selectedImagePath == null) return;

    setState(() => _isLoading = true);

    try {
      // Determinar o tipo de evidência baseado na fonte
      EvidenceType evidenceType;
      if (_selectedImageSource == 'Vídeo') {
        evidenceType = EvidenceType.video;
      } else if (_selectedImageSource == 'Documento') {
        evidenceType = EvidenceType.document;
      } else {
        evidenceType = EvidenceType.photo;
      }

      // Obter tamanho do arquivo se possível
      int fileSize = 0;
      try {
        if (_selectedImagePath != null) {
          final file = File(_selectedImagePath!);
          if (await file.exists()) {
            fileSize = await file.length();
          }
        }
      } catch (e) {
        // Se não conseguir obter o tamanho, mantém 0
        fileSize = 0;
      }

      final evidence = Evidence(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        inspectionId: widget.inspectionId,
        uploadedBy: _currentUser!,
        title: '${widget.itemTitle} - ${DateFormat('dd/MM HH:mm').format(DateTime.now())}',
        description: 'Item: ${widget.itemId} | Fonte: $_selectedImageSource${_commentController.text.isNotEmpty ? ' | Comentário: ${_commentController.text}' : ''}',
        filePath: _selectedImagePath!,
        type: evidenceType,
        uploadedAt: DateTime.now(),
        fileSize: fileSize,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _dataService.addEvidence(evidence);
      
      setState(() {
        _evidences.add(evidence);
        _commentController.clear();
        _selectedImagePath = null;
        _selectedImageSource = null;
      });
      
      widget.onEvidencesChanged(_evidences);
      _showSnackBar('Evidência adicionada com sucesso!');
    } catch (e) {
      _showSnackBar('Erro ao adicionar evidência: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Salvar Evidência',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.surfaceVariant,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildPreviewWidget(context),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Comentário (opcional)',
                  hintText: 'Adicione um comentário sobre esta evidência...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedImagePath = null;
                          _selectedImageSource = null;
                        });
                      },
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () {
                        Navigator.pop(context);
                        _addEvidence();
                      },
                      child: _isLoading 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Salvar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Adicionar Evidência',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              Text(
                'Escolha como deseja adicionar a evidência:',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Tirar Foto'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _pickFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Selecionar da Galeria'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _pickFile,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Selecionar Arquivo'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewWidget(BuildContext context) {
    if (_selectedImagePath == null) {
      return Icon(
        Icons.image,
        size: 64,
        color: Theme.of(context).colorScheme.primary,
      );
    }

    if (_selectedImageSource == 'Vídeo') {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            _getFileName(_selectedImagePath!),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    } else if (_selectedImageSource == 'Documento') {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getDocumentIcon(_selectedImagePath!),
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            _getFileName(_selectedImagePath!),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    } else {
      // Para fotos, tentar mostrar preview real
      if (_selectedImagePath!.startsWith('/') || _selectedImagePath!.contains('\\')) {
        final file = File(_selectedImagePath!);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.photo,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              );
            },
          );
        }
      }
      
      return Icon(
        Icons.photo,
        size: 64,
        color: Theme.of(context).colorScheme.primary,
      );
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _deleteEvidence(Evidence evidence) async {
    try {
      setState(() => _isLoading = true);
      
      await _dataService.deleteEvidence(evidence.id);
      
      setState(() {
        _evidences.removeWhere((e) => e.id == evidence.id);
      });
      
      widget.onEvidencesChanged(_evidences);
      _showSnackBar('Evidência removida com sucesso!');
    } catch (e) {
      _showSnackBar('Erro ao remover evidência: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDeleteConfirmation(Evidence evidence) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja remover esta evidência?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEvidence(evidence);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_library,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Evidências (${_evidences.length})',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Spacer(),
              if (widget.enabled)
                IconButton(
                  onPressed: _isLoading ? null : _showImageSourceDialog,
                  icon: const Icon(Icons.add_photo_alternate),
                  iconSize: 20,
                  tooltip: 'Adicionar Evidência',
                ),
            ],
          ),
          if (_evidences.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _evidences.length,
                itemBuilder: (context, index) {
                  final evidence = _evidences[index];
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _showEvidenceDetail(evidence),
                      child: Card(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(context).colorScheme.surfaceVariant,
                          ),
                          child: Stack(
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: _buildEvidenceThumbnail(evidence),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('HH:mm').format(evidence.uploadedAt),
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                              // Botão de exclusão (apenas se permitido e habilitado)
                              if (widget.allowDeletion && widget.enabled)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _showDeleteConfirmation(evidence),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEvidenceThumbnail(Evidence evidence) {
    if (evidence.type == EvidenceType.photo) {
      // Tentar mostrar thumbnail real da foto
      if (evidence.filePath.startsWith('/') || evidence.filePath.contains('\\')) {
        final file = File(evidence.filePath);
        if (file.existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.photo,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                );
              },
            ),
          );
        }
      }
    } else if (evidence.type == EvidenceType.video) {
      // Para vídeos, mostrar ícone com indicador
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.videocam,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Fallback para ícone
    return Icon(
      evidence.type == EvidenceType.photo ? Icons.photo : 
      evidence.type == EvidenceType.video ? Icons.videocam : 
      _getDocumentIcon(evidence.filePath),
      color: Theme.of(context).colorScheme.primary,
      size: 24,
    );
  }

  void _showEvidenceDetail(Evidence evidence) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EvidenceGalleryScreen(
          evidences: _evidences,
          initialIndex: _evidences.indexOf(evidence),
        ),
      ),
    );
  }

}

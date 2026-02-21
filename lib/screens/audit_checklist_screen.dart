import 'package:flutter/material.dart';
import 'package:inspecao/models/inspection.dart';
import 'package:inspecao/models/inspection_item.dart';
import 'package:inspecao/models/user.dart';
import 'package:inspecao/services/data_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AuditChecklistScreen extends StatefulWidget {
  final Inspection template;
  final Position location;
  final User author;

  const AuditChecklistScreen({
    super.key,
    required this.template,
    required this.location,
    required this.author,
  });

  @override
  State<AuditChecklistScreen> createState() => _AuditChecklistScreenState();
}

class _AuditChecklistScreenState extends State<AuditChecklistScreen> {
  final _dataService = DataService();
  final _imagePicker = ImagePicker();
  
  int _currentPage = 0;
  int _totalPages = 1;
  Map<String, dynamic> _answers = {};
  Map<String, List<File>> _attachments = {};
  Map<String, String> _comments = {};

  @override
  void initState() {
    super.initState();
    _calculatePages();
  }

  void _calculatePages() {
    // Calcular número de páginas baseado no número de perguntas
    final questionsPerPage = 2; // 2 perguntas por página
    _totalPages = (widget.template.itens.length / questionsPerPage).ceil();
  }


  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _answerQuestion(String questionId, dynamic answer) {
    setState(() {
      _answers[questionId] = answer;
    });
  }

  void _addComment(String questionId) {
    showDialog(
      context: context,
      builder: (context) => _CommentDialog(
        initialText: _comments[questionId] ?? '',
        onSave: (text) {
          setState(() {
            _comments[questionId] = text;
          });
        },
      ),
    );
  }

  void _addPhoto(String questionId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose an action',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.camera_alt,
                  label: 'Take photo',
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto(questionId);
                  },
                ),
                _buildActionButton(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromGallery(questionId);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1976D2),
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF2E2E2E),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _takePhoto(String questionId) async {
    final image = await _imagePicker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _attachments.putIfAbsent(questionId, () => []).add(File(image.path));
      });
    }
  }

  Future<void> _pickFromGallery(String questionId) async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _attachments.putIfAbsent(questionId, () => []).add(File(image.path));
      });
    }
  }

  void _submitAudit() async {
    try {
      // Criar nova inspeção baseada no template
      final newInspection = Inspection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        titulo: widget.template.titulo,
        descricao: widget.template.descricao,
        tipo: widget.template.tipo,
        status: InspectionStatus.emAndamento,
        dataAgendada: DateTime.now(),
        endereco: '${widget.location.latitude}, ${widget.location.longitude}',
        latitude: widget.location.latitude,
        longitude: widget.location.longitude,
        equipe: widget.template.equipe,
        itens: widget.template.itens,
        establishmentId: widget.template.establishmentId,
        inspectorId: widget.author.id,
        isTemplate: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Salvar inspeção
      await _dataService.addInspection(newInspection);
      
      // Mostrar sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audit started successfully!'),
          backgroundColor: Color(0xFF1976D2),
        ),
      );
      
      // Voltar para a tela anterior
      Navigator.pop(context);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting audit: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildHeader() {
    return Container(
      height: 120,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1976D2), // lightPrimary
            Color(0xFF1565C0),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 16),
              // Title
              Expanded(
                child: Text(
                  widget.template.titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Chat button
              GestureDetector(
                onTap: () {
                  // Implementar chat/suporte
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 8),
              // More options
              GestureDetector(
                onTap: () {
                  // Implementar menu de opções
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.more_vert, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1976D2).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Explore this sample checklist. You can play with it and see how it works before creating your own.',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.assignment, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Text(
                '2 Sections ${widget.template.itens.length} Questions',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
            ],
          ),
          const SizedBox(height: 12),
          // Section progress
          Row(
            children: [
              Text(
                'Safety Measures',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              Container(
                width: 100,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.0, // 0% progress
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '0%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCollapsibleSection('Foundation-Filling', 0, [
          _buildSubSection('Pre-Pour', 0, 9, [
            'Dimensions Consistent with Elevations, Selections and Change orders?',
            'Beams/footings clear of water and debris? 20" wide?',
          ]),
        ]),
        const SizedBox(height: 16),
        _buildCollapsibleSection('Framing', 4, [
          _buildSubSection('Shear Wall, Windows, Doors', 1, 35, [
            'Is the lumber the correct grade as specified on the plans?',
            'Are the correct trusses installed per the engineered layout?',
          ]),
        ]),
      ],
    );
  }

  Widget _buildCollapsibleSection(String title, int progress, List<Widget> subsections) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E2E2E),
                    ),
                  ),
                ),
                // Progress bar
                Container(
                  width: 100,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$progress%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey[600], size: 20),
              ],
            ),
          ),
          // Subsections
          ...subsections,
        ],
      ),
    );
  }

  Widget _buildSubSection(String title, int completedSubs, int totalQuestions, List<String> questions) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subsection header
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E2E2E),
                  ),
                ),
              ),
              Icon(Icons.assignment, color: Colors.grey[600], size: 16),
              const SizedBox(width: 4),
              Text(
                '$completedSubs/1 Sub-sec',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.list, color: Colors.grey[600], size: 16),
              const SizedBox(width: 4),
              Text(
                '0/$totalQuestions Answered',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.keyboard_arrow_up, color: Colors.grey[600], size: 16),
            ],
          ),
          const SizedBox(height: 16),
          // Questions
          ...questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return _buildQuestionCard(question, index + 1);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(String question, int questionNumber) {
    final questionId = 'q$questionNumber';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question text
          Text(
            '$questionNumber. $question',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E2E2E),
            ),
          ),
          const SizedBox(height: 16),
          
          // Answer options
          _buildChoiceOptions(questionId),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => _addPhoto(questionId),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.grey,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _addComment(questionId),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.comment,
                    color: Colors.grey,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          
          // Show attachments if any
          if (_attachments.containsKey(questionId) && _attachments[questionId]!.isNotEmpty)
            _buildAttachments(questionId),
          
          // Show comment if any
          if (_comments.containsKey(questionId) && _comments[questionId]!.isNotEmpty)
            _buildComment(questionId),
        ],
      ),
    );
  }

  Widget _buildChoiceOptions(String questionId) {
    return Column(
      children: [
        _buildChoiceButton(questionId, 'Yes', ItemStatus.conforme),
        const SizedBox(height: 8),
        _buildChoiceButton(questionId, 'No', ItemStatus.naoConforme),
        const SizedBox(height: 8),
        _buildChoiceButton(questionId, 'N/A', ItemStatus.naoAplica),
      ],
    );
  }

  Widget _buildChoiceButton(String questionId, String label, ItemStatus status) {
    final isSelected = _answers[questionId] == status;
    
    return GestureDetector(
      onTap: () => _answerQuestion(questionId, status),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? (status == ItemStatus.naoConforme ? Colors.red : const Color(0xFF1976D2))
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? (status == ItemStatus.naoConforme ? Colors.red : const Color(0xFF1976D2))
                : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF2E2E2E),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }


  Widget _buildAttachments(String questionId) {
    final files = _attachments[questionId]!;
    
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: files.map((file) => _buildAttachmentThumbnail(file, questionId)).toList(),
      ),
    );
  }

  Widget _buildAttachmentThumbnail(File file, String questionId) {
    return Stack(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: FileImage(file),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: -5,
          right: -5,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _attachments[questionId]!.remove(file);
                if (_attachments[questionId]!.isEmpty) {
                  _attachments.remove(questionId);
                }
              });
            },
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComment(String questionId) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Text(
        _comments[questionId]!,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous button
          if (_currentPage > 0)
            GestureDetector(
              onTap: _previousPage,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.grey),
              ),
            )
          else
            const SizedBox(width: 40),
          
          const Spacer(),
          
          // Page indicator
          Text(
            'Page ${_currentPage + 1} of $_totalPages',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          
          const Spacer(),
          
          // Next button or Report button
          if (_currentPage < _totalPages - 1)
            GestureDetector(
              onTap: _nextPage,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_forward, color: Colors.white),
              ),
            )
          else
            GestureDetector(
              onTap: _showReport,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.visibility, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  void _showReport() {
    // Mostrar relatório da auditoria
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Audit Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Template: ${widget.template.titulo}'),
            const SizedBox(height: 8),
            Text('Questions Answered: ${_answers.length}'),
            const SizedBox(height: 8),
            Text('Comments Added: ${_comments.length}'),
            const SizedBox(height: 8),
            Text('Photos Attached: ${_attachments.values.fold(0, (sum, list) => sum + list.length)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitAudit();
            },
            child: const Text('Submit Audit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F0E9), // Background específico sempre
      body: Column(
        children: [
          _buildHeader(),
          _buildIntroSection(),
          _buildProgressSection(),
          Expanded(child: _buildQuestionsList()),
          _buildBottomNavigation(),
        ],
      ),
    );
  }
}

class _CommentDialog extends StatefulWidget {
  final String initialText;
  final Function(String) onSave;

  const _CommentDialog({
    required this.initialText,
    required this.onSave,
  });

  @override
  State<_CommentDialog> createState() => _CommentDialogState();
}

class _CommentDialogState extends State<_CommentDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Comments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 5,
              maxLength: 5000,
              decoration: const InputDecoration(
                hintText: 'Enter your comment...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1976D2)),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Color(0xFF1976D2)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onSave(_controller.text);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

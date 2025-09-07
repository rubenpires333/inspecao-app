import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inspecao/models/evidence.dart';
import 'package:inspecao/widgets/evidence_viewer.dart';

class EvidenceGalleryScreen extends StatefulWidget {
  final List<Evidence> evidences;
  final int initialIndex;

  const EvidenceGalleryScreen({
    super.key,
    required this.evidences,
    this.initialIndex = 0,
  });

  @override
  State<EvidenceGalleryScreen> createState() => _EvidenceGalleryScreenState();
}

class _EvidenceGalleryScreenState extends State<EvidenceGalleryScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showInfo = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _toggleInfo() {
    setState(() {
      _showInfo = !_showInfo;
    });
  }

  void _previousEvidence() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextEvidence() {
    if (_currentIndex < widget.evidences.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.evidences.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Galeria de Evidências'),
        ),
        body: const Center(
          child: Text('Nenhuma evidência encontrada'),
        ),
      );
    }

    final currentEvidence = widget.evidences[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Evidência ${_currentIndex + 1} de ${widget.evidences.length}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _toggleInfo,
            icon: Icon(
              _showInfo ? Icons.info_outline : Icons.info,
              color: Colors.white,
            ),
            tooltip: _showInfo ? 'Ocultar Informações' : 'Mostrar Informações',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Galeria principal
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: widget.evidences.length,
            itemBuilder: (context, index) {
              final evidence = widget.evidences[index];
              return _buildEvidenceView(evidence);
            },
          ),

          // Controles de navegação
          if (widget.evidences.length > 1) ...[
            // Botão anterior
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: _currentIndex > 0
                    ? GestureDetector(
                        onTap: _previousEvidence,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),

            // Botão próximo
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: _currentIndex < widget.evidences.length - 1
                    ? GestureDetector(
                        onTap: _nextEvidence,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],

          // Painel de informações
          if (_showInfo)
            Positioned(
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tipo e data
                    Row(
                      children: [
                        Icon(
                          _getEvidenceIcon(currentEvidence.type),
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getEvidenceTypeText(currentEvidence.type),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(currentEvidence.uploadedAt),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Nome do arquivo
                    Text(
                      _getFileName(currentEvidence.filePath),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Comentário (se existir)
                    if (currentEvidence.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          currentEvidence.description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Indicador de posição
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.evidences.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: index == _currentIndex
                                ? Colors.white
                                : Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Instruções de navegação (apenas se houver múltiplas evidências)
          if (widget.evidences.length > 1 && !_showInfo)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Deslize para navegar entre as evidências',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEvidenceView(Evidence evidence) {
    return Center(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: EvidenceViewer(
          evidence: evidence,
          showControls: true,
        ),
      ),
    );
  }

  IconData _getEvidenceIcon(EvidenceType type) {
    switch (type) {
      case EvidenceType.photo:
        return Icons.photo;
      case EvidenceType.document:
        return Icons.description;
      case EvidenceType.video:
        return Icons.videocam;
    }
  }

  String _getEvidenceTypeText(EvidenceType type) {
    switch (type) {
      case EvidenceType.photo:
        return 'Foto';
      case EvidenceType.document:
        return 'Documento';
      case EvidenceType.video:
        return 'Vídeo';
    }
  }

  String _getFileName(String filePath) {
    return filePath.split('/').last.split('\\').last;
  }
}

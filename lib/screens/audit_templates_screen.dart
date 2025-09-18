import 'package:flutter/material.dart';
import 'package:inspecao/services/data_service.dart';
import 'package:inspecao/models/organization.dart';

class AuditTemplatesScreen extends StatefulWidget {
  const AuditTemplatesScreen({super.key});

  @override
  State<AuditTemplatesScreen> createState() => _AuditTemplatesScreenState();
}

class _AuditTemplatesScreenState extends State<AuditTemplatesScreen> {
  final _dataService = DataService();
  List<AuditTemplate> _filteredTemplates = [];
  List<Organization> _organizations = [];
  List<Organization> _filteredOrganizations = [];
  Organization? _currentOrganization;
  String _companySearchQuery = '';
  bool _isLoading = false;
  bool _isCardView = true; // true = card view, false = list view
  bool _showCompanyModal = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Carregar organizações e organização atual
      final organizations = await _dataService.getOrganizations();
      final currentOrg = await _dataService.getCurrentOrganization();
      
      // Carregar templates do usuário
      final templates = await _dataService.getUserTemplates();
      
      if (mounted) {
        setState(() {
          _organizations = organizations;
          _filteredOrganizations = organizations;
          _currentOrganization = currentOrg;
          _filteredTemplates = templates;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  void _filterOrganizations() {
    setState(() {
      _filteredOrganizations = _organizations.where((organization) {
        return _companySearchQuery.isEmpty ||
            organization.name.toLowerCase().contains(_companySearchQuery.toLowerCase()) ||
            organization.description.toLowerCase().contains(_companySearchQuery.toLowerCase());
      }).toList();
    });
  }

  void _showCompanySelectionModal() {
    setState(() {
      _showCompanyModal = true;
      _companySearchQuery = '';
      _filteredOrganizations = _organizations;
    });
  }

  void _hideCompanySelectionModal() {
    setState(() => _showCompanyModal = false);
  }

  void _selectOrganization(Organization organization) async {
    await _dataService.setCurrentOrganization(organization);
    setState(() {
      _currentOrganization = organization;
      _showCompanyModal = false;
    });
  }

  void _toggleViewMode() {
    setState(() {
      _isCardView = !_isCardView;
    });
  }

  void _showTemplatePreview(AuditTemplate template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Content
            Expanded(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            template.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E2E2E),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Questions list
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: template.questions.length,
                        itemBuilder: (context, index) {
                          final question = template.questions[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${index + 1}. ${question.text}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF2E2E2E),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (question.type == 'choice' && question.options != null)
                                  Wrap(
                                    spacing: 8,
                                    children: question.options!.map((option) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          option,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      'Text input',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Color(0xFF1976D2)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Close',
                              style: TextStyle(
                                color: Color(0xFF1976D2),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _addTemplate(template);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Add',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addTemplate(AuditTemplate template) async {
    // Adicionar template aos templates do usuário
    await _dataService.addUserTemplate(template);
    
    // Mostrar feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${template.title} added to your templates'),
        backgroundColor: const Color(0xFF1976D2),
      ),
    );
    
    // Voltar para a tela anterior
    Navigator.pop(context);
  }

  Widget _buildHeader() {
    return Container(
      height: 120,
      decoration: const BoxDecoration(
        color: Color(0xFF1976D2), // Blue color from home screen
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
              const Expanded(
                child: Text(
                  'Start Audit',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Search and message icons
              Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.search, color: Colors.white, size: 24),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.message, color: Colors.white, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrganizationSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Organization selector
          Expanded(
            child: GestureDetector(
              onTap: _showCompanySelectionModal,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _currentOrganization?.name ?? 'MSN',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E2E2E),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // View mode toggle
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _isCardView ? null : _toggleViewMode,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isCardView ? const Color(0xFF1976D2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.grid_view,
                      color: _isCardView ? Colors.white : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _isCardView ? _toggleViewMode : null,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: !_isCardView ? const Color(0xFF1976D2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.list,
                      color: !_isCardView ? Colors.white : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddNewTemplateButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: () {
          // Navegar para tela de adicionar novo template
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add New Template functionality'),
              backgroundColor: Color(0xFF1976D2),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 20),
            SizedBox(width: 8),
            Text(
              'Add New Template',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesGrid() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredTemplates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No templates found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _filteredTemplates.length,
      itemBuilder: (context, index) {
        final template = _filteredTemplates[index];
        return _buildTemplateCard(template);
      },
    );
  }

  Widget _buildTemplatesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredTemplates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No templates found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredTemplates.length,
      itemBuilder: (context, index) {
        final template = _filteredTemplates[index];
        return _buildTemplateListItem(template);
      },
    );
  }

  Widget _buildTemplateCard(AuditTemplate template) {
    return GestureDetector(
      onTap: () => _showTemplatePreview(template),
      child: Container(
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
            // Template image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _getCategoryColor(template.category).withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(template.category),
                    color: _getCategoryColor(template.category),
                    size: 48,
                  ),
                ),
              ),
            ),
            // Template info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E2E2E),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${template.questionCount} questions',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateListItem(AuditTemplate template) {
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getCategoryColor(template.category).withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(
            _getCategoryIcon(template.category),
            color: _getCategoryColor(template.category),
            size: 24,
          ),
        ),
        title: Text(
          template.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E2E2E),
          ),
        ),
        subtitle: Text(
          '${template.questionCount} questions',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey,
          size: 16,
        ),
        onTap: () => _showTemplatePreview(template),
      ),
    );
  }

  Widget _buildCompanySelectionModal() {
    if (!_showCompanyModal) return const SizedBox.shrink();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Select Company',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E2E2E),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _hideCompanySelectionModal,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Search bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1976D2)),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _companySearchQuery = value;
                  });
                  _filterOrganizations();
                },
                decoration: const InputDecoration(
                  hintText: 'Search Company',
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Color(0xFF1976D2)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Companies list
            Expanded(
              child: _filteredOrganizations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No companies found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try a different search term',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _filteredOrganizations.length,
                      itemBuilder: (context, index) {
                        final organization = _filteredOrganizations[index];
                        final isSelected = _currentOrganization?.id == organization.id;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF1976D2).withOpacity(0.1) : Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF1976D2) : Colors.grey[200]!,
                            ),
                          ),
                          child: ListTile(
                            title: Text(
                              organization.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? const Color(0xFF1976D2) : const Color(0xFF2E2E2E),
                              ),
                            ),
                            subtitle: Text(
                              organization.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            onTap: () => _selectOrganization(organization),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Construction':
        return Colors.orange;
      case 'Retail':
        return Colors.blue;
      case 'Manufacturing':
        return Colors.purple;
      case 'Hotels & Vacation Rentals':
        return Colors.teal;
      case 'Food & Hospitality':
        return Colors.red;
      case 'Transport & Automotive':
        return Colors.green;
      case 'Facility & Services':
        return Colors.indigo;
      default:
        return const Color(0xFF1976D2);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Construction':
        return Icons.construction;
      case 'Retail':
        return Icons.shopping_cart;
      case 'Manufacturing':
        return Icons.precision_manufacturing;
      case 'Hotels & Vacation Rentals':
        return Icons.hotel;
      case 'Food & Hospitality':
        return Icons.restaurant;
      case 'Transport & Automotive':
        return Icons.directions_car;
      case 'Facility & Services':
        return Icons.cleaning_services;
      default:
        return Icons.assignment;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F0E9), // Light green background from image
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              _buildOrganizationSelector(),
              _buildAddNewTemplateButton(),
              Expanded(
                child: _isCardView ? _buildTemplatesGrid() : _buildTemplatesList(),
              ),
            ],
          ),
          _buildCompanySelectionModal(),
        ],
      ),
    );
  }
}
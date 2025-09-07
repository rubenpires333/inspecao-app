import 'package:flutter/material.dart';
import 'package:inspecao/models/inspector.dart';
import 'package:inspecao/services/data_service.dart';

class TeamSelectionScreen extends StatefulWidget {
  final List<Inspector> selectedTeam;
  final Function(List<Inspector>) onTeamSelected;

  const TeamSelectionScreen({
    super.key,
    required this.selectedTeam,
    required this.onTeamSelected,
  });

  @override
  State<TeamSelectionScreen> createState() => _TeamSelectionScreenState();
}

class _TeamSelectionScreenState extends State<TeamSelectionScreen> {
  final _dataService = DataService();
  List<Inspector> _inspectors = [];
  List<Inspector> _selectedTeam = [];
  bool _isLoading = false;
  String _searchQuery = '';
  InspectorRole? _filterRole;

  @override
  void initState() {
    super.initState();
    _selectedTeam = List.from(widget.selectedTeam);
    _loadInspectors();
  }

  Future<void> _loadInspectors() async {
    setState(() => _isLoading = true);
    try {
      final inspectors = await _dataService.getInspectors();
      if (mounted) {
        setState(() => _inspectors = inspectors);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Inspector> get _filteredInspectors {
    var filtered = _inspectors;

    // Filtro por texto
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((inspector) =>
          inspector.nome.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          inspector.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          inspector.especialidades.any((especialidade) =>
              especialidade.toLowerCase().contains(_searchQuery.toLowerCase()))).toList();
    }

    // Filtro por cargo
    if (_filterRole != null) {
      filtered = filtered.where((inspector) => inspector.cargo == _filterRole).toList();
    }

    return filtered;
  }

  void _toggleInspectorSelection(Inspector inspector) {
    setState(() {
      if (_selectedTeam.any((selected) => selected.id == inspector.id)) {
        _selectedTeam.removeWhere((selected) => selected.id == inspector.id);
      } else {
        _selectedTeam.add(inspector);
      }
    });
  }

  bool _isInspectorSelected(Inspector inspector) {
    return _selectedTeam.any((selected) => selected.id == inspector.id);
  }

  void _confirmSelection() {
    widget.onTeamSelected(_selectedTeam);
    Navigator.of(context).pop();
  }

  String _getRoleText(InspectorRole role) {
    switch (role) {
      case InspectorRole.lider:
        return 'Líder';
      case InspectorRole.tecnico:
        return 'Técnico';
      case InspectorRole.assistente:
        return 'Assistente';
    }
  }

  Color _getRoleColor(InspectorRole role) {
    switch (role) {
      case InspectorRole.lider:
        return Colors.red;
      case InspectorRole.tecnico:
        return Colors.blue;
      case InspectorRole.assistente:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Equipe'),
        actions: [
          if (_selectedTeam.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_selectedTeam.length} selecionado(s)',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Barra de pesquisa e filtros
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Pesquisar inspetores',
                    hintText: 'Nome, email ou especialidade...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Todos'),
                        selected: _filterRole == null,
                        onSelected: (selected) {
                          setState(() => _filterRole = null);
                        },
                      ),
                      const SizedBox(width: 8),
                      ...InspectorRole.values.map((role) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(_getRoleText(role)),
                            selected: _filterRole == role,
                            onSelected: (selected) {
                              setState(() => _filterRole = selected ? role : null);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de inspetores
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredInspectors.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Nenhum inspetor encontrado',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tente ajustar os filtros de pesquisa',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredInspectors.length,
                        itemBuilder: (context, index) {
                          final inspector = _filteredInspectors[index];
                          final isSelected = _isInspectorSelected(inspector);
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getRoleColor(inspector.cargo),
                                child: Text(
                                  inspector.nome.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                inspector.nome,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : null,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.work_outline,
                                        size: 14,
                                        color: isSelected 
                                            ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7)
                                            : Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _getRoleText(inspector.cargo),
                                        style: TextStyle(
                                          color: isSelected 
                                              ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7)
                                              : Colors.grey[600],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.email_outlined,
                                        size: 14,
                                        color: isSelected 
                                            ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7)
                                            : Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          inspector.email,
                                          style: TextStyle(
                                            color: isSelected 
                                                ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7)
                                                : Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (inspector.especialidades.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 2,
                                      children: inspector.especialidades.take(3).map((especialidade) {
                                        return Chip(
                                          label: Text(
                                            especialidade,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isSelected 
                                                  ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8)
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                          backgroundColor: isSelected 
                                              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                                              : Colors.grey[200],
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check_circle,
                                      color: Theme.of(context).colorScheme.primary,
                                    )
                                  : Icon(
                                      Icons.radio_button_unchecked,
                                      color: Colors.grey[400],
                                    ),
                              onTap: () => _toggleInspectorSelection(inspector),
                            ),
                          );
                        },
                      ),
          ),
          
          // Botão Confirmar
          if (_selectedTeam.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _confirmSelection,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    ),
                    icon: const Icon(
                      Icons.check_circle,
                      size: 24,
                    ),
                    label: Text(
                      'Confirmar Seleção (${_selectedTeam.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

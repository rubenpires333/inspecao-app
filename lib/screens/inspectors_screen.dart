import 'package:flutter/material.dart';
import 'package:inspecao/models/inspector.dart';
import 'package:inspecao/services/data_service.dart';

class InspectorsScreen extends StatefulWidget {
  const InspectorsScreen({super.key});

  @override
  State<InspectorsScreen> createState() => _InspectorsScreenState();
}

class _InspectorsScreenState extends State<InspectorsScreen> {
  final _dataService = DataService();
  List<Inspector> _inspectors = [];
  String _searchQuery = '';
  InspectorRole? _filterRole;

  @override
  void initState() {
    super.initState();
    _loadInspectors();
  }

  Future<void> _loadInspectors() async {
    final inspectors = await _dataService.getInspectors();
    if (mounted) {
      setState(() => _inspectors = inspectors);
    }
  }

  List<Inspector> get _filteredInspectors {
    var filtered = _inspectors;

    // Filtro por texto
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((inspector) =>
          inspector.nome.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          inspector.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          inspector.telefone.contains(_searchQuery) ||
          inspector.especialidades.any((especialidade) =>
              especialidade.toLowerCase().contains(_searchQuery.toLowerCase()))).toList();
    }

    // Filtro por cargo
    if (_filterRole != null) {
      filtered = filtered.where((inspector) => inspector.cargo == _filterRole).toList();
    }

    return filtered;
  }

  Color _getRoleColor(InspectorRole role) {
    switch (role) {
      case InspectorRole.lider:
        return Colors.purple;
      case InspectorRole.tecnico:
        return Colors.blue;
      case InspectorRole.assistente:
        return Colors.green;
    }
  }

  IconData _getRoleIcon(InspectorRole role) {
    switch (role) {
      case InspectorRole.lider:
        return Icons.person_pin;
      case InspectorRole.tecnico:
        return Icons.engineering;
      case InspectorRole.assistente:
        return Icons.support_agent;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipe de Inspetores'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadInspectors,
        child: Column(
          children: [
            // Barra de pesquisa e filtros
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Pesquisar inspetores',
                      hintText: 'Nome, email, telefone ou especialidade...',
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
              child: _filteredInspectors.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search_outlined, size: 64, color: Colors.grey),
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
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: _getRoleColor(inspector.cargo),
                                child: Icon(
                                  _getRoleIcon(inspector.cargo),
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      inspector.nome,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      inspector.cargoText,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: _getRoleColor(inspector.cargo),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!inspector.ativo)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Inativo',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(Icons.email, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                inspector.email,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                inspector.telefone,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          if (inspector.especialidades.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Especialidades:',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: inspector.especialidades.map((especialidade) {
                                return Chip(
                                  label: Text(
                                    especialidade,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
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
}
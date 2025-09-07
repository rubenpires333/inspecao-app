import 'package:flutter/material.dart';
import 'package:inspecao/models/establishment.dart';
import 'package:inspecao/services/data_service.dart';

class EstablishmentSelectionScreen extends StatefulWidget {
  final Establishment? selectedEstablishment;
  final Function(Establishment) onEstablishmentSelected;

  const EstablishmentSelectionScreen({
    super.key,
    this.selectedEstablishment,
    required this.onEstablishmentSelected,
  });

  @override
  State<EstablishmentSelectionScreen> createState() => _EstablishmentSelectionScreenState();
}

class _EstablishmentSelectionScreenState extends State<EstablishmentSelectionScreen> {
  final _dataService = DataService();
  List<Establishment> _establishments = [];
  bool _isLoading = false;
  String _searchQuery = '';
  EstablishmentType? _filterType;

  @override
  void initState() {
    super.initState();
    _loadEstablishments();
  }

  Future<void> _loadEstablishments() async {
    setState(() => _isLoading = true);
    try {
      final establishments = await _dataService.getAllEstablishments();
      if (mounted) {
        setState(() => _establishments = establishments);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Establishment> get _filteredEstablishments {
    var filtered = _establishments;

    // Filtro por texto
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((e) =>
          e.nome.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.descricao.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.endereco.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Filtro por tipo
    if (_filterType != null) {
      filtered = filtered.where((e) => e.tipo == _filterType).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Estabelecimento'),
      ),
      body: Column(
        children: [
          // Barra de pesquisa
          Padding(
            padding: const EdgeInsets.all(16),
            child:             TextField(
              decoration: InputDecoration(
                labelText: 'Pesquisar estabelecimentos',
                hintText: 'Nome, descrição ou endereço...',
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
          ),
          
          // Filtros por tipo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Todos'),
                    selected: _filterType == null,
                    onSelected: (selected) {
                      setState(() => _filterType = null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ...EstablishmentType.values.map((type) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(DataService.getEstablishmentTypeText(type)),
                        selected: _filterType == type,
                        onSelected: (selected) {
                          setState(() => _filterType = selected ? type : null);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Lista de estabelecimentos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEstablishments.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.business_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Nenhum dados encontrados',
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
                        itemCount: _filteredEstablishments.length,
                        itemBuilder: (context, index) {
                          final establishment = _filteredEstablishments[index];
                          final isSelected = widget.selectedEstablishment?.id == establishment.id;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: DataService.getEstablishmentTypeColor(establishment.tipo),
                                child: Text(
                                  establishment.tipoIcon,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                              title: Text(
                                establishment.nome,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : null,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    establishment.descricao,
                                    style: TextStyle(
                                      color: isSelected 
                                          ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8)
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 14,
                                        color: isSelected 
                                            ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7)
                                            : Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          establishment.endereco,
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
                                  if (establishment.responsavel != null) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person,
                                          size: 14,
                                          color: isSelected 
                                              ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7)
                                              : Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          establishment.responsavel!,
                                          style: TextStyle(
                                            color: isSelected 
                                                ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7)
                                                : Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check_circle,
                                      color: Theme.of(context).colorScheme.primary,
                                    )
                                  : null,
                              onTap: () {
                                widget.onEstablishmentSelected(establishment);
                                Navigator.of(context).pop();
                              },
                            ),
                          );
                        },
                      ),
          ),
          
          // Botão Cancelar
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
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                      width: 1.5,
                    ),
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                  ),
                  icon: const Icon(
                    Icons.close,
                    size: 24,
                  ),
                  label: const Text(
                    'Cancelar',
                    style: TextStyle(
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

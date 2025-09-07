import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:inspecao/models/inspection.dart';
import 'package:inspecao/models/establishment.dart';
import 'package:inspecao/services/data_service.dart';
import 'package:inspecao/screens/inspection_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _dataService = DataService();
  List<Inspection> _inspections = [];
  InspectionStatus? _statusFilter;
  Map<String, Establishment> _establishmentsCache = {};
  
  // Variáveis do mapa
  MapController _mapController = MapController();
  List<Marker> _markers = [];
  String _currentMapStyle = 'OpenStreetMap';
  LatLng? _currentLocation;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadInspections();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  void _updateMarkers() {
    _markers.clear();
    
    for (final inspection in _filteredInspections) {
      _markers.add(
        Marker(
          point: LatLng(inspection.latitude, inspection.longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InspectionDetailScreen(inspection: inspection),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: _getStatusColor(inspection.status),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _getStatusIcon(inspection.status),
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }
    
    // Adicionar marcador da localização atual se disponível
    if (_currentLocation != null) {
      _markers.add(
        Marker(
          point: _currentLocation!,
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.my_location,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      );
    }
    
    setState(() {});
  }

  void _changeMapType() {
    setState(() {
      switch (_currentMapStyle) {
        case 'OpenStreetMap':
          _currentMapStyle = 'CartoDB';
          break;
        case 'CartoDB':
          _currentMapStyle = 'Mapbox';
          break;
        case 'Mapbox':
          _currentMapStyle = 'OpenStreetMap';
          break;
        default:
          _currentMapStyle = 'OpenStreetMap';
      }
    });
  }

  TileLayer _getTileLayer() {
    switch (_currentMapStyle) {
      case 'CartoDB':
        return TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.inspecao.app',
        );
      case 'Mapbox':
        return TileLayer(
          urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6ImNpejY4NXVycTA2emYycXBndHRqcmZ3N3gifQ.rJcFIG214AriISLbB6B5aw',
          userAgentPackageName: 'com.inspecao.app',
        );
      default: // OpenStreetMap
        return TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.inspecao.app',
        );
    }
  }

  void _centerMapOnInspections() {
    if (_filteredInspections.isEmpty) return;
    
    double minLat = _filteredInspections.first.latitude;
    double maxLat = _filteredInspections.first.latitude;
    double minLng = _filteredInspections.first.longitude;
    double maxLng = _filteredInspections.first.longitude;
    
    for (final inspection in _filteredInspections) {
      minLat = minLat < inspection.latitude ? minLat : inspection.latitude;
      maxLat = maxLat > inspection.latitude ? maxLat : inspection.latitude;
      minLng = minLng < inspection.longitude ? minLng : inspection.longitude;
      maxLng = maxLng > inspection.longitude ? maxLng : inspection.longitude;
    }
    
    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
    
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  Future<void> _loadInspections() async {
    final inspections = await _dataService.getInspections();
    
    // Carregar estabelecimentos para cache
    final establishments = await _dataService.getAllEstablishments();
    final establishmentsMap = <String, Establishment>{};
    for (final establishment in establishments) {
      establishmentsMap[establishment.id] = establishment;
    }
    
    if (mounted) {
      setState(() {
        _inspections = inspections;
        _establishmentsCache = establishmentsMap;
      });
      _updateMarkers();
    }
  }

  List<Inspection> get _filteredInspections {
    final filtered = _statusFilter == null 
        ? _inspections 
        : _inspections.where((i) => i.status == _statusFilter).toList();
    
    // Atualizar marcadores quando o filtro mudar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateMarkers();
      }
    });
    
    return filtered;
  }

  Future<void> _openMap(Inspection inspection) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${inspection.latitude},${inspection.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _openAllInspectionsMap() async {
    if (_filteredInspections.isEmpty) return;
    
    // Criar URL do Google Maps com múltiplos pontos
    final points = _filteredInspections.map((i) => '${i.latitude},${i.longitude}').join('|');
    final url = 'https://www.google.com/maps/dir/$points';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Color _getStatusColor(InspectionStatus status) {
    switch (status) {
      case InspectionStatus.agendada:
        return Colors.blue;
      case InspectionStatus.emAndamento:
        return Colors.orange;
      case InspectionStatus.concluida:
        return Colors.green;
      case InspectionStatus.cancelada:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(InspectionStatus status) {
    switch (status) {
      case InspectionStatus.agendada:
        return Icons.schedule;
      case InspectionStatus.emAndamento:
        return Icons.play_circle;
      case InspectionStatus.concluida:
        return Icons.check_circle;
      case InspectionStatus.cancelada:
        return Icons.cancel;
    }
  }

  String _getInspectionDisplayTitle(Inspection inspection) {
    if (inspection.establishmentId == null) {
      return inspection.titulo;
    }
    
    final establishment = _establishmentsCache[inspection.establishmentId];
    if (establishment != null) {
      return '${inspection.titulo} - ${establishment.nome}';
    }
    
    return inspection.titulo;
  }

  Widget _buildMapWidget() {
    if (_inspections.isEmpty) {
      return Container(
        height: 300,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Nenhuma inspeção encontrada'),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 400,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation ?? LatLng(
                  _inspections.first.latitude,
                  _inspections.first.longitude,
                ),
                initialZoom: 12.0,
                minZoom: 3.0,
                maxZoom: 18.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                _getTileLayer(),
                MarkerLayer(markers: _markers),
              ],
            ),
            // Controles do mapa
            Positioned(
              top: 16,
              right: 16,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    onPressed: _changeMapType,
                    tooltip: 'Trocar Layer ($_currentMapStyle)',
                    child: Icon(
                      _currentMapStyle == 'OpenStreetMap' 
                          ? Icons.map 
                          : _currentMapStyle == 'CartoDB'
                              ? Icons.terrain
                              : Icons.satellite,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    onPressed: _centerMapOnInspections,
                    tooltip: 'Centralizar nas Inspeções',
                    child: const Icon(Icons.center_focus_strong),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    onPressed: _getCurrentLocation,
                    tooltip: 'Minha Localização',
                    child: _isLoadingLocation 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                  ),
                ],
              ),
            ),
            // Botão para abrir no Google Maps
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.small(
                onPressed: _openAllInspectionsMap,
                tooltip: 'Abrir no Google Maps',
                child: const Icon(Icons.open_in_new),
              ),
            ),
            // Indicador do layer atual
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _currentMapStyle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Geográfico'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadInspections,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildMapWidget(),
              
              // Legenda
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Legenda',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildLegendItem(Colors.blue, 'Agendadas'),
                        const SizedBox(width: 20),
                        _buildLegendItem(Colors.orange, 'Em Andamento'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildLegendItem(Colors.green, 'Concluídas'),
                        const SizedBox(width: 20),
                        _buildLegendItem(Colors.red, 'Canceladas'),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Lista de Inspeções
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Inspeções (${_filteredInspections.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Theme.of(context).colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: PopupMenuButton<InspectionStatus?>(
                        onSelected: (status) => setState(() => _statusFilter = status),
                        icon: Icon(
                          Icons.filter_list,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: null,
                            child: Row(
                              children: [
                                Icon(Icons.clear_all, size: 16),
                                SizedBox(width: 8),
                                Text('Todas'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: InspectionStatus.agendada,
                            child: Row(
                              children: [
                                Icon(Icons.schedule, color: Colors.blue, size: 16),
                                const SizedBox(width: 8),
                                const Text('Agendadas'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: InspectionStatus.emAndamento,
                            child: Row(
                              children: [
                                Icon(Icons.play_circle, color: Colors.orange, size: 16),
                                const SizedBox(width: 8),
                                const Text('Em Andamento'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: InspectionStatus.concluida,
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 16),
                                const SizedBox(width: 8),
                                const Text('Concluídas'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_statusFilter != null) ...[
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(_statusFilter!.name),
                        onDeleted: () => setState(() => _statusFilter = null),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredInspections.length,
                itemBuilder: (context, index) {
                  final inspection = _filteredInspections[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(inspection.status),
                        child: Icon(
                          _getStatusIcon(inspection.status),
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      title: Text(_getInspectionDisplayTitle(inspection)),
                      subtitle: Text(inspection.endereco),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.map),
                            onPressed: () => _openMap(inspection),
                            tooltip: 'Abrir no mapa',
                          ),
                          IconButton(
                            icon: const Icon(Icons.info),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InspectionDetailScreen(inspection: inspection),
                              ),
                            ),
                            tooltip: 'Ver detalhes',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
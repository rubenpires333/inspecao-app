import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:inspecao/models/inspection.dart';
import 'package:inspecao/models/establishment.dart';
import 'package:inspecao/models/notification.dart';
import 'package:inspecao/services/data_service.dart';
import 'package:inspecao/services/database_service.dart';
import 'package:inspecao/screens/inspection_detail_screen.dart';
import 'package:inspecao/screens/notifications_screen.dart';
import 'package:intl/intl.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _dataService = DataService();
  final _dbService = DatabaseService();
  List<Inspection> _inspections = [];
  InspectionStatus? _statusFilter;
  Map<String, Establishment> _establishmentsCache = {};
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  
  // Variáveis do mapa
  MapController _mapController = MapController();
  List<Marker> _markers = [];
  String _currentMapStyle = 'OpenStreetMap';
  LatLng? _currentLocation;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadInspections(sync: false);
    _loadNotifications();
    _getCurrentLocation();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await _dataService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _notifications = [];
        });
      }
    }
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
      final establishment = _establishmentsCache[inspection.establishmentId];
      final establishmentName = establishment?.nome ?? inspection.titulo;
      
      _markers.add(
        Marker(
          point: LatLng(inspection.latitude, inspection.longitude),
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () {
              _showInspectionPopup(inspection, establishmentName);
            },
            child: Icon(
              Icons.location_on,
              color: _getStatusColor(inspection.status),
              size: 48,
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

  void _showInspectionPopup(Inspection inspection, String establishmentName) {
    final establishment = _establishmentsCache[inspection.establishmentId];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Seta apontando para baixo (conectando ao marcador)
            CustomPaint(
              size: const Size(20, 12),
              painter: _ArrowPainter(),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header com botão fechar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          inspection.titulo, // Número da inspeção
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E2E2E),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 22, color: Color(0xFF666666)),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Nome do estabelecimento
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18778A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.business, size: 18, color: Color(0xFF18778A)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            establishmentName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E2E2E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Status com badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(inspection.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStatusColor(inspection.status).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(inspection.status),
                          size: 18,
                          color: _getStatusColor(inspection.status),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Status: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          inspection.statusText,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(inspection.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Data e Hora com ícone
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 18, color: Colors.grey[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Data: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy').format(inspection.dataAgendada),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E2E2E),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.access_time, size: 18, color: Colors.grey[700]),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('HH:mm').format(inspection.dataAgendada),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E2E2E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Divisor
                  if (establishment != null && (establishment.telefone != null || establishment.email != null)) ...[
                    const SizedBox(height: 20),
                    const Divider(height: 1, thickness: 1),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.contacts, size: 20, color: Colors.grey[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Contatos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E2E2E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Contato - Nome do estabelecimento
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contato - $establishmentName',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E2E2E),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Telefone
                          if (establishment.telefone != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Tel: ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF666666),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    establishment.telefone!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2E2E2E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Email
                          if (establishment.email != null)
                            Row(
                              children: [
                                Icon(Icons.email, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                const Text(
                                  'Email: ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF666666),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    establishment.email!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2E2E2E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else
                    const SizedBox(height: 20),
                  // Botão ver detalhes
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InspectionDetailScreen(inspection: inspection),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF18778A),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Ver detalhes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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

  Future<void> _loadInspections({bool sync = false}) async {
    try {
      setState(() => _isLoading = true);
      
      List<Inspection> inspections = [];
      Map<String, Establishment> establishmentsMap = {};
      
      if (sync) {
        // Sincronizar com API quando solicitado
        inspections = await _dataService.getInspections();
        final establishments = await _dataService.getAllEstablishments();
        for (final establishment in establishments) {
          establishmentsMap[establishment.id] = establishment;
        }
      } else {
        // Carregar apenas do banco local (sem sincronizar)
        await _dbService.initialize();
        inspections = await _dbService.getInspections();
        final establishments = await _dbService.getEstablishments();
        for (final establishment in establishments) {
          establishmentsMap[establishment.id] = establishment;
        }
      }
      
      if (mounted) {
        setState(() {
          _inspections = inspections;
          _establishmentsCache = establishmentsMap;
        });
        _updateMarkers();
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _inspections = [];
          _establishmentsCache = {};
          _isLoading = false;
        });
      }
      print('Erro ao carregar inspeções: $e');
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

  Color _getStatusColor(InspectionStatus status) {
    switch (status) {
      case InspectionStatus.rascunho:
        return Colors.grey;
      case InspectionStatus.emAndamento:
        return Colors.orange;
      case InspectionStatus.concluida:
        return Colors.blue;
      case InspectionStatus.sincronizada:
        return Colors.cyan;
      case InspectionStatus.porVerificar:
        return Colors.amber;
      case InspectionStatus.verificada:
        return Colors.lightBlue;
      case InspectionStatus.invalida:
        return Colors.red;
      case InspectionStatus.relatorioGerado:
        return Colors.purple;
      case InspectionStatus.parecerDdrsDdrf:
        return Colors.indigo;
      case InspectionStatus.assinaturaCa:
        return Colors.teal;
      case InspectionStatus.finalizada:
        return Colors.green;
      case InspectionStatus.disponibilizada:
        return Colors.lightGreen;
    }
  }

  IconData _getStatusIcon(InspectionStatus status) {
    switch (status) {
      case InspectionStatus.rascunho:
        return Icons.edit;
      case InspectionStatus.emAndamento:
        return Icons.access_time;
      case InspectionStatus.concluida:
        return Icons.check_circle;
      case InspectionStatus.sincronizada:
        return Icons.sync;
      case InspectionStatus.porVerificar:
        return Icons.visibility;
      case InspectionStatus.verificada:
        return Icons.verified;
      case InspectionStatus.invalida:
        return Icons.cancel;
      case InspectionStatus.relatorioGerado:
        return Icons.description;
      case InspectionStatus.parecerDdrsDdrf:
        return Icons.gavel;
      case InspectionStatus.assinaturaCa:
        return Icons.verified_user;
      case InspectionStatus.finalizada:
        return Icons.check_circle_outline;
      case InspectionStatus.disponibilizada:
        return Icons.public;
    }
  }

  void _showFilterMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtrar por Status',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E2E2E),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFilterOption(null, 'Todas'),
                  _buildFilterOption(InspectionStatus.rascunho, 'Rascunho'),
                  _buildFilterOption(InspectionStatus.emAndamento, 'Em Andamento'),
                  _buildFilterOption(InspectionStatus.concluida, 'Concluídas'),
                  _buildFilterOption(InspectionStatus.finalizada, 'Finalizadas'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(InspectionStatus? status, String label) {
    final isSelected = _statusFilter == status;
    return ListTile(
      leading: Icon(
        status == null ? Icons.clear_all : _getStatusIcon(status),
        color: isSelected ? const Color(0xFF18778A) : Colors.grey[600],
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? const Color(0xFF18778A) : const Color(0xFF2E2E2E),
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: Color(0xFF18778A))
          : null,
      onTap: () {
        setState(() {
          _statusFilter = status;
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem(Colors.grey, 'Rascunho'),
          _buildLegendItem(Colors.orange, 'Em Andamento'),
          _buildLegendItem(Colors.blue, 'Concluídas'),
          _buildLegendItem(Colors.green, 'Finalizadas'),
          _buildLegendItem(Colors.red, 'Inválidas'),
        ],
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
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  Widget _buildMapHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF18778A),
            Color(0xFF18778A),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // App Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo e nome
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'web/icons/icon-192.png',
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.check_circle,
                                color: Color(0xFF18778A),
                                size: 20,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Mapa',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Ícones de ação compactos
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NotificationsScreen(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                            ),
                          ),
                          if (_notifications.where((n) => !n.isRead).isNotEmpty)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '${_notifications.where((n) => !n.isRead).length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      IconButton(
                        icon: _isLoading 
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _isLoading ? null : () async {
                          setState(() {
                            _isLoading = true;
                          });
                          
                          try {
                            await _loadInspections(sync: true);
                            await _loadNotifications();
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          } catch (e) {
                            await _loadInspections(sync: false);
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                      ),
                      GestureDetector(
                        onTap: _showFilterMenu,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.tune, color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F0E9),
      body: Column(
        children: [
          // Header fixo
          _buildMapHeader(),
          // Legenda
          _buildLegend(),
          // Mapa expandido
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadInspections(sync: true),
              child: _inspections.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma inspeção encontrada',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Stack(
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
                                backgroundColor: Colors.white,
                                child: Icon(
                                  _currentMapStyle == 'OpenStreetMap' 
                                      ? Icons.map 
                                      : _currentMapStyle == 'CartoDB'
                                          ? Icons.terrain
                                          : Icons.satellite,
                                  color: const Color(0xFF18778A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              FloatingActionButton.small(
                                onPressed: _centerMapOnInspections,
                                tooltip: 'Centralizar nas Inspeções',
                                backgroundColor: Colors.white,
                                child: const Icon(
                                  Icons.center_focus_strong,
                                  color: Color(0xFF18778A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              FloatingActionButton.small(
                                onPressed: _getCurrentLocation,
                                tooltip: 'Minha Localização',
                                backgroundColor: Colors.white,
                                child: _isLoadingLocation 
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF18778A)),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.my_location,
                                        color: Color(0xFF18778A),
                                      ),
                              ),
                            ],
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
          ),
        ],
      ),
    );
  }
}

// Classe para desenhar a seta apontando para baixo
class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = ui.Path();
    path.moveTo(size.width / 2, size.height);
    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

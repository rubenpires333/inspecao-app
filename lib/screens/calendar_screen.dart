import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:inspecao/models/inspection.dart';
import 'package:inspecao/models/establishment.dart';
import 'package:inspecao/models/notification.dart';
import 'package:inspecao/services/data_service.dart';
import 'package:inspecao/services/database_service.dart';
import 'package:inspecao/screens/inspection_detail_screen.dart';
import 'package:inspecao/screens/notifications_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _dataService = DataService();
  final _dbService = DatabaseService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Inspection> _inspections = [];
  List<Inspection> _selectedInspections = [];
  Map<String, Establishment> _establishmentsCache = {};
  List<AppNotification> _notifications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadInspections(sync: false);
    _loadNotifications();
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
      // Se não houver notificações, continuar com lista vazia
      if (mounted) {
        setState(() {
          _notifications = [];
        });
      }
    }
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
          _selectedInspections = _getInspectionsForDay(_selectedDay);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _inspections = [];
          _selectedInspections = [];
          _establishmentsCache = {};
          _isLoading = false;
        });
      }
      print('Erro ao carregar inspeções: $e');
    }
  }

  List<Inspection> _getInspectionsForDay(DateTime? day) {
    if (day == null) return [];
    
    return _inspections.where((inspection) {
      final inspectionDate = inspection.dataAgendada;
      return inspectionDate.year == day.year &&
             inspectionDate.month == day.month &&
             inspectionDate.day == day.day;
    }).toList();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedInspections = _getInspectionsForDay(selectedDay);
      });
    }
  }

  Future<void> _selectMonthYear(DateTime currentFocusedDay) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentFocusedDay,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Selecionar mês e ano',
      cancelText: 'Cancelar',
      confirmText: 'Selecionar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF18778A),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF18778A),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _focusedDay = DateTime(picked.year, picked.month, _focusedDay.day);
        // Se a data selecionada estiver no mês/ano escolhido, manter a seleção
        if (_selectedDay != null && 
            _selectedDay!.year == picked.year && 
            _selectedDay!.month == picked.month) {
          // Manter a seleção atual
        } else {
          // Selecionar o primeiro dia do mês escolhido
          _selectedDay = DateTime(picked.year, picked.month, 1);
          _selectedInspections = _getInspectionsForDay(_selectedDay);
        }
      });
    }
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

  String _getInspectionDisplayTitle(Inspection inspection) {
    final est = inspection.establishmentId != null
        ? _establishmentsCache[inspection.establishmentId]
        : null;
    return DataService.getInspectionDisplayTitle(inspection, est);
  }

  /// A API envia `dataInspecao` como data sem hora → vira `DateTime` à meia-noite local (00:00).
  String _formatInspectionTimeLabel(DateTime dataAgendada) {
    final d = dataAgendada;
    if (d.hour == 0 && d.minute == 0 && d.second == 0) {
      return 'Sem horário';
    }
    return DateFormat('HH:mm').format(d);
  }

  List<Widget> _buildEventMarkers(DateTime day) {
    final inspections = _getInspectionsForDay(day);
    if (inspections.isEmpty) return [];

    return inspections.take(3).map((inspection) {
      return Container(
        margin: const EdgeInsets.only(top: 2),
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getStatusColor(inspection.status),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F0E9),
      body: Column(
        children: [
          // Header fixo
          _buildCalendarHeader(),
          // Conteúdo com scroll
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadInspections(sync: true), // Sincronizar ao fazer pull-to-refresh
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TableCalendar<Inspection>(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      eventLoader: _getInspectionsForDay,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      calendarStyle: const CalendarStyle(
                        outsideDaysVisible: false,
                        weekendTextStyle: TextStyle(color: Colors.red),
                        holidayTextStyle: TextStyle(color: Colors.red),
                        selectedDecoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF18778A),
                        ),
                        leftChevronIcon: const Icon(
                          Icons.chevron_left,
                          color: Color(0xFF18778A),
                        ),
                        rightChevronIcon: const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF18778A),
                        ),
                      ),
                      onHeaderTapped: (focusedDay) {
                        _selectMonthYear(focusedDay);
                      },
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      onDaySelected: _onDaySelected,
                      onFormatChanged: (format) {
                        if (_calendarFormat != format) {
                          setState(() {
                            _calendarFormat = format;
                          });
                        }
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, day, events) {
                          final markers = _buildEventMarkers(day);
                          return markers.isNotEmpty
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: markers,
                                )
                              : null;
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Lista de inspeções para a data selecionada
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: _selectedInspections.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_note,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Nenhuma inspeção agendada',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _selectedDay != null
                                        ? 'para ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}'
                                        : '',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _selectedInspections.length,
                              itemBuilder: (context, index) {
                                final inspection = _selectedInspections[index];
                                return _buildInspectionCard(inspection);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionCard(Inspection inspection) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InspectionDetailScreen(inspection: inspection),
            ),
          );
          _loadInspections(sync: false);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getInspectionDisplayTitle(inspection),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E2E2E),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      inspection.endereco.isNotEmpty
                          ? inspection.endereco
                          : 'Endereço não informado',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Data, hora (ou "Sem horário") e status na mesma linha
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(inspection.dataAgendada),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatInspectionTimeLabel(inspection.dataAgendada),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (!inspection.isSynced) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Não sincronizada',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(inspection.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(inspection.status),
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          inspection.statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  Widget _buildCalendarHeader() {
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
                        'Calendário',
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
                      IconButton(
                        icon: Icon(_calendarFormat == CalendarFormat.month 
                            ? Icons.view_week 
                            : Icons.calendar_month),
                        color: Colors.white,
                        onPressed: () {
                          setState(() {
                            _calendarFormat = _calendarFormat == CalendarFormat.month
                                ? CalendarFormat.week
                                : CalendarFormat.month;
                          });
                        },
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
}
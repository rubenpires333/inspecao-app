import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:inspecao/models/inspection.dart';
import 'package:inspecao/models/establishment.dart';
import 'package:inspecao/services/data_service.dart';
import 'package:inspecao/screens/inspection_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _dataService = DataService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Inspection> _inspections = [];
  List<Inspection> _selectedInspections = [];
  Map<String, Establishment> _establishmentsCache = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadInspections();
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
        _selectedInspections = _getInspectionsForDay(_selectedDay);
      });
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
    if (inspection.establishmentId == null) {
      return inspection.titulo;
    }
    
    final establishment = _establishmentsCache[inspection.establishmentId];
    if (establishment != null) {
      return '${inspection.titulo} - ${establishment.nome}';
    }
    
    return inspection.titulo;
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
      appBar: AppBar(
        title: const Text('Calendário'),
        actions: [
          IconButton(
            icon: Icon(_calendarFormat == CalendarFormat.month 
                ? Icons.view_week 
                : Icons.calendar_month),
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
      body: RefreshIndicator(
        onRefresh: _loadInspections,
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
                  color: Colors.deepOrange,
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
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
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
            Expanded(
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
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(inspection.status),
                              child: Text(
                                DateFormat('HH:mm').format(inspection.dataAgendada).substring(0, 2),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            title: Text(
                              _getInspectionDisplayTitle(inspection),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(inspection.endereco),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat('HH:mm').format(inspection.dataAgendada),
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(Icons.people, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${inspection.equipe.length} inspector(es)',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(inspection.status),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                inspection.statusText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => InspectionDetailScreen(inspection: inspection),
                                ),
                              );
                              _loadInspections();
                            },
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
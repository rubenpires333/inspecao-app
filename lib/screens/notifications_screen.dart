import 'package:flutter/material.dart';
import 'package:inspecao/models/notification.dart';
import 'package:inspecao/services/data_service.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _dataService = DataService();
  List<AppNotification> _notifications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final notifications = await _dataService.getNotifications();
    if (mounted) {
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    }
  }


  Future<void> _refreshNotifications() async {
    setState(() => _isLoading = true);
    
    try {
      // Aguardar um pouco para mostrar o loading
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Recarregar a tela completamente
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationsScreen(),
          ),
        );
      }
    } catch (e) {
      // Em caso de erro, apenas recarregar dados
      await _loadNotifications();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationDate = DateTime(date.year, date.month, date.day);
    
    if (notificationDate == today) {
      return 'Today';
    } else if (notificationDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('d MMM yyyy').format(date);
    }
  }

  String _formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
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
              const Expanded(
                child: Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Refresh button
              GestureDetector(
                onTap: _refreshNotifications,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: _isLoading 
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.refresh, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 8),
              // More options button
              GestureDetector(
                onTap: () {
                  // Show options menu
                  _showOptionsMenu();
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

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mark_email_read),
              title: const Text('Mark all as read'),
              onTap: () {
                Navigator.pop(context);
                _markAllAsRead();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Clear all notifications'),
              onTap: () {
                Navigator.pop(context);
                _clearAllNotifications();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAllAsRead() async {
    for (final notification in _notifications) {
      if (!notification.isRead) {
        await _dataService.markNotificationAsRead(notification.id);
      }
    }
    _loadNotifications();
  }

  Future<void> _clearAllNotifications() async {
    // Implementar limpeza de todas as notificações
    _loadNotifications();
  }

  Widget _buildNotificationsList() {
    if (_isLoading && _notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // Agrupar notificações por data
    final groupedNotifications = <String, List<AppNotification>>{};
    for (final notification in _notifications) {
      final dateKey = _formatDate(notification.createdAt);
      groupedNotifications.putIfAbsent(dateKey, () => []).add(notification);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedNotifications.length,
      itemBuilder: (context, index) {
        final dateKey = groupedNotifications.keys.elementAt(index);
        final notifications = groupedNotifications[dateKey]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 8),
              child: Text(
                dateKey,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E2E2E),
                ),
              ),
            ),
            // Notifications for this date
            ...notifications.map((notification) => _buildNotificationItem(notification)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildNotificationItem(AppNotification notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status dot
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: BoxDecoration(
              color: notification.isRead ? Colors.grey[400] : const Color(0xFF1976D2),
              shape: BoxShape.circle,
            ),
          ),
          // Notification content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  notification.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: notification.isRead ? Colors.grey[600] : const Color(0xFF2E2E2E),
                  ),
                ),
                const SizedBox(height: 4),
                // Message
                Text(
                  notification.message,
                  style: TextStyle(
                    fontSize: 14,
                    color: notification.isRead ? Colors.grey[500] : const Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          // Time
          Text(
            _formatTime(notification.createdAt),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
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
          Expanded(
            child: _buildNotificationsList(),
          ),
        ],
      ),
    );
  }
}

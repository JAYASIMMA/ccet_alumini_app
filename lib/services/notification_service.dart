import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:ccet_alumini_app/services/api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  late IO.Socket socket;

  Future<void> init() async {
    // Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Initialize Socket.IO
    _connectSocket();
  }

  void _connectSocket() {
    // Parse base URL to get correct host
    // ApiService.baseUrl is like 'http://192.168.1.33:3000/api'
    // We need 'http://192.168.1.33:3000'
    final uri = Uri.parse(ApiService.baseUrl);
    final socketUrl = '${uri.scheme}://${uri.host}:${uri.port}';

    print('Connecting to Socket.IO at $socketUrl');

    socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      print('Socket Connected');
    });

    socket.onDisconnect((_) {
      print('Socket Disconnected');
    });

    socket.on('new_job', (data) {
      print('New Job Received: $data');
      _showNotification(
        id: 1,
        title: 'New Job Alert!',
        body: 'New job posted: ${data['title']} at ${data['company']}',
      );
    });

    socket.on('new_event', (data) {
      print('New Event Received: $data');
      _showNotification(
        id: 2,
        title: 'New Event Alert!',
        body: 'New event: ${data['title']} on ${data['date']}',
      );
    });
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'ccet_channel_id',
          'CCET Alumni Updates',
          channelDescription: 'Notifications for new jobs and events',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}

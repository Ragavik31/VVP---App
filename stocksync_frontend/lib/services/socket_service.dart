import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;

  String _buildUrl() {
    // Mirror ApiClient logic for emulator
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://localhost:5000';
  }

  void connect({required String token}) {
    final url = _buildUrl();
    socket = IO.io(url, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'extraHeaders': {'Authorization': 'Bearer $token'},
    });

    socket?.on('connect', (_) {
      debugPrint('Socket connected: \\${socket?.id}');
    });

    socket?.on('disconnect', (_) {
      debugPrint('Socket disconnected');
    });

    socket?.connect();
  }

  void on(String event, Function(dynamic) handler) {
    socket?.on(event, (data) => handler(data));
  }

  void off(String event) {
    socket?.off(event);
  }

  void dispose() {
    socket?.disconnect();
    socket = null;
  }
}

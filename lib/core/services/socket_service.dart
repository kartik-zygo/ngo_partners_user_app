import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/app_constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;

  final StreamController<Map<String, dynamic>> _callStatusController =
      StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  final StreamController<Map<String, dynamic>> _paymentApprovedController =
      StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<Map<String, dynamic>> _paymentRejectedController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Emits whenever the server pushes a `call:status-changed` event.
  Stream<Map<String, dynamic>> get callStatusStream =>
      _callStatusController.stream;

  /// Emits `true` on connect / reconnect, `false` on disconnect / error.
  Stream<bool> get connectionStream => _connectionController.stream;

  Stream<Map<String, dynamic>> get paymentApprovedStream =>
      _paymentApprovedController.stream;

  Stream<Map<String, dynamic>> get paymentRejectedStream =>
      _paymentRejectedController.stream;

  bool get isConnected => _socket?.connected ?? false;

  /// Call once after login (or after token refresh) to establish the
  /// Socket.io connection with the user's JWT access token.
  void connect(String accessToken) {
    _socket?.disconnect();

    _socket = io.io(
      AppConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setPath('/socket.io')
          .setAuth({'token': accessToken})
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(99999)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[Socket] Connected to ${AppConstants.socketUrl}');
      _connectionController.add(true);
    });

    _socket!.onConnectError((err) {
      debugPrint('[Socket] Connect error: $err');
      _connectionController.add(false);
    });

    _socket!.onDisconnect((reason) {
      debugPrint('[Socket] Disconnected: $reason');
      _connectionController.add(false);
    });

    _socket!.on('connect_error', (err) {
      debugPrint('[Socket] connect_error: $err');
    });

    _socket!.on('call:status-changed', (data) {
      debugPrint('[Socket] call:status-changed raw: $data');
      final map = _toMap(data);
      if (map != null) {
        debugPrint('[Socket] call:status-changed parsed: $map');
        _callStatusController.add(map);
      } else {
        debugPrint('[Socket] call:status-changed: unrecognised payload format');
      }
    });

    _socket!.on('order:paymentApproved', (data) {
      final map = _toMap(data);
      if (map != null) _paymentApprovedController.add(map);
    });

    _socket!.on('order:paymentRejected', (data) {
      final map = _toMap(data);
      if (map != null) _paymentRejectedController.add(map);
    });

    _socket!.connect();
  }

  // Safely converts socket.io event data to a typed map.
  // socket_io_client can deliver the payload as:
  //   - Map<String, dynamic>  — direct object
  //   - Map (other type)      — needs re-typing
  //   - List                  — package wraps single-arg payloads in a list
  Map<String, dynamic>? _toMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List && data.isNotEmpty) {
      final first = data[0];
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    return null;
  }

  /// Call on logout. Disconnects and clears the socket.
  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  /// Emit after `POST /support-calls` returns — joins the call room so the
  /// server can push call-room-scoped events for this call.
  void joinCall(String callId) {
    debugPrint('[Socket] Emitting call:join for $callId');
    _socket?.emit('call:join', callId);
  }

  /// Emit when the call ends or is rejected.
  void leaveCall(String callId) {
    debugPrint('[Socket] Emitting call:leave for $callId');
    _socket?.emit('call:leave', callId);
  }
}

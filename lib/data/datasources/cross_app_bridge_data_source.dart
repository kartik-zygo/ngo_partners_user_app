import 'dart:convert';
import 'dart:io';

class UserBridgeCallRequest {
  const UserBridgeCallRequest({
    required this.id,
    required this.status,
    required this.callType,
    required this.targetTeam,
    required this.createdAt,
    required this.updatedAt,
    this.salesAgentName,
  });

  final String id;
  final String status;
  final String callType;
  final String targetTeam;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? salesAgentName;

  factory UserBridgeCallRequest.fromJson(Map<String, dynamic> json) {
    return UserBridgeCallRequest(
      id: json['id'] as String,
      status: json['status'] as String? ?? 'ringing',
      callType: json['callType'] as String? ?? 'voice',
      targetTeam: json['targetTeam'] as String? ?? 'support',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      salesAgentName: json['salesAgentName'] as String?,
    );
  }
}

class CrossAppBridgeDataSource {
  static const _fileName = 'ngo_partner_cross_app_bridge.json';

  Future<String> submitLeadRequest({
    required String userId,
    required String userName,
    required String userEmail,
    required String userPhone,
    required String organization,
    required String serviceId,
    required String serviceName,
    String? message,
  }) async {
    final store = await _readStore();
    final requestId = 'lead_req_${DateTime.now().microsecondsSinceEpoch}';

    final requests = (store['leadRequests'] as List<dynamic>? ?? <dynamic>[])
      ..add({
        'id': requestId,
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'userPhone': userPhone,
        'organization': organization,
        'serviceId': serviceId,
        'serviceName': serviceName,
        'message': message,
        'createdAt': DateTime.now().toIso8601String(),
        'processed': false,
        'processedAt': null,
      });

    store['leadRequests'] = requests;
    await _writeStore(store);
    return requestId;
  }

  Future<String> createCallRequest({
    required String userId,
    required String userName,
    required String userEmail,
    required String userPhone,
    required String organization,
    required String targetTeam,
    required String callType,
    String? message,
  }) async {
    final store = await _readStore();
    final callId = 'call_${DateTime.now().microsecondsSinceEpoch}';

    final calls = (store['callRequests'] as List<dynamic>? ?? <dynamic>[])
      ..add({
        'id': callId,
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'userPhone': userPhone,
        'organization': organization,
        'targetTeam': targetTeam,
        'callType': callType,
        'status': 'ringing',
        'message': message,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'salesAgentId': null,
        'salesAgentName': null,
      });

    store['callRequests'] = calls;
    await _writeStore(store);
    return callId;
  }

  Future<UserBridgeCallRequest?> getCallRequestById(String callId) async {
    final store = await _readStore();
    final raw = (store['callRequests'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .firstWhere(
          (item) => item['id'] == callId,
          orElse: () => <String, dynamic>{},
        );

    if (raw.isEmpty) {
      return null;
    }
    return UserBridgeCallRequest.fromJson(raw);
  }

  Future<void> updateCallStatus({
    required String callId,
    required String status,
  }) async {
    final store = await _readStore();
    final raw = (store['callRequests'] as List<dynamic>? ?? const []);

    final updated = raw
        .whereType<Map<String, dynamic>>()
        .map((item) {
          if (item['id'] != callId) {
            return item;
          }
          return {
            ...item,
            'status': status,
            'updatedAt': DateTime.now().toIso8601String(),
          };
        })
        .toList();

    store['callRequests'] = updated;
    await _writeStore(store);
  }

  Future<Map<String, dynamic>> _readStore() async {
    final file = await _storeFile();
    if (!file.existsSync()) {
      return _emptyStore();
    }

    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return _emptyStore();
      }

      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) {
        return {
          'leadRequests': decoded['leadRequests'] is List ? decoded['leadRequests'] : <dynamic>[],
          'callRequests': decoded['callRequests'] is List ? decoded['callRequests'] : <dynamic>[],
        };
      }
      return _emptyStore();
    } catch (_) {
      return _emptyStore();
    }
  }

  Future<void> _writeStore(Map<String, dynamic> store) async {
    final file = await _storeFile();
    await file.writeAsString(jsonEncode(store), flush: true);
  }

  Future<File> _storeFile() async {
    final path = '${Directory.systemTemp.path}${Platform.pathSeparator}$_fileName';
    final file = File(path);
    if (!file.existsSync()) {
      await file.writeAsString(jsonEncode(_emptyStore()), flush: true);
    }
    return file;
  }

  Map<String, dynamic> _emptyStore() {
    return {
      'leadRequests': <dynamic>[],
      'callRequests': <dynamic>[],
    };
  }
}

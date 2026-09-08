import 'package:equatable/equatable.dart';

enum CallStatus { ringing, accepted, rejected, ended }

enum CallType { voice, video }

class SupportCallEntity extends Equatable {
  final String id;
  final CallType callType;
  final String targetTeam;
  final CallStatus status;
  final DateTime? createdAt;

  const SupportCallEntity({
    required this.id,
    required this.callType,
    required this.targetTeam,
    required this.status,
    this.createdAt,
  });

  factory SupportCallEntity.fromJson(Map<String, dynamic> json) {
    return SupportCallEntity(
      id: json['id'] as String? ?? '',
      callType: (json['callType'] as String?) == 'video'
          ? CallType.video
          : CallType.voice,
      targetTeam: json['targetTeam'] as String? ?? 'support',
      status: _parseStatus(json['status'] as String?),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  static CallStatus _parseStatus(String? raw) {
    switch (raw) {
      case 'accepted':
        return CallStatus.accepted;
      case 'rejected':
        return CallStatus.rejected;
      case 'ended':
        return CallStatus.ended;
      default:
        return CallStatus.ringing;
    }
  }

  @override
  List<Object?> get props => [id, callType, status];
}

class AgoraTokenEntity extends Equatable {
  final String token;
  final String channelName;
  final int uid;
  final String appId;
  final String callType;
  final int expiresInSeconds;

  const AgoraTokenEntity({
    required this.token,
    required this.channelName,
    required this.uid,
    required this.appId,
    required this.callType,
    required this.expiresInSeconds,
  });

  factory AgoraTokenEntity.fromJson(Map<String, dynamic> json) {
    return AgoraTokenEntity(
      token: json['token'] as String? ?? '',
      channelName: json['channelName'] as String? ?? '',
      uid: (json['uid'] as num?)?.toInt() ?? 0,
      appId: json['appId'] as String? ?? '',
      callType: json['callType'] as String? ?? 'voice',
      expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt() ?? 3600,
    );
  }

  @override
  List<Object?> get props => [token, channelName, uid];
}

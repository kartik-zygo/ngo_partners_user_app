import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  final String id;
  final String title;
  final String text;
  final String timeAgo;
  final bool isRead;
  final String? type;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.text,
    required this.timeAgo,
    this.isRead = false,
    this.type,
  });

  factory NotificationEntity.fromJson(Map<String, dynamic> json) {
    return NotificationEntity(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      text: json['body'] as String? ?? json['message'] as String? ?? json['text'] as String? ?? '',
      timeAgo: _formatTimeAgo(json['created_at'] as String? ?? json['createdAt'] as String?),
      isRead: json['is_read'] as bool? ?? json['isRead'] as bool? ?? false,
      type: json['notification_type'] as String? ?? json['type'] as String?,
    );
  }

  static String _formatTimeAgo(String? isoString) {
    if (isoString == null) return '';
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  NotificationEntity copyWith({bool? isRead}) => NotificationEntity(
        id: id,
        title: title,
        text: text,
        timeAgo: timeAgo,
        isRead: isRead ?? this.isRead,
        type: type,
      );

  @override
  List<Object?> get props => [id, title, text, isRead];
}

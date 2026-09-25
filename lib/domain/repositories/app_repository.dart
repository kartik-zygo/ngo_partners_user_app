import '../entities/case_entity.dart';
import '../entities/collaboration_entity.dart';
import '../entities/community_entity.dart';
import '../entities/notification_entity.dart';
import '../entities/order_entity.dart';
import '../entities/quotation_entity.dart';
import '../entities/service_entity.dart';
import '../entities/support_call_entity.dart';
import '../entities/ticket_entity.dart';

abstract class AppRepository {
  // Services
  Future<List<ServiceEntity>> getServices();
  Future<ServiceEntity> getServiceById(String id);

  // Cases
  Future<List<CaseEntity>> getCases(String userId);
  Future<CaseEntity> purchaseService({
    required String userId,
    required ServiceEntity service,
  });
  Future<void> uploadDocument({
    required String caseId,
    required String docName,
    required String filePath,
  });
  Future<void> resubmitDocuments({
    required String caseId,
    required String requestId,
    required List<Map<String, dynamic>> documents,
  });

  // Collaborations
  Future<List<CollaborationEntity>> getCollaborations();
  Future<CollaborationEntity> requestCollaboration({
    required String ngoName,
    required CollabType type,
    required String about,
  });

  // Notifications
  Future<List<NotificationEntity>> getNotifications(String userId);
  Future<void> markNotificationRead(String notificationId);
  Future<void> markAllNotificationsRead();

  // Tickets
  Future<List<TicketEntity>> getTickets(String userId);
  Future<TicketEntity> createTicket({
    required String userId,
    required String subject,
    required String description,
    required TicketPriority priority,
    String? caseId,
  });
  Future<void> addTicketReply({
    required String ticketId,
    required String message,
  });
  Future<TicketEntity> getTicketById(String id);

  // Support Calls
  Future<SupportCallEntity> initiateCall({
    required String callType,
    required String targetTeam,
  });
  Future<SupportCallEntity> getCallStatus(String callId);
  Future<AgoraTokenEntity> getAgoraToken(String callId);
  Future<void> updateCallStatus({
    required String callId,
    required String status,
  });

  // Orders — legacy, read-only since the quotation cutover
  Future<List<OrderEntity>> getOrders({String? status});
  Future<OrderEntity> getOrder(String orderId);
  Future<OrderEntity> cancelOrder(String orderId, {String? reason});

  // Quotations
  Future<QuotationEntity> createQuotation({
    required String serviceId,
    required String name,
    required String email,
    required String phone,
    String? organizationName,
    String? message,
  });
  Future<List<QuotationEntity>> getQuotations({
    String? status,
    int page,
    int limit,
  });
  Future<QuotationEntity> getQuotationById(String id);

  // Community Hub
  Future<CommunityFeed> getCommunityPosts({
    int page,
    int limit,
    String sort,
    String? tag,
    String? search,
    String? postType,
  });
  Future<CommunityPost> getCommunityPost(String id);
  Future<CommunityPost> createCommunityPost({
    required String title,
    required String body,
    required String postType,
    required List<String> tags,
  });
  Future<CommunityAnswer> addCommunityAnswer({
    required String postId,
    required String body,
  });
  Future<CommunityVoteResult> voteCommunityPost({
    required String postId,
    required int value,
  });
  Future<CommunityVoteResult> voteCommunityAnswer({
    required String answerId,
    required int value,
  });
  Future<CommunityPost> acceptCommunityAnswer({
    required String postId,
    required String answerId,
  });
  Future<void> deleteCommunityPost(String postId);
  Future<void> deleteCommunityAnswer(String answerId);
  Future<List<CommunityTag>> getCommunityTags();
  Future<void> reportCommunityContent({
    required CommunityReportTarget target,
    required CommunityReportReason reason,
    String? details,
    bool blockAuthor,
  });
}

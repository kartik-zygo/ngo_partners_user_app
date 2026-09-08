import 'dart:io';

import 'package:mime/mime.dart';

import '../../domain/entities/case_entity.dart';
import '../../domain/entities/collaboration_entity.dart';
import '../../domain/entities/community_entity.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/entities/support_call_entity.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/repositories/app_repository.dart';
import '../datasources/remote_data_source.dart';

class AppRepositoryImpl implements AppRepository {
  final RemoteDataSource _remote;
  AppRepositoryImpl(this._remote);

  // ── Services ────────────────────────────────────────────────────────────

  @override
  Future<List<ServiceEntity>> getServices() => _remote.getServices();

  @override
  Future<ServiceEntity> getServiceById(String id) =>
      _remote.getServiceById(id);

  // ── Cases ────────────────────────────────────────────────────────────────

  @override
  Future<List<CaseEntity>> getCases(String userId) => _remote.getCases();

  @override
  Future<CaseEntity> purchaseService({
    required String userId,
    required ServiceEntity service,
  }) =>
      _remote.createCase(
        userId: userId,
        serviceId: service.id,
        notes: '',
      );

  @override
  Future<void> uploadDocument({
    required String caseId,
    required String docName,
    required String filePath,
  }) async {
    final file = File(filePath);
    final fileSizeBytes = await file.length();
    final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';
    return _remote.uploadDocumentToCase(
      caseId: caseId,
      docName: docName,
      filePath: filePath,
      mimeType: mimeType,
      fileSizeBytes: fileSizeBytes,
    );
  }

  @override
  Future<void> resubmitDocuments({
    required String caseId,
    required String requestId,
    required List<Map<String, dynamic>> documents,
  }) =>
      _remote.resubmitDocuments(
          caseId: caseId, requestId: requestId, documents: documents);

  // ── Collaborations ────────────────────────────────────────────────────────

  @override
  Future<List<CollaborationEntity>> getCollaborations() =>
      _remote.getCollaborations();

  @override
  Future<CollaborationEntity> requestCollaboration({
    required String ngoName,
    required CollabType type,
    required String about,
  }) =>
      _remote.requestCollaboration(type: type, proposal: about);

  // ── Notifications ─────────────────────────────────────────────────────────

  @override
  Future<List<NotificationEntity>> getNotifications(String userId) =>
      _remote.getNotifications();

  @override
  Future<void> markNotificationRead(String notificationId) =>
      _remote.markNotificationRead(notificationId);

  @override
  Future<void> markAllNotificationsRead() =>
      _remote.markAllNotificationsRead();

  // ── Tickets ───────────────────────────────────────────────────────────────

  @override
  Future<List<TicketEntity>> getTickets(String userId) =>
      _remote.getTickets();

  @override
  Future<TicketEntity> createTicket({
    required String userId,
    required String subject,
    required String description,
    required TicketPriority priority,
    String? caseId,
  }) =>
      _remote.createTicket(
        subject: subject,
        description: description,
        priority: priority,
        caseId: caseId,
      );

  @override
  Future<void> addTicketReply({
    required String ticketId,
    required String message,
  }) =>
      _remote.addTicketReply(ticketId: ticketId, message: message);

  @override
  Future<TicketEntity> getTicketById(String id) =>
      _remote.getTicketById(id);

  // ── Support Calls ─────────────────────────────────────────────────────────

  @override
  Future<SupportCallEntity> initiateCall({
    required String callType,
    required String targetTeam,
  }) =>
      _remote.initiateCall(callType: callType, targetTeam: targetTeam);

  @override
  Future<SupportCallEntity> getCallStatus(String callId) =>
      _remote.getCallStatus(callId);

  @override
  Future<AgoraTokenEntity> getAgoraToken(String callId) =>
      _remote.getAgoraToken(callId);

  @override
  Future<void> updateCallStatus({
    required String callId,
    required String status,
  }) =>
      _remote.updateCallStatus(callId: callId, status: status);

  // ── Orders ───────────────────────────────────────────────────────────────

  @override
  Future<List<OrderEntity>> getOrders({String? status}) =>
      _remote.getOrders(status: status);

  @override
  Future<OrderEntity> createOrder({
    required String serviceId,
    String? customerPhone,
    String? notes,
  }) =>
      _remote.createOrder(
          serviceId: serviceId, customerPhone: customerPhone, notes: notes);

  @override
  Future<OrderEntity> getOrder(String orderId) => _remote.getOrder(orderId);

  @override
  Future<PaymentInstructions> getPaymentInstructions() =>
      _remote.getPaymentInstructions();

  @override
  Future<PaymentRequestEntity> submitPaymentRequest({
    required String orderId,
    required String paymentMethod,
    required String referenceNumber,
    required double amountPaid,
    DateTime? paidAt,
    String? payerName,
    String? payerNote,
    String? proofFilePath,
  }) =>
      _remote.submitPaymentRequest(
        orderId: orderId,
        paymentMethod: paymentMethod,
        referenceNumber: referenceNumber,
        amountPaid: amountPaid,
        paidAt: paidAt,
        payerName: payerName,
        payerNote: payerNote,
        proofFilePath: proofFilePath,
      );

  @override
  Future<PaymentRequestEntity> getPaymentRequest(String requestId) =>
      _remote.getPaymentRequest(requestId);

  @override
  Future<OrderEntity> cancelOrder(String orderId, {String? reason}) =>
      _remote.cancelOrder(orderId, reason: reason);

  // ── Community Hub ──────────────────────────────────────────────────────────

  @override
  Future<CommunityFeed> getCommunityPosts({
    int page = 1,
    int limit = 20,
    String sort = 'newest',
    String? tag,
    String? search,
    String? postType,
  }) =>
      _remote.getCommunityPosts(
        page: page,
        limit: limit,
        sort: sort,
        tag: tag,
        search: search,
        postType: postType,
      );

  @override
  Future<CommunityPost> getCommunityPost(String id) =>
      _remote.getCommunityPost(id);

  @override
  Future<CommunityPost> createCommunityPost({
    required String title,
    required String body,
    required String postType,
    required List<String> tags,
  }) =>
      _remote.createCommunityPost(
          title: title, body: body, postType: postType, tags: tags);

  @override
  Future<CommunityAnswer> addCommunityAnswer({
    required String postId,
    required String body,
  }) =>
      _remote.addCommunityAnswer(postId: postId, body: body);

  @override
  Future<CommunityVoteResult> voteCommunityPost({
    required String postId,
    required int value,
  }) =>
      _remote.voteCommunityPost(postId: postId, value: value);

  @override
  Future<CommunityVoteResult> voteCommunityAnswer({
    required String answerId,
    required int value,
  }) =>
      _remote.voteCommunityAnswer(answerId: answerId, value: value);

  @override
  Future<CommunityPost> acceptCommunityAnswer({
    required String postId,
    required String answerId,
  }) =>
      _remote.acceptCommunityAnswer(postId: postId, answerId: answerId);

  @override
  Future<void> deleteCommunityPost(String postId) =>
      _remote.deleteCommunityPost(postId);

  @override
  Future<void> deleteCommunityAnswer(String answerId) =>
      _remote.deleteCommunityAnswer(answerId);

  @override
  Future<List<CommunityTag>> getCommunityTags() => _remote.getCommunityTags();
}

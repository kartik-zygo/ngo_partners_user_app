import '../entities/case_entity.dart';
import '../entities/collaboration_entity.dart';
import '../entities/community_entity.dart';
import '../entities/notification_entity.dart';
import '../entities/order_entity.dart';
import '../entities/payment_entity.dart';
import '../entities/service_entity.dart';
import '../entities/support_call_entity.dart';
import '../entities/ticket_entity.dart';
import '../repositories/app_repository.dart';

// ── Services ──────────────────────────────────────────────────────────────────

class GetServicesUseCase {
  final AppRepository _repo;
  GetServicesUseCase(this._repo);
  Future<List<ServiceEntity>> call() => _repo.getServices();
}

class GetServiceByIdUseCase {
  final AppRepository _repo;
  GetServiceByIdUseCase(this._repo);
  Future<ServiceEntity> call(String id) => _repo.getServiceById(id);
}

// ── Cases ─────────────────────────────────────────────────────────────────────

class GetCasesUseCase {
  final AppRepository _repo;
  GetCasesUseCase(this._repo);
  Future<List<CaseEntity>> call(String userId) => _repo.getCases(userId);
}

class PurchaseServiceUseCase {
  final AppRepository _repo;
  PurchaseServiceUseCase(this._repo);
  Future<CaseEntity> call({
    required String userId,
    required ServiceEntity service,
  }) =>
      _repo.purchaseService(userId: userId, service: service);
}

class UploadDocumentUseCase {
  final AppRepository _repo;
  UploadDocumentUseCase(this._repo);
  Future<void> call({
    required String caseId,
    required String docName,
    required String filePath,
  }) =>
      _repo.uploadDocument(caseId: caseId, docName: docName, filePath: filePath);
}

class ResubmitDocumentsUseCase {
  final AppRepository _repo;
  ResubmitDocumentsUseCase(this._repo);
  Future<void> call({
    required String caseId,
    required String requestId,
    required List<Map<String, dynamic>> documents,
  }) =>
      _repo.resubmitDocuments(
          caseId: caseId, requestId: requestId, documents: documents);
}

// ── Collaborations ────────────────────────────────────────────────────────────

class GetCollaborationsUseCase {
  final AppRepository _repo;
  GetCollaborationsUseCase(this._repo);
  Future<List<CollaborationEntity>> call() => _repo.getCollaborations();
}

class RequestCollaborationUseCase {
  final AppRepository _repo;
  RequestCollaborationUseCase(this._repo);
  Future<CollaborationEntity> call({
    required String ngoName,
    required CollabType type,
    required String about,
  }) =>
      _repo.requestCollaboration(ngoName: ngoName, type: type, about: about);
}

// ── Notifications ─────────────────────────────────────────────────────────────

class GetNotificationsUseCase {
  final AppRepository _repo;
  GetNotificationsUseCase(this._repo);
  Future<List<NotificationEntity>> call(String userId) =>
      _repo.getNotifications(userId);
}

class MarkNotificationReadUseCase {
  final AppRepository _repo;
  MarkNotificationReadUseCase(this._repo);
  Future<void> call(String id) => _repo.markNotificationRead(id);
}

class MarkAllNotificationsReadUseCase {
  final AppRepository _repo;
  MarkAllNotificationsReadUseCase(this._repo);
  Future<void> call() => _repo.markAllNotificationsRead();
}

// ── Tickets ───────────────────────────────────────────────────────────────────

class GetTicketsUseCase {
  final AppRepository _repo;
  GetTicketsUseCase(this._repo);
  Future<List<TicketEntity>> call(String userId) => _repo.getTickets(userId);
}

class CreateTicketUseCase {
  final AppRepository _repo;
  CreateTicketUseCase(this._repo);
  Future<TicketEntity> call({
    required String userId,
    required String subject,
    required String description,
    required TicketPriority priority,
    String? caseId,
  }) =>
      _repo.createTicket(
        userId: userId,
        subject: subject,
        description: description,
        priority: priority,
        caseId: caseId,
      );
}

class AddTicketReplyUseCase {
  final AppRepository _repo;
  AddTicketReplyUseCase(this._repo);
  Future<void> call({
    required String ticketId,
    required String message,
  }) =>
      _repo.addTicketReply(ticketId: ticketId, message: message);
}

class GetTicketByIdUseCase {
  final AppRepository _repo;
  GetTicketByIdUseCase(this._repo);
  Future<TicketEntity> call(String id) => _repo.getTicketById(id);
}

// ── Support Calls ─────────────────────────────────────────────────────────────

class InitiateCallUseCase {
  final AppRepository _repo;
  InitiateCallUseCase(this._repo);
  Future<SupportCallEntity> call({
    required String callType,
    required String targetTeam,
  }) =>
      _repo.initiateCall(callType: callType, targetTeam: targetTeam);
}

class GetCallStatusUseCase {
  final AppRepository _repo;
  GetCallStatusUseCase(this._repo);
  Future<SupportCallEntity> call(String callId) =>
      _repo.getCallStatus(callId);
}

class GetAgoraTokenUseCase {
  final AppRepository _repo;
  GetAgoraTokenUseCase(this._repo);
  Future<AgoraTokenEntity> call(String callId) =>
      _repo.getAgoraToken(callId);
}

class UpdateCallStatusUseCase {
  final AppRepository _repo;
  UpdateCallStatusUseCase(this._repo);
  Future<void> call({
    required String callId,
    required String status,
  }) =>
      _repo.updateCallStatus(callId: callId, status: status);
}

// ── Orders ────────────────────────────────────────────────────────────────────

class GetOrdersUseCase {
  final AppRepository _repo;
  GetOrdersUseCase(this._repo);
  Future<List<OrderEntity>> call({String? status}) =>
      _repo.getOrders(status: status);
}

class CreateOrderUseCase {
  final AppRepository _repo;
  CreateOrderUseCase(this._repo);
  Future<OrderEntity> call({
    required String serviceId,
    String? customerPhone,
    String? notes,
  }) =>
      _repo.createOrder(
          serviceId: serviceId, customerPhone: customerPhone, notes: notes);
}

class GetOrderUseCase {
  final AppRepository _repo;
  GetOrderUseCase(this._repo);
  Future<OrderEntity> call(String orderId) => _repo.getOrder(orderId);
}

class GetPaymentInstructionsUseCase {
  final AppRepository _repo;
  GetPaymentInstructionsUseCase(this._repo);
  Future<PaymentInstructions> call() => _repo.getPaymentInstructions();
}

class SubmitPaymentRequestUseCase {
  final AppRepository _repo;
  SubmitPaymentRequestUseCase(this._repo);
  Future<PaymentRequestEntity> call({
    required String orderId,
    required String paymentMethod,
    required String referenceNumber,
    required double amountPaid,
    DateTime? paidAt,
    String? payerName,
    String? payerNote,
    String? proofFilePath,
  }) =>
      _repo.submitPaymentRequest(
        orderId: orderId,
        paymentMethod: paymentMethod,
        referenceNumber: referenceNumber,
        amountPaid: amountPaid,
        paidAt: paidAt,
        payerName: payerName,
        payerNote: payerNote,
        proofFilePath: proofFilePath,
      );
}

class GetPaymentRequestUseCase {
  final AppRepository _repo;
  GetPaymentRequestUseCase(this._repo);
  Future<PaymentRequestEntity> call(String requestId) =>
      _repo.getPaymentRequest(requestId);
}

class CancelOrderUseCase {
  final AppRepository _repo;
  CancelOrderUseCase(this._repo);
  Future<OrderEntity> call(String orderId, {String? reason}) =>
      _repo.cancelOrder(orderId, reason: reason);
}

// ── Community Hub ───────────────────────────────────────────────────────────────

class GetCommunityPostsUseCase {
  final AppRepository _repo;
  GetCommunityPostsUseCase(this._repo);
  Future<CommunityFeed> call({
    int page = 1,
    int limit = 20,
    String sort = 'newest',
    String? tag,
    String? search,
    String? postType,
  }) =>
      _repo.getCommunityPosts(
        page: page,
        limit: limit,
        sort: sort,
        tag: tag,
        search: search,
        postType: postType,
      );
}

class GetCommunityPostUseCase {
  final AppRepository _repo;
  GetCommunityPostUseCase(this._repo);
  Future<CommunityPost> call(String id) => _repo.getCommunityPost(id);
}

class CreateCommunityPostUseCase {
  final AppRepository _repo;
  CreateCommunityPostUseCase(this._repo);
  Future<CommunityPost> call({
    required String title,
    required String body,
    required String postType,
    required List<String> tags,
  }) =>
      _repo.createCommunityPost(
          title: title, body: body, postType: postType, tags: tags);
}

class AddCommunityAnswerUseCase {
  final AppRepository _repo;
  AddCommunityAnswerUseCase(this._repo);
  Future<CommunityAnswer> call({
    required String postId,
    required String body,
  }) =>
      _repo.addCommunityAnswer(postId: postId, body: body);
}

class VoteCommunityPostUseCase {
  final AppRepository _repo;
  VoteCommunityPostUseCase(this._repo);
  Future<CommunityVoteResult> call({
    required String postId,
    required int value,
  }) =>
      _repo.voteCommunityPost(postId: postId, value: value);
}

class VoteCommunityAnswerUseCase {
  final AppRepository _repo;
  VoteCommunityAnswerUseCase(this._repo);
  Future<CommunityVoteResult> call({
    required String answerId,
    required int value,
  }) =>
      _repo.voteCommunityAnswer(answerId: answerId, value: value);
}

class AcceptCommunityAnswerUseCase {
  final AppRepository _repo;
  AcceptCommunityAnswerUseCase(this._repo);
  Future<CommunityPost> call({
    required String postId,
    required String answerId,
  }) =>
      _repo.acceptCommunityAnswer(postId: postId, answerId: answerId);
}

class DeleteCommunityPostUseCase {
  final AppRepository _repo;
  DeleteCommunityPostUseCase(this._repo);
  Future<void> call(String postId) => _repo.deleteCommunityPost(postId);
}

class DeleteCommunityAnswerUseCase {
  final AppRepository _repo;
  DeleteCommunityAnswerUseCase(this._repo);
  Future<void> call(String answerId) => _repo.deleteCommunityAnswer(answerId);
}

class GetCommunityTagsUseCase {
  final AppRepository _repo;
  GetCommunityTagsUseCase(this._repo);
  Future<List<CommunityTag>> call() => _repo.getCommunityTags();
}

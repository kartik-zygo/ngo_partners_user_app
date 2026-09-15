import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../core/network/dio_client.dart';
import '../../domain/entities/case_entity.dart';
import '../../domain/entities/collaboration_entity.dart';
import '../../domain/entities/community_entity.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/entities/support_call_entity.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/quotation_entity.dart';
import '../../domain/entities/user_entity.dart';

class RemoteDataSource {
  final DioClient _client;
  final _uuid = const Uuid();

  RemoteDataSource(this._client);

  Dio get _dio => _client.dio;

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = res.data['data'] as Map<String, dynamic>;
      await _saveAuthData(data);
      return UserEntity.fromJson(data);
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  Future<UserEntity> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    bool isOrganizationAccount = false,
    String? organizationName,
    String? organizationType,
    String? organizationRegNumber,
    String? organizationWebsite,
    String? organizationDescription,
  }) async {
    try {
      final body = {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        if (phone != null) 'phone': phone,
        'isOrganizationAccount': isOrganizationAccount,
        if (organizationName != null) 'organizationName': organizationName,
        if (organizationType != null) 'organizationType': organizationType,
        if (organizationRegNumber != null)
          'organizationRegNumber': organizationRegNumber,
        if (organizationWebsite != null)
          'organizationWebsite': organizationWebsite,
        if (organizationDescription != null)
          'organizationDescription': organizationDescription,
      };
      final res = await _dio.post('/auth/register', data: body);
      final data = res.data['data'] as Map<String, dynamic>;
      await _saveAuthData(data);
      return UserEntity.fromJson(data);
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  Future<UserEntity> getMe() async {
    try {
      final res = await _dio.get('/auth/me');
      final data = res.data['data'] as Map<String, dynamic>;
      final user = UserEntity.fromJson(data);
      await _client.saveUserId(user.id);
      return user;
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _client.getRefreshToken();
      if (refreshToken != null) {
        await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
      }
    } catch (_) {
      // Always clear tokens regardless of server response
    }
    await _client.clearTokens();
  }

  /// `DELETE /auth/me`. The server re-checks [password], removes the account
  /// and revokes every session. Returns its confirmation message.
  Future<String> deleteAccount({
    required String password,
    String? reason,
  }) async {
    try {
      final res = await _dio.delete('/auth/me', data: {
        'password': password,
        'confirm': 'DELETE',
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      });
      _client.stopRefreshTimer();
      await _client.clearTokens();
      final data = res.data['data'];
      return data is Map ? (data['message'] ?? '').toString() : '';
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == null) {
        throw Exception(
          'Could not reach the server. Check your connection and try again.',
        );
      }
      if (status == 401) {
        throw Exception('Incorrect password. Please check it and try again.');
      }
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  Future<UserEntity> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
    String? organizationName,
  }) async {
    try {
      final body = <String, dynamic>{
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (phone != null) 'phone': phone,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (organizationName != null) 'organizationName': organizationName,
      };
      await _dio.patch('/auth/me/profile', data: body);
      return getMe();
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  // ── Services ──────────────────────────────────────────────────────────────

  Future<List<ServiceEntity>> getServices({int page = 1, int limit = 20}) async {
    try {
      final res = await _dio.get('/services', queryParameters: {
        'page': page,
        'limit': limit,
      });
      final list = res.data['data'] as List<dynamic>;
      return list
          .map((e) => ServiceEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  Future<ServiceEntity> getServiceById(String id) async {
    try {
      final res = await _dio.get('/services/$id');
      return ServiceEntity.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  // ── Cases ─────────────────────────────────────────────────────────────────

  Future<List<CaseEntity>> getCases({int page = 1, int limit = 20}) async {
    try {
      final res = await _dio.get('/cases', queryParameters: {
        'page': page,
        'limit': limit,
      });
      final list = res.data['data'] as List<dynamic>;
      return list
          .map((e) => CaseEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  Future<CaseEntity> getCaseById(String id) async {
    try {
      final res = await _dio.get('/cases/$id');
      return CaseEntity.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  Future<CaseEntity> createCase({
    required String userId,
    required String serviceId,
    String notes = '',
  }) async {
    try {
      final res = await _dio.post('/cases', data: {
        'userId': userId,
        'serviceId': serviceId,
        'notes': notes,
      });
      final newCase =
          CaseEntity.fromJson(res.data['data'] as Map<String, dynamic>);
      // Fire purchase-intent integration event (best-effort)
      _triggerUserAction(
        userId: userId,
        actionType: 'purchaseIntent',
        serviceId: serviceId,
      );
      return newCase;
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  Future<void> uploadDocumentToCase({
    required String caseId,
    required String docName,
    required String filePath,
    required String mimeType,
    required int fileSizeBytes,
  }) async {
    try {
      final formData = FormData.fromMap({
        'document_name': docName,
        'mime_type': mimeType,
        'file_size_bytes': fileSizeBytes,
        'file': await MultipartFile.fromFile(
          filePath,
          filename: docName,
          contentType: DioMediaType.parse(mimeType),
        ),
      });
      await _dio.post('/cases/$caseId/documents', data: formData);
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  Future<void> resubmitDocuments({
    required String caseId,
    required String requestId,
    required List<Map<String, dynamic>> documents,
  }) async {
    try {
      await _dio.post('/cases/$caseId/resubmissions', data: {
        'requestId': requestId,
        'documents': documents,
      });
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  // ── Tickets ───────────────────────────────────────────────────────────────

  Future<List<TicketEntity>> getTickets({int page = 1, int limit = 20}) async {
    try {
      final res = await _dio.get('/tickets', queryParameters: {
        'page': page,
        'limit': limit,
      });
      final list = res.data['data'] as List<dynamic>;
      return list
          .map((e) => TicketEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  Future<TicketEntity> getTicketById(String id) async {
    try {
      final res = await _dio.get('/tickets/$id');
      return TicketEntity.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  Future<TicketEntity> createTicket({
    required String subject,
    required String description,
    required TicketPriority priority,
    String? caseId,
  }) async {
    try {
      final res = await _dio.post('/tickets', data: {
        'subject': subject,
        'description': description,
        'priority': _priorityToString(priority),
        if (caseId != null) 'caseId': caseId,
      });
      return TicketEntity.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  Future<void> addTicketReply({
    required String ticketId,
    required String message,
  }) async {
    try {
      await _dio.post('/tickets/$ticketId/updates', data: {
        'message': message,
      });
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  String _priorityToString(TicketPriority p) {
    switch (p) {
      case TicketPriority.low:
        return 'low';
      case TicketPriority.medium:
        return 'medium';
      case TicketPriority.high:
        return 'high';
      case TicketPriority.urgent:
        return 'urgent';
    }
  }

  // ── Support Calls ─────────────────────────────────────────────────────────

  Future<SupportCallEntity> initiateCall({
    required String callType,
    required String targetTeam,
  }) async {
    try {
      final res = await _dio.post('/support-calls', data: {
        'callType': callType,
        'targetTeam': targetTeam,
      });
      return SupportCallEntity.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  Future<SupportCallEntity> getCallStatus(String callId) async {
    try {
      final res = await _dio.get('/support-calls/$callId');
      return SupportCallEntity.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  Future<AgoraTokenEntity> getAgoraToken(String callId) async {
    try {
      final res = await _dio.get('/support-calls/$callId/agora-token');
      return AgoraTokenEntity.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  Future<void> updateCallStatus({
    required String callId,
    required String status,
  }) async {
    try {
      await _dio.patch('/support-calls/$callId/status', data: {
        'status': status,
      });
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  Future<List<NotificationEntity>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await _dio.get('/notifications', queryParameters: {
        'page': page,
        'limit': limit,
      });
      final list = res.data['data'] as List<dynamic>;
      return list
          .map((e) =>
              NotificationEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _dio.patch('/notifications/$notificationId/read');
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  Future<void> markAllNotificationsRead() async {
    try {
      await _dio.patch('/notifications/read-all');
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  // ── Collaborations ────────────────────────────────────────────────────────

  Future<List<CollaborationEntity>> getCollaborations({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await _dio.get('/collaborations', queryParameters: {
        'page': page,
        'limit': limit,
      });
      final list = res.data['data'] as List<dynamic>;
      return list
          .map((e) =>
              CollaborationEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  Future<CollaborationEntity> requestCollaboration({
    required CollabType type,
    required String proposal,
  }) async {
    try {
      final res = await _dio.post('/collaborations', data: {
        'type': _collabTypeToString(type),
        'proposal': proposal,
      });
      return CollaborationEntity.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  String _collabTypeToString(CollabType t) {
    switch (t) {
      case CollabType.fundingPartner:
        return 'fundingPartner';
      case CollabType.resourceSharing:
        return 'resourceSharing';
      case CollabType.csrPartner:
        return 'csrPartner';
      case CollabType.technical:
        return 'technical';
    }
  }

  // ── Orders (legacy) ───────────────────────────────────────────────────────
  // Read-only since the quotation cutover. Orders can no longer be placed or
  // paid from the app; these only settle what was already in flight.

  Future<List<OrderEntity>> getOrders({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await _dio.get('/orders', queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
      });
      final list = res.data['data'] as List<dynamic>;
      return list
          .map((e) => OrderEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  Future<OrderEntity> getOrder(String orderId) async {
    try {
      final res = await _dio.get('/orders/$orderId');
      return OrderEntity.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  Future<OrderEntity> cancelOrder(String orderId, {String? reason}) async {
    try {
      final res = await _dio.post(
        '/orders/$orderId/cancel',
        data: {if (reason != null && reason.isNotEmpty) 'reason': reason},
      );
      return OrderEntity.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  // ── Quotations ────────────────────────────────────────────────────────────

  Future<QuotationEntity> createQuotation({
    required String serviceId,
    required String name,
    required String email,
    required String phone,
    String? organizationName,
    String? message,
  }) async {
    try {
      final res = await _dio.post('/quotations', data: {
        'serviceId': serviceId,
        'name': name,
        'email': email,
        'phone': phone,
        if (organizationName != null && organizationName.isNotEmpty)
          'organizationName': organizationName,
        if (message != null && message.isNotEmpty) 'message': message,
      });
      return QuotationEntity.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _quotationSubmitError(e);
    }
  }

  Future<List<QuotationEntity>> getQuotations({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await _dio.get('/quotations', queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null && status.isNotEmpty) 'status': status,
      });
      final list = res.data['data'] as List<dynamic>;
      return list
          .map((e) => QuotationEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  Future<QuotationEntity> getQuotationById(String id) async {
    try {
      final res = await _dio.get('/quotations/$id');
      return QuotationEntity.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  /// Turns the documented submit failures into the typed exceptions the
  /// quotation screens branch on. Anything else stays a plain [Exception].
  Exception _quotationSubmitError(DioException e) {
    final status = e.response?.statusCode;
    final message = _client.extractErrorMessage(e);
    final error = _errorBody(e);
    final details = error?['details'];

    if (status == 409) {
      return QuotationAlreadyOpenException(
        message,
        reference: _referenceFrom(details, e.response?.data) ??
            _referenceFrom(null, message),
      );
    }
    if (status == 422) {
      return QuotationValidationException(
        message,
        fieldErrors: _fieldErrors(details),
      );
    }
    if (status == 404) {
      return QuotationServiceUnavailableException(message);
    }
    return Exception(message);
  }

  Map<String, dynamic>? _errorBody(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      return Map<String, dynamic>.from(data['error'] as Map);
    }
    return null;
  }

  /// `QR-2609-D5D6A4`. The backend may return it as a field or only inside the
  /// message, so both are worth a look before giving up.
  String? _referenceFrom(dynamic details, dynamic fallback) {
    if (details is Map) {
      for (final key in const ['reference', 'existingReference', 'quotationReference']) {
        final value = details[key];
        if (value is String && value.isNotEmpty) return value;
      }
    }
    if (fallback is Map) {
      final data = fallback['data'];
      if (data is Map && data['reference'] is String) {
        return data['reference'] as String;
      }
    }
    if (fallback is String) {
      final match = RegExp(r'QR-[A-Z0-9]+-[A-Z0-9]+').firstMatch(fallback);
      if (match != null) return match.group(0);
    }
    return null;
  }

  /// `details` arrives either as `[{field, message}, …]` or as a plain map of
  /// field → message depending on the validator that rejected the body.
  Map<String, String> _fieldErrors(dynamic details) {
    final result = <String, String>{};
    if (details is List) {
      for (final entry in details) {
        if (entry is! Map) continue;
        final field = (entry['field'] ?? entry['path'] ?? entry['param'])
            ?.toString();
        final message = (entry['message'] ?? entry['msg'])?.toString();
        if (field != null && message != null) result[field] = message;
      }
    } else if (details is Map) {
      details.forEach((key, value) {
        if (value is String) {
          result[key.toString()] = value;
        } else if (value is List && value.isNotEmpty) {
          result[key.toString()] = value.first.toString();
        }
      });
    }
    return result;
  }

  // ── Integration ───────────────────────────────────────────────────────────

  Future<void> triggerServiceInquiry({
    required String userId,
    required String serviceId,
  }) async {
    _triggerUserAction(
      userId: userId,
      actionType: 'serviceInquiry',
      serviceId: serviceId,
    );
  }

  Future<void> submitLeadRequest({
    required String userId,
    required String serviceId,
    required String contactName,
    required String contactEmail,
    required String contactPhone,
    String notes = '',
  }) async {
    try {
      await _dio.post('/integration/lead-requests', data: {
        'userId': userId,
        'serviceId': serviceId,
        'contactName': contactName,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        'notes': notes,
        'idempotencyKey': 'lead-${_uuid.v4()}',
      });
    } catch (_) {}
  }

  // Best-effort — don't propagate errors to caller
  void _triggerUserAction({
    required String userId,
    required String actionType,
    required String serviceId,
  }) {
    _dio.post('/integration/user-actions', data: {
      'userId': userId,
      'actionType': actionType,
      'serviceId': serviceId,
      'idempotencyKey': '$actionType-${_uuid.v4()}',
    // ignore errors from fire-and-forget integration events
    }).then((_) {}, onError: (_) {});
  }

  // ── Community Hub ─────────────────────────────────────────────────────────

  Future<CommunityFeed> getCommunityPosts({
    int page = 1,
    int limit = 20,
    String sort = 'newest',
    String? tag,
    String? search,
    String? postType,
  }) async {
    try {
      final res = await _dio.get('/community/posts', queryParameters: {
        'page': page,
        'limit': limit,
        'sort': sort,
        if (tag != null && tag.isNotEmpty) 'tag': tag,
        if (search != null && search.isNotEmpty) 'search': search,
        if (postType != null) 'postType': postType,
      });
      final list = (res.data['data'] as List<dynamic>)
          .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
          .toList();
      final meta = res.data['meta'] as Map<String, dynamic>?;
      return CommunityFeed(
        posts: list,
        hasNext: meta?['hasNext'] as bool? ?? false,
        page: (meta?['page'] as num?)?.toInt() ?? page,
      );
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  Future<CommunityPost> getCommunityPost(String id) async {
    try {
      final res = await _dio.get('/community/posts/$id');
      return CommunityPost.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  Future<CommunityPost> createCommunityPost({
    required String title,
    required String body,
    required String postType,
    required List<String> tags,
  }) async {
    try {
      final res = await _dio.post('/community/posts', data: {
        'title': title,
        'body': body,
        'postType': postType,
        'tags': tags,
      });
      return CommunityPost.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  Future<CommunityAnswer> addCommunityAnswer({
    required String postId,
    required String body,
  }) async {
    try {
      final res = await _dio.post('/community/posts/$postId/answers', data: {
        'body': body,
      });
      return CommunityAnswer.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  Future<CommunityVoteResult> voteCommunityPost({
    required String postId,
    required int value,
  }) async {
    try {
      final res = await _dio.post('/community/posts/$postId/vote', data: {
        'value': value,
      });
      return CommunityVoteResult.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  Future<CommunityVoteResult> voteCommunityAnswer({
    required String answerId,
    required int value,
  }) async {
    try {
      final res = await _dio.post('/community/answers/$answerId/vote', data: {
        'value': value,
      });
      return CommunityVoteResult.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  Future<CommunityPost> acceptCommunityAnswer({
    required String postId,
    required String answerId,
  }) async {
    try {
      final res = await _dio
          .post('/community/posts/$postId/answers/$answerId/accept');
      return CommunityPost.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  Future<void> deleteCommunityPost(String postId) async {
    try {
      await _dio.delete('/community/posts/$postId');
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  Future<void> deleteCommunityAnswer(String answerId) async {
    try {
      await _dio.delete('/community/answers/$answerId');
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  Future<List<CommunityTag>> getCommunityTags() async {
    try {
      final res = await _dio.get('/community/tags');
      return (res.data['data'] as List<dynamic>)
          .map((e) => CommunityTag.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_client.extractErrorMessage(e));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    final accessToken = data['accessToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;
    final userId = (data['user'] as Map<String, dynamic>?)?['id'] as String?;

    if (accessToken != null && refreshToken != null) {
      await _client.saveTokens(
          accessToken: accessToken, refreshToken: refreshToken);
    }
    if (userId != null) {
      await _client.saveUserId(userId);
    }
  }
}

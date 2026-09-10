import '../../domain/entities/user_entity.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/entities/case_entity.dart';
import '../../domain/entities/collaboration_entity.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/ticket_entity.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Mock in-memory data source  (replace with API/local DB in production)
// ─────────────────────────────────────────────────────────────────────────────
class LocalDataSource {
  // Users (demo credentials)
  static final Map<String, Map<String, dynamic>> _users = {
    'user@ngo.com': {
      'password': 'user123',
      'entity': const UserEntity(
        id: 'u1',
        name: 'Guest User',
        email: 'user@ngo.com',
        role: UserRole.user,
        phone: '+91 9876543210',
        purchasedServices: ['NGO Registration', '12A Registration'],
      ),
    },
  };

  static UserEntity? _currentUser;

  // ── Auth ──────────────────────────────────────────────────────────────────
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final entry = _users[email.trim().toLowerCase()];
    if (entry == null || entry['password'] != password) {
      throw Exception('Invalid email or password');
    }
    _currentUser = entry['entity'] as UserEntity;
    return _currentUser!;
  }

  Future<void> logout() async {
    _currentUser = null;
  }

  Future<UserEntity?> getCurrentUser() async => _currentUser;

  // ── Services ──────────────────────────────────────────────────────────────
  static final List<ServiceEntity> _services = [
    const ServiceEntity(
      id: 's1', name: 'NGO Registration',      status: 'approved', category: ServiceCategory.ngo,
      description: 'Complete NGO registration with all government formalities.',
      documents: ['PAN Card', 'Address Proof', 'MOA & AOA'],
      durationDays: 21,
    ),
    const ServiceEntity(
      id: 's2', name: 'Trust Registration',      status: 'approved', category: ServiceCategory.ngo,
      description: 'Public charitable trust registration under state Act.',
      documents: ['Trust Deed', 'ID Proofs of Trustees'],
      durationDays: 30,
    ),
    const ServiceEntity(
      id: 's3', name: 'Section 8 Company',      status: 'approved', category: ServiceCategory.ngo,
      description: 'Non-profit company under Section 8 of Companies Act 2013.',
      documents: ['DIN', 'DSC', 'MOA & AOA'],
      durationDays: 25,
    ),
    const ServiceEntity(
      id: 's4', name: '12A Registration',      status: 'approved', category: ServiceCategory.compliance,
      description: 'Tax exemption registration for NGOs & trusts.',
      documents: ['Registration Certificate', 'MOA', 'IT Returns'],
      durationDays: 45,
    ),
    const ServiceEntity(
      id: 's5', name: '80G Registration',      status: 'approved', category: ServiceCategory.compliance,
      description: 'Donors can claim 50% deduction on donations.',
      documents: ['12A Certificate', 'Audited Accounts'],
      durationDays: 45,
    ),
    const ServiceEntity(
      id: 's6', name: 'GST Registration',      status: 'pending', category: ServiceCategory.business,
      description: 'Mandatory GST registration for eligible organizations.',
      documents: ['PAN', 'Aadhaar', 'Bank Statement'],
      durationDays: 7,
    ),
    const ServiceEntity(
      id: 's7', name: 'LLP Registration',      status: 'approved', category: ServiceCategory.business,
      description: 'Limited Liability Partnership formation.',
      documents: ['DPIN', 'DSC', 'LLP Agreement'],
      durationDays: 15,
    ),
    const ServiceEntity(
      id: 's8', name: 'Private Limited Co.',      status: 'approved', category: ServiceCategory.business,
      description: 'Pvt Ltd company incorporation under Companies Act.',
      documents: ['DIN', 'DSC', 'MOA & AOA'],
      durationDays: 20,
    ),
    const ServiceEntity(
      id: 's9', name: 'Startup India Reg.',      status: 'pending', category: ServiceCategory.business,
      description: 'Register as Startup India certified entity.',
      documents: ['Incorporation Certificate', 'Business Plan'],
      durationDays: 10,
    ),
    const ServiceEntity(
      id: 's10', name: 'FCRA Registration',      status: 'approved', category: ServiceCategory.ngo,
      description: 'Foreign Contribution Regulation Act registration.',
      documents: ['3-yr IT Returns', 'Audit Report', 'Bank Details'],
      durationDays: 90,
    ),
  ];

  Future<List<ServiceEntity>> getServices() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.unmodifiable(_services);
  }

  // ── Cases ─────────────────────────────────────────────────────────────────
  final List<CaseEntity> _cases = [
    CaseEntity(
      id: 'c1', userId: 'u1', serviceName: 'NGO Registration',
      status: CaseStatus.filingInProgress,
      documents: ['Certificate.pdf', 'AoA.pdf'],
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    CaseEntity(
      id: 'c2', userId: 'u1', serviceName: '12A Registration',
      status: CaseStatus.underReview,
      documents: ['PAN.pdf'],
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
    ),
    CaseEntity(
      id: 'c4', userId: 'u1', serviceName: '80G Registration',
      status: CaseStatus.resubmitRequired,
      documents: ['80G_Form.pdf'],
      resubmitNote: 'Please upload latest audited financial statement.',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    CaseEntity(
      id: 'c5', userId: 'u1', serviceName: 'Trust Registration',
      status: CaseStatus.approved,
      documents: ['Trust_Deed.pdf', 'Trustee_IDs.pdf'],
      createdAt: DateTime.now().subtract(const Duration(days: 40)),
      updatedAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
  ];

  Future<List<CaseEntity>> getCases(String userId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _cases.where((c) => c.userId == userId).toList();
  }

  Future<CaseEntity> purchaseService({
    required String userId,
    required ServiceEntity service,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final newCase = CaseEntity(
      id: 'c${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      serviceName: service.name,
      status: CaseStatus.submitted,
      documents: [],
      createdAt: DateTime.now(),
    );
    _cases.add(newCase);
    return newCase;
  }

  Future<CaseEntity> uploadDocument({
    required String caseId,
    required String docName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final idx = _cases.indexWhere((c) => c.id == caseId);
    if (idx == -1) throw Exception('Case not found');
    final c = _cases[idx];
    final updated = CaseEntity(
      id: c.id, userId: c.userId, serviceName: c.serviceName,
      status: c.status,
      documents: [...c.documents, docName],
      resubmitNote: c.resubmitNote,
      createdAt: c.createdAt,
      updatedAt: DateTime.now(),
    );
    _cases[idx] = updated;
    return updated;
  }

  // ── Collaborations ────────────────────────────────────────────────────────
  final List<CollaborationEntity> _collabs = [
    const CollaborationEntity(
      id: 'col1', ngoName: 'Green Earth NGO',
      type: CollabType.fundingPartner,
      status: CollabStatus.pending,
      about: 'Environmental conservation projects',
    ),
    const CollaborationEntity(
      id: 'col2', ngoName: 'Literacy Foundation',
      type: CollabType.resourceSharing,
      status: CollabStatus.approved,
      about: 'Education programs for rural areas',
    ),
    const CollaborationEntity(
      id: 'col3', ngoName: 'Health For All',
      type: CollabType.csrPartner,
      status: CollabStatus.pending,
      about: 'Primary healthcare access',
    ),
  ];

  Future<List<CollaborationEntity>> getCollaborations() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.unmodifiable(_collabs);
  }

  Future<CollaborationEntity> requestCollaboration({
    required String ngoName,
    required CollabType type,
    required String about,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final collab = CollaborationEntity(
      id: 'col${DateTime.now().millisecondsSinceEpoch}',
      ngoName: ngoName,
      type: type,
      status: CollabStatus.pending,
      about: about,
    );
    _collabs.add(collab);
    return collab;
  }

  // ── Notifications ─────────────────────────────────────────────────────────
  final Map<String, List<NotificationEntity>> _notifications = {
    'u1': [
      const NotificationEntity(
        id: 'n1', title: 'Case Update',
        text: 'Your NGO Registration is in progress',
        timeAgo: '2h ago', isRead: false, type: 'case',
      ),
      const NotificationEntity(
        id: 'n2', title: 'Document Verified',
        text: 'Document verified by filing team',
        timeAgo: '1d ago', isRead: false, type: 'document',
      ),
      const NotificationEntity(
        id: 'n3', title: 'Collaboration Request',
        text: 'New collaboration request from Green Earth NGO',
        timeAgo: '2d ago', isRead: true, type: 'collab',
      ),
    ],
  };

  Future<List<NotificationEntity>> getNotifications(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _notifications[userId] ?? [];
  }

  Future<void> markNotificationRead(String notificationId) async {
    for (final entry in _notifications.entries) {
      final idx = entry.value.indexWhere((n) => n.id == notificationId);
      if (idx != -1) {
        entry.value[idx] = entry.value[idx].copyWith(isRead: true);
        return;
      }
    }
  }

  // ── Tickets ───────────────────────────────────────────────────────────────
  final List<TicketEntity> _tickets = [];

  Future<List<TicketEntity>> getTickets(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _tickets.where((t) => t.userId == userId).toList();
  }

  Future<TicketEntity> createTicket({
    required String userId,
    required String subject,
    required String description,
    required TicketPriority priority,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final ticket = TicketEntity(
      id: 'tkt${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      subject: subject,
      description: description,
      priority: priority,
      createdAt: DateTime.now(),
    );
    _tickets.add(ticket);
    return ticket;
  }
}

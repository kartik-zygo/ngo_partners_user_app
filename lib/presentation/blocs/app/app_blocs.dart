import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/collaboration_entity.dart';
import '../../../domain/entities/notification_entity.dart';
import '../../../domain/entities/ticket_entity.dart';
import '../../../domain/usecases/app_usecases.dart';

// ── Collaboration BLoC ────────────────────────────────────────────────────────
abstract class CollabEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadCollaborations extends CollabEvent {}

class RequestCollab extends CollabEvent {
  final String ngoName;
  final CollabType type;
  final String about;
  RequestCollab(
      {required this.ngoName, required this.type, required this.about});
  @override
  List<Object?> get props => [ngoName, type, about];
}

abstract class CollabState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CollabInitial extends CollabState {}

class CollabLoading extends CollabState {}

class CollabLoaded extends CollabState {
  final List<CollaborationEntity> collaborations;
  final bool isRequesting;
  CollabLoaded({required this.collaborations, this.isRequesting = false});
  @override
  List<Object?> get props => [collaborations, isRequesting];
}

class CollabError extends CollabState {
  final String message;
  CollabError(this.message);
  @override
  List<Object?> get props => [message];
}

class CollabBloc extends Bloc<CollabEvent, CollabState> {
  final GetCollaborationsUseCase _get;
  final RequestCollaborationUseCase _request;

  CollabBloc({
    required GetCollaborationsUseCase getCollaborations,
    required RequestCollaborationUseCase requestCollaboration,
  })  : _get = getCollaborations,
        _request = requestCollaboration,
        super(CollabInitial()) {
    on<LoadCollaborations>(_onLoad);
    on<RequestCollab>(_onRequest);
  }

  Future<void> _onLoad(
      LoadCollaborations _, Emitter<CollabState> emit) async {
    emit(CollabLoading());
    try {
      final list = await _get();
      emit(CollabLoaded(collaborations: list));
    } catch (e) {
      emit(CollabError(e.toString()));
    }
  }

  Future<void> _onRequest(
      RequestCollab event, Emitter<CollabState> emit) async {
    final current = state;
    if (current is! CollabLoaded) return;
    emit(CollabLoaded(
        collaborations: current.collaborations, isRequesting: true));
    try {
      final collab = await _request(
        ngoName: event.ngoName,
        type: event.type,
        about: event.about,
      );
      emit(CollabLoaded(
        collaborations: [...current.collaborations, collab],
      ));
    } catch (_) {
      emit(CollabLoaded(collaborations: current.collaborations));
    }
  }
}

// ── Notifications BLoC ────────────────────────────────────────────────────────
abstract class NotifEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotifEvent {
  final String userId;
  LoadNotifications(this.userId);
  @override
  List<Object?> get props => [userId];
}

class MarkRead extends NotifEvent {
  final String id;
  MarkRead(this.id);
  @override
  List<Object?> get props => [id];
}

class MarkAllRead extends NotifEvent {}

abstract class NotifState extends Equatable {
  @override
  List<Object?> get props => [];
}

class NotifInitial extends NotifState {}

class NotifLoading extends NotifState {}

class NotifLoaded extends NotifState {
  final List<NotificationEntity> notifications;
  NotifLoaded(this.notifications);
  int get unreadCount => notifications.where((n) => !n.isRead).length;
  @override
  List<Object?> get props => [notifications];
}

class NotifBloc extends Bloc<NotifEvent, NotifState> {
  final GetNotificationsUseCase _get;
  final MarkNotificationReadUseCase _mark;
  final MarkAllNotificationsReadUseCase _markAll;

  NotifBloc({
    required GetNotificationsUseCase getNotifications,
    required MarkNotificationReadUseCase markRead,
    required MarkAllNotificationsReadUseCase markAllRead,
  })  : _get = getNotifications,
        _mark = markRead,
        _markAll = markAllRead,
        super(NotifInitial()) {
    on<LoadNotifications>(_onLoad);
    on<MarkRead>(_onMark);
    on<MarkAllRead>(_onMarkAll);
  }

  Future<void> _onLoad(
      LoadNotifications event, Emitter<NotifState> emit) async {
    emit(NotifLoading());
    try {
      final list = await _get(event.userId);
      emit(NotifLoaded(list));
    } catch (_) {
      emit(NotifLoaded(const []));
    }
  }

  Future<void> _onMark(MarkRead event, Emitter<NotifState> emit) async {
    await _mark(event.id).catchError((_) {});
    final current = state;
    if (current is NotifLoaded) {
      final updated = current.notifications
          .map((n) => n.id == event.id ? n.copyWith(isRead: true) : n)
          .toList();
      emit(NotifLoaded(updated));
    }
  }

  Future<void> _onMarkAll(MarkAllRead _, Emitter<NotifState> emit) async {
    final current = state;
    if (current is! NotifLoaded) return;
    // Optimistic update
    final allRead = current.notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    emit(NotifLoaded(allRead));
    // Sync to API best-effort
    await _markAll().catchError((_) {});
  }
}

// ── Tickets BLoC ─────────────────────────────────────────────────────────────
abstract class TicketEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadTickets extends TicketEvent {
  final String userId;
  LoadTickets(this.userId);
  @override
  List<Object?> get props => [userId];
}

class CreateTicket extends TicketEvent {
  final String userId, subject, description;
  final TicketPriority priority;
  final String? caseId;
  CreateTicket({
    required this.userId,
    required this.subject,
    required this.description,
    required this.priority,
    this.caseId,
  });
  @override
  List<Object?> get props => [userId, subject, description, priority];
}

class AddTicketReply extends TicketEvent {
  final String ticketId;
  final String message;
  AddTicketReply({required this.ticketId, required this.message});
  @override
  List<Object?> get props => [ticketId, message];
}

abstract class TicketState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TicketInitial extends TicketState {}

class TicketLoading extends TicketState {}

class TicketLoaded extends TicketState {
  final List<TicketEntity> tickets;
  final bool isCreating;
  TicketLoaded({required this.tickets, this.isCreating = false});
  @override
  List<Object?> get props => [tickets, isCreating];
}

class TicketsBloc extends Bloc<TicketEvent, TicketState> {
  final GetTicketsUseCase _get;
  final CreateTicketUseCase _create;
  final AddTicketReplyUseCase _reply;

  TicketsBloc({
    required GetTicketsUseCase getTickets,
    required CreateTicketUseCase createTicket,
    required AddTicketReplyUseCase addTicketReply,
  })  : _get = getTickets,
        _create = createTicket,
        _reply = addTicketReply,
        super(TicketInitial()) {
    on<LoadTickets>(_onLoad);
    on<CreateTicket>(_onCreate);
    on<AddTicketReply>(_onReply);
  }

  Future<void> _onLoad(LoadTickets event, Emitter<TicketState> emit) async {
    emit(TicketLoading());
    try {
      final list = await _get(event.userId);
      emit(TicketLoaded(tickets: list));
    } catch (_) {
      emit(TicketLoaded(tickets: const []));
    }
  }

  Future<void> _onCreate(
      CreateTicket event, Emitter<TicketState> emit) async {
    final current = state;
    if (current is! TicketLoaded) return;
    emit(TicketLoaded(tickets: current.tickets, isCreating: true));
    try {
      final ticket = await _create(
        userId: event.userId,
        subject: event.subject,
        description: event.description,
        priority: event.priority,
        caseId: event.caseId,
      );
      emit(TicketLoaded(tickets: [...current.tickets, ticket]));
    } catch (_) {
      emit(TicketLoaded(tickets: current.tickets));
    }
  }

  Future<void> _onReply(
      AddTicketReply event, Emitter<TicketState> emit) async {
    await _reply(ticketId: event.ticketId, message: event.message)
        .catchError((_) {});
  }
}

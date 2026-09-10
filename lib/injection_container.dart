import 'package:get_it/get_it.dart';
import 'core/network/dio_client.dart';
import 'core/services/socket_service.dart';
import 'data/datasources/remote_data_source.dart';
import 'data/repositories/app_repository_impl.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/app_repository.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/app_usecases.dart';
import 'domain/usecases/auth_usecases.dart';
import 'presentation/blocs/app/app_blocs.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/community/community_bloc.dart';
import 'presentation/blocs/quotations/quotations_bloc.dart';
import 'presentation/blocs/services/services_bloc.dart';

final sl = GetIt.instance;

void setupInjection() {
  // ── Network ───────────────────────────────────────────────────────────────
  sl.registerLazySingleton<DioClient>(() => DioClient());
  sl.registerLazySingleton<SocketService>(() => SocketService());

  // ── Data sources ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<RemoteDataSource>(() => RemoteDataSource(sl()));

  // ── Repositories ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton<AppRepository>(() => AppRepositoryImpl(sl()));

  // ── Auth use cases ────────────────────────────────────────────────────────
  sl.registerFactory(() => LoginUseCase(sl()));
  sl.registerFactory(() => RegisterUseCase(sl()));
  sl.registerFactory(() => LogoutUseCase(sl()));
  sl.registerFactory(() => GetCurrentUserUseCase(sl()));
  sl.registerFactory(() => UpdateProfileUseCase(sl()));

  // ── App use cases ─────────────────────────────────────────────────────────
  sl.registerFactory(() => GetServicesUseCase(sl()));
  sl.registerFactory(() => GetServiceByIdUseCase(sl()));
  sl.registerFactory(() => GetCasesUseCase(sl()));
  sl.registerFactory(() => PurchaseServiceUseCase(sl()));
  sl.registerFactory(() => UploadDocumentUseCase(sl()));
  sl.registerFactory(() => ResubmitDocumentsUseCase(sl()));
  sl.registerFactory(() => GetCollaborationsUseCase(sl()));
  sl.registerFactory(() => RequestCollaborationUseCase(sl()));
  sl.registerFactory(() => GetNotificationsUseCase(sl()));
  sl.registerFactory(() => MarkNotificationReadUseCase(sl()));
  sl.registerFactory(() => MarkAllNotificationsReadUseCase(sl()));
  sl.registerFactory(() => GetTicketsUseCase(sl()));
  sl.registerFactory(() => CreateTicketUseCase(sl()));
  sl.registerFactory(() => AddTicketReplyUseCase(sl()));
  sl.registerFactory(() => GetTicketByIdUseCase(sl()));
  sl.registerFactory(() => InitiateCallUseCase(sl()));
  sl.registerFactory(() => GetCallStatusUseCase(sl()));
  sl.registerFactory(() => GetAgoraTokenUseCase(sl()));
  sl.registerFactory(() => UpdateCallStatusUseCase(sl()));
  sl.registerFactory(() => GetOrdersUseCase(sl()));
  sl.registerFactory(() => GetOrderUseCase(sl()));
  sl.registerFactory(() => CancelOrderUseCase(sl()));
  sl.registerFactory(() => CreateQuotationUseCase(sl()));
  sl.registerFactory(() => GetQuotationsUseCase(sl()));
  sl.registerFactory(() => GetQuotationByIdUseCase(sl()));
  sl.registerFactory(() => GetCommunityPostsUseCase(sl()));
  sl.registerFactory(() => GetCommunityPostUseCase(sl()));
  sl.registerFactory(() => CreateCommunityPostUseCase(sl()));
  sl.registerFactory(() => AddCommunityAnswerUseCase(sl()));
  sl.registerFactory(() => VoteCommunityPostUseCase(sl()));
  sl.registerFactory(() => VoteCommunityAnswerUseCase(sl()));
  sl.registerFactory(() => AcceptCommunityAnswerUseCase(sl()));
  sl.registerFactory(() => DeleteCommunityPostUseCase(sl()));
  sl.registerFactory(() => DeleteCommunityAnswerUseCase(sl()));
  sl.registerFactory(() => GetCommunityTagsUseCase(sl()));

  // ── BLoCs ─────────────────────────────────────────────────────────────────
  sl.registerFactory(
    () => AuthBloc(
      login: sl(),
      register: sl(),
      logout: sl(),
      getCurrentUser: sl(),
      updateProfile: sl(),
    ),
  );
  sl.registerFactory(
    () => ServicesBloc(
      getServices: sl(),
      getCases: sl(),
      purchaseService: sl(),
      uploadDocument: sl(),
    ),
  );
  sl.registerFactory(
    () => CollabBloc(
      getCollaborations: sl(),
      requestCollaboration: sl(),
    ),
  );
  sl.registerFactory(
    () => NotifBloc(
      getNotifications: sl(),
      markRead: sl(),
      markAllRead: sl(),
    ),
  );
  sl.registerFactory(
    () => TicketsBloc(
      getTickets: sl(),
      createTicket: sl(),
      addTicketReply: sl(),
    ),
  );
  sl.registerFactory(
    () => QuotationsBloc(
      createQuotation: sl(),
      getQuotations: sl(),
    ),
  );
  sl.registerFactory(
    () => CommunityBloc(
      getPosts: sl(),
      getTags: sl(),
    ),
  );
}

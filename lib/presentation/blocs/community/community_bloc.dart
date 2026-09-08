import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/community_entity.dart';
import '../../../domain/usecases/app_usecases.dart';

part 'community_event.dart';
part 'community_state.dart';

/// Drives the community feed: sort tabs, tag filter, search, and pagination.
/// The post-detail screen manages its own state via use cases directly.
class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  final GetCommunityPostsUseCase _getPosts;
  final GetCommunityTagsUseCase _getTags;

  CommunityBloc({
    required GetCommunityPostsUseCase getPosts,
    required GetCommunityTagsUseCase getTags,
  })  : _getPosts = getPosts,
        _getTags = getTags,
        super(const CommunityState()) {
    on<CommunityFeedRequested>(_onFeedRequested);
    on<CommunitySortChanged>(_onSortChanged);
    on<CommunityTagSelected>(_onTagSelected);
    on<CommunitySearchChanged>(_onSearchChanged);
    on<CommunityLoadMore>(_onLoadMore);
    on<CommunityRefreshed>(_onRefreshed);
  }

  Future<void> _load(Emitter<CommunityState> emit, {required bool reset}) async {
    if (reset) {
      emit(state.copyWith(status: CommunityStatus.loading, posts: const []));
    }
    try {
      final page = reset ? 1 : state.page + 1;
      final feed = await _getPosts(
        page: page,
        sort: state.sort,
        tag: state.tag,
        search: state.search.isEmpty ? null : state.search,
      );
      // Tags are best-effort; never block the feed on them.
      List<CommunityTag> tags = state.tags;
      if (reset && tags.isEmpty) {
        try {
          tags = await _getTags();
        } catch (_) {}
      }
      final posts = reset ? feed.posts : [...state.posts, ...feed.posts];
      emit(state.copyWith(
        status: CommunityStatus.success,
        posts: posts,
        tags: tags,
        page: feed.page,
        hasNext: feed.hasNext,
        loadingMore: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CommunityStatus.failure,
        loadingMore: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onFeedRequested(
      CommunityFeedRequested event, Emitter<CommunityState> emit) async {
    await _load(emit, reset: true);
  }

  Future<void> _onRefreshed(
      CommunityRefreshed event, Emitter<CommunityState> emit) async {
    await _load(emit, reset: true);
  }

  Future<void> _onSortChanged(
      CommunitySortChanged event, Emitter<CommunityState> emit) async {
    if (event.sort == state.sort) return;
    emit(state.copyWith(sort: event.sort));
    await _load(emit, reset: true);
  }

  Future<void> _onTagSelected(
      CommunityTagSelected event, Emitter<CommunityState> emit) async {
    final next = state.tag == event.tag ? null : event.tag;
    emit(state.copyWith(tag: next, clearTag: next == null));
    await _load(emit, reset: true);
  }

  Future<void> _onSearchChanged(
      CommunitySearchChanged event, Emitter<CommunityState> emit) async {
    emit(state.copyWith(search: event.query));
    await _load(emit, reset: true);
  }

  Future<void> _onLoadMore(
      CommunityLoadMore event, Emitter<CommunityState> emit) async {
    if (state.loadingMore || !state.hasNext) return;
    emit(state.copyWith(loadingMore: true));
    await _load(emit, reset: false);
  }
}

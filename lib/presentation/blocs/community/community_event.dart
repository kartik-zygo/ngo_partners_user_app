part of 'community_bloc.dart';

abstract class CommunityEvent extends Equatable {
  const CommunityEvent();
  @override
  List<Object?> get props => [];
}

/// Initial load (or full reload with current filters).
class CommunityFeedRequested extends CommunityEvent {
  const CommunityFeedRequested();
}

class CommunityRefreshed extends CommunityEvent {
  const CommunityRefreshed();
}

class CommunitySortChanged extends CommunityEvent {
  final String sort; // newest | top | unanswered | active
  const CommunitySortChanged(this.sort);
  @override
  List<Object?> get props => [sort];
}

class CommunityTagSelected extends CommunityEvent {
  final String tag;
  const CommunityTagSelected(this.tag);
  @override
  List<Object?> get props => [tag];
}

class CommunitySearchChanged extends CommunityEvent {
  final String query;
  const CommunitySearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class CommunityLoadMore extends CommunityEvent {
  const CommunityLoadMore();
}

/// The user blocked or unblocked someone, or reported a post.
class CommunitySafetyChanged extends CommunityEvent {
  const CommunitySafetyChanged();
}

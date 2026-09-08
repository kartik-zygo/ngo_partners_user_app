import 'package:equatable/equatable.dart';

/// Author of a community post or answer, with a reputation score and a
/// "team" badge for NGO Partners staff (SALES/ADMIN).
class CommunityAuthor extends Equatable {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isTeam;
  final int reputation;

  const CommunityAuthor({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isTeam = false,
    this.reputation = 0,
  });

  factory CommunityAuthor.fromJson(Map<String, dynamic> json) {
    return CommunityAuthor(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'NGO Member',
      avatarUrl: json['avatarUrl'] as String?,
      isTeam: json['isTeam'] as bool? ?? false,
      reputation: (json['reputation'] as num?)?.toInt() ?? 0,
    );
  }

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  @override
  List<Object?> get props => [id, name, isTeam, reputation];
}

class CommunityAnswer extends Equatable {
  final String id;
  final String postId;
  final String body;
  final int voteScore;
  final bool isAccepted;
  final CommunityAuthor author;
  final int myVote; // 1, 0, -1
  final DateTime? createdAt;

  const CommunityAnswer({
    required this.id,
    required this.postId,
    required this.body,
    this.voteScore = 0,
    this.isAccepted = false,
    required this.author,
    this.myVote = 0,
    this.createdAt,
  });

  factory CommunityAnswer.fromJson(Map<String, dynamic> json) {
    return CommunityAnswer(
      id: json['id'] as String? ?? '',
      postId: json['postId'] as String? ?? '',
      body: json['body'] as String? ?? '',
      voteScore: (json['voteScore'] as num?)?.toInt() ?? 0,
      isAccepted: json['isAccepted'] as bool? ?? false,
      author: CommunityAuthor.fromJson(
          (json['author'] as Map<String, dynamic>?) ?? const {}),
      myVote: (json['myVote'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  CommunityAnswer copyWith({int? voteScore, int? myVote, bool? isAccepted}) {
    return CommunityAnswer(
      id: id,
      postId: postId,
      body: body,
      voteScore: voteScore ?? this.voteScore,
      isAccepted: isAccepted ?? this.isAccepted,
      author: author,
      myVote: myVote ?? this.myVote,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, voteScore, isAccepted, myVote];
}

class CommunityPost extends Equatable {
  final String id;
  final String title;
  final String body;
  final String postType; // 'question' | 'discussion'
  final List<String> tags;
  final int viewCount;
  final int voteScore;
  final int answerCount;
  final String? acceptedAnswerId;
  final bool isResolved;
  final bool isClosed;
  final CommunityAuthor author;
  final int myVote;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<CommunityAnswer> answers;

  const CommunityPost({
    required this.id,
    required this.title,
    required this.body,
    this.postType = 'question',
    this.tags = const [],
    this.viewCount = 0,
    this.voteScore = 0,
    this.answerCount = 0,
    this.acceptedAnswerId,
    this.isResolved = false,
    this.isClosed = false,
    required this.author,
    this.myVote = 0,
    this.createdAt,
    this.updatedAt,
    this.answers = const [],
  });

  bool get isQuestion => postType == 'question';

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      postType: json['postType'] as String? ?? 'question',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const [],
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      voteScore: (json['voteScore'] as num?)?.toInt() ?? 0,
      answerCount: (json['answerCount'] as num?)?.toInt() ?? 0,
      acceptedAnswerId: json['acceptedAnswerId'] as String?,
      isResolved: json['isResolved'] as bool? ?? false,
      isClosed: json['isClosed'] as bool? ?? false,
      author: CommunityAuthor.fromJson(
          (json['author'] as Map<String, dynamic>?) ?? const {}),
      myVote: (json['myVote'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      answers: (json['answers'] as List<dynamic>?)
              ?.map((e) => CommunityAnswer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  CommunityPost copyWith({int? voteScore, int? myVote}) {
    return CommunityPost(
      id: id,
      title: title,
      body: body,
      postType: postType,
      tags: tags,
      viewCount: viewCount,
      voteScore: voteScore ?? this.voteScore,
      answerCount: answerCount,
      acceptedAnswerId: acceptedAnswerId,
      isResolved: isResolved,
      isClosed: isClosed,
      author: author,
      myVote: myVote ?? this.myVote,
      createdAt: createdAt,
      updatedAt: updatedAt,
      answers: answers,
    );
  }

  @override
  List<Object?> get props => [id, voteScore, answerCount, isResolved, myVote];
}

/// A page of community posts plus whether more pages exist.
class CommunityFeed extends Equatable {
  final List<CommunityPost> posts;
  final bool hasNext;
  final int page;

  const CommunityFeed({
    required this.posts,
    required this.hasNext,
    required this.page,
  });

  @override
  List<Object?> get props => [posts, hasNext, page];
}

class CommunityVoteResult extends Equatable {
  final String targetId;
  final int voteScore;
  final int myVote;

  const CommunityVoteResult({
    required this.targetId,
    required this.voteScore,
    required this.myVote,
  });

  factory CommunityVoteResult.fromJson(Map<String, dynamic> json) {
    return CommunityVoteResult(
      targetId: json['targetId'] as String? ?? '',
      voteScore: (json['voteScore'] as num?)?.toInt() ?? 0,
      myVote: (json['myVote'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [targetId, voteScore, myVote];
}

class CommunityTag extends Equatable {
  final String tag;
  final int count;

  const CommunityTag({required this.tag, required this.count});

  factory CommunityTag.fromJson(Map<String, dynamic> json) {
    return CommunityTag(
      tag: json['tag'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [tag, count];
}

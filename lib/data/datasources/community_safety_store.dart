import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/moderation/content_filter.dart';
import '../../domain/entities/community_entity.dart';
import 'remote_data_source.dart';

/// Decides what the signed-in user sees in the Community (App Store
/// guideline 1.2): blocked members, content they reported, and content the
/// [ContentFilter] flags are all left out.
///
/// The server is the source of truth for blocks (`/community/blocks`) and
/// filters the feed itself. This store keeps a per-account copy in shared
/// preferences so a block or report disappears from the screen at once,
/// before any request completes.
class CommunitySafetyStore extends ChangeNotifier {
  static const _blockedKeyPrefix = 'community_blocked_members_';
  static const _hiddenKeyPrefix = 'community_hidden_content_';

  final RemoteDataSource _remote;

  CommunitySafetyStore(this._remote);

  String? _userId;
  Future<void>? _loading;
  final Map<String, BlockedCommunityMember> _blocked = {};
  final Set<String> _hidden = {};

  /// Loads the cached lists for [userId], then reconciles blocks with the
  /// server in the background. Safe to call repeatedly; only a change of
  /// account reloads.
  Future<void> load(String userId) {
    if (_userId == userId && _loading != null) return _loading!;
    _userId = userId;
    _blocked.clear();
    _hidden.clear();
    final loading = _readCache(userId);
    loading.then((_) => syncBlocks());
    return _loading = loading;
  }

  /// Completes once the current account's cached lists are loaded.
  Future<void> get ready => _loading ?? Future<void>.value();

  List<BlockedCommunityMember> get blockedMembers =>
      _blocked.values.toList()..sort((a, b) => b.blockedAt.compareTo(a.blockedAt));

  bool isBlocked(String memberId) => _blocked.containsKey(memberId);

  bool allowsPost(CommunityPost post) =>
      !_blocked.containsKey(post.author.id) &&
      !_hidden.contains(post.id) &&
      !ContentFilter.anyObjectionable([post.title, post.body, ...post.tags]);

  bool allowsAnswer(CommunityAnswer answer) =>
      !_blocked.containsKey(answer.author.id) &&
      !_hidden.contains(answer.id) &&
      !ContentFilter.isObjectionable(answer.body);

  /// Hides [author] at once, then records the block on the server, which also
  /// alerts the moderation team about [target]. Set [onServer] when the server
  /// already recorded it (a report sent with `blockAuthor`). Throws if the
  /// server call fails; the member stays hidden and a retry is safe.
  Future<void> block(
    CommunityAuthor author, {
    CommunityReportTarget? target,
    bool onServer = false,
  }) async {
    _blocked[author.id] = BlockedCommunityMember(
      id: author.id,
      name: author.name,
      blockedAt: DateTime.now(),
    );
    notifyListeners();
    await _writeCache();
    if (!onServer) await _remote.blockCommunityMember(author.id, target: target);
  }

  /// Unblocks on the server first, so the member cannot come back as blocked
  /// on the next sync. Throws if the server call fails.
  Future<void> unblock(String memberId) async {
    await _remote.unblockCommunityMember(memberId);
    if (_blocked.remove(memberId) == null) return;
    notifyListeners();
    await _writeCache();
  }

  /// Hides a post or answer the user reported. The server hides it for them
  /// too once the report is filed.
  Future<void> hideContent(String contentId) async {
    if (!_hidden.add(contentId)) return;
    notifyListeners();
    await _writeCache();
  }

  /// Adopts the server's block list, and re-sends blocks made on this device
  /// that never reached it (for example while offline).
  Future<void> syncBlocks() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      final server = await _remote.getBlockedCommunityMembers();
      if (_userId != userId) return;
      final serverIds = server.map((m) => m.id).toSet();
      final unsynced =
          _blocked.values.where((m) => !serverIds.contains(m.id)).toList();
      for (final member in unsynced) {
        await _remote.blockCommunityMember(member.id);
      }
      if (_userId != userId) return;
      _blocked
        ..clear()
        ..addEntries(server.map((m) => MapEntry(m.id, m)))
        ..addEntries(unsynced.map((m) => MapEntry(m.id, m)));
      notifyListeners();
      await _writeCache();
    } catch (_) {
      // Offline or server error: keep the cached list and try on next load.
    }
  }

  Future<void> _readCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_userId != userId) return;
      final raw = prefs.getString('$_blockedKeyPrefix$userId');
      if (raw != null) {
        for (final item in jsonDecode(raw) as List<dynamic>) {
          final member =
              BlockedCommunityMember.fromJson(item as Map<String, dynamic>);
          if (member.id.isNotEmpty) _blocked[member.id] = member;
        }
      }
      _hidden.addAll(prefs.getStringList('$_hiddenKeyPrefix$userId') ?? const []);
    } catch (_) {
      // A corrupt cache must never keep the Community from loading.
    }
    notifyListeners();
  }

  Future<void> _writeCache() async {
    final userId = _userId;
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_blockedKeyPrefix$userId',
      jsonEncode(_blocked.values.map((m) => m.toJson()).toList()),
    );
    await prefs.setStringList('$_hiddenKeyPrefix$userId', _hidden.toList());
  }
}

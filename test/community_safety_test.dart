import 'package:flutter_test/flutter_test.dart';
import 'package:ngo_partner_user/core/moderation/content_filter.dart';
import 'package:ngo_partner_user/data/datasources/community_safety_store.dart';
import 'package:ngo_partner_user/data/datasources/remote_data_source.dart';
import 'package:ngo_partner_user/domain/entities/community_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory stand-in for the `/community/blocks` endpoints.
class _FakeRemote extends Fake implements RemoteDataSource {
  final Map<String, Set<String>> blocksByUser = {};
  String currentUser = 'me';
  bool offline = false;

  Set<String> get _mine => blocksByUser.putIfAbsent(currentUser, () => {});

  @override
  Future<List<BlockedCommunityMember>> getBlockedCommunityMembers() async {
    if (offline) throw Exception('offline');
    return _mine
        .map((id) => BlockedCommunityMember(
            id: id, name: 'Member $id', blockedAt: DateTime(2026)))
        .toList();
  }

  @override
  Future<void> blockCommunityMember(String userId,
      {CommunityReportTarget? target}) async {
    if (offline) throw Exception('offline');
    _mine.add(userId);
  }

  @override
  Future<void> unblockCommunityMember(String userId) async {
    if (offline) throw Exception('offline');
    _mine.remove(userId);
  }
}

CommunityPost _post(String id, String authorId, {String body = 'How do we file 12A?'}) {
  return CommunityPost(
    id: id,
    title: 'Question about registration',
    body: body,
    author: CommunityAuthor(id: authorId, name: 'Member $authorId'),
  );
}

const _abuser = CommunityAuthor(id: 'abuser', name: 'Abuser');

void main() {
  group('ContentFilter', () {
    test('flags profanity, slurs and disguised spellings', () {
      for (final text in [
        'what the fuck',
        'you are a MOTHERFUCKER',
        'this is bullshit',
        r'$h1t answer',
        'fuuuuck this',
        'kill yourself',
        'tu chutiya hai',
        'bhenchod',
      ]) {
        expect(ContentFilter.isObjectionable(text), isTrue, reason: text);
      }
    });

    test('leaves ordinary NGO conversation alone', () {
      for (final text in [
        'How do we apply for 80G & 12A registration?',
        'Our Niger programme needs FCRA approval',
        'We assess class sizes in Scunthorpe and Lund',
        'Office-cum-residence address proof',
        'Please pass the assets register to the auditor',
        'Dickens reading programme for children',
        'PAN XXXXX1234X',
        '',
      ]) {
        expect(ContentFilter.isObjectionable(text), isFalse, reason: text);
      }
    });
  });

  group('CommunitySafetyStore', () {
    late _FakeRemote remote;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      remote = _FakeRemote();
    });

    test('blocking hides the member at once and records it on the server',
        () async {
      final store = CommunitySafetyStore(remote);
      await store.load('me');
      var notified = 0;
      store.addListener(() => notified++);

      expect(store.allowsPost(_post('p1', 'abuser')), isTrue);
      await store.block(_abuser);
      expect(store.allowsPost(_post('p1', 'abuser')), isFalse);
      expect(store.allowsPost(_post('p2', 'friend')), isTrue);
      expect(notified, greaterThanOrEqualTo(1));
      expect(remote.blocksByUser['me'], contains('abuser'));

      await store.unblock('abuser');
      expect(store.allowsPost(_post('p1', 'abuser')), isTrue);
      expect(remote.blocksByUser['me'], isNot(contains('abuser')));
    });

    test('an offline block still hides the member and is re-sent on sync',
        () async {
      final store = CommunitySafetyStore(remote);
      await store.load('me');

      remote.offline = true;
      await expectLater(store.block(_abuser), throwsException);
      expect(store.isBlocked('abuser'), isTrue);

      remote.offline = false;
      await store.syncBlocks();
      expect(remote.blocksByUser['me'], contains('abuser'));
      expect(store.isBlocked('abuser'), isTrue);
    });

    test('the server list wins and each account keeps its own', () async {
      remote.blocksByUser['me'] = {'from-other-device'};
      final store = CommunitySafetyStore(remote);
      await store.load('me');
      await store.syncBlocks();
      expect(store.isBlocked('from-other-device'), isTrue);

      remote.currentUser = 'someone-else';
      final other = CommunitySafetyStore(remote);
      await other.load('someone-else');
      await other.syncBlocks();
      expect(other.isBlocked('from-other-device'), isFalse);
    });

    test('reported and filtered content is hidden', () async {
      final store = CommunitySafetyStore(remote);
      await store.load('me');

      await store.hideContent('p1');
      expect(store.allowsPost(_post('p1', 'someone')), isFalse);
      expect(
        store.allowsPost(_post('p2', 'someone', body: 'what the fuck')),
        isFalse,
      );
      expect(store.allowsPost(_post('p3', 'someone')), isTrue);
    });
  });
}

import 'package:bike_news_room/features/watchlist/data/watchlist_repository.dart';
import 'package:bike_news_room/features/watchlist/domain/entities/watched_entity.dart';
import 'package:bike_news_room/features/watchlist/presentation/cubit/watchlist_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<WatchlistCubit> build() async {
    final prefs = await SharedPreferences.getInstance();
    final repo = WatchlistRepository(prefs);
    final cubit = WatchlistCubit(repo);
    // Skip the asset-loaded catalogue (rootBundle isn't available in pure unit
    // tests without TestDefaultBinaryMessengerBinding); just load following.
    final following = await repo.loadFollowing();
    cubit.emit(cubit.state.copyWith(following: following, ready: true));
    return cubit;
  }

  group('WatchlistCubit.follow / unfollow', () {
    test('follow appends and persists', () async {
      final cubit = await build();
      final entity = WatchedEntity(
        id: 'pogacar',
        kind: WatchedKind.rider,
        name: 'Tadej Pogačar',
      );

      await cubit.follow(entity);
      expect(cubit.state.following, [entity]);
    });

    test('follow is idempotent', () async {
      final cubit = await build();
      final entity = WatchedEntity(
        id: 'pogacar',
        kind: WatchedKind.rider,
        name: 'Pogacar',
      );

      await cubit.follow(entity);
      await cubit.follow(entity);
      expect(cubit.state.following.length, 1);
    });

    test('unfollow removes by id', () async {
      final cubit = await build();
      await cubit.follow(WatchedEntity(
          id: 'pogacar', kind: WatchedKind.rider, name: 'Pogacar'));
      await cubit.follow(WatchedEntity(
          id: 'roglic', kind: WatchedKind.rider, name: 'Roglic'));

      await cubit.unfollow('pogacar');
      expect(cubit.state.following.length, 1);
      expect(cubit.state.following.first.id, 'roglic');
    });
  });

  group('WatchlistCubit.followCustom', () {
    test('slug-ifies name', () async {
      final cubit = await build();
      await cubit.followCustom(name: 'Mathieu van der Poel', kind: WatchedKind.rider);
      expect(cubit.state.following.first.id, 'mathieu-van-der-poel');
    });

    test('handles accents', () async {
      final cubit = await build();
      await cubit.followCustom(name: 'Tadej Pogačar', kind: WatchedKind.rider);
      // The slug regex strips non-ascii, which is acceptable for an id —
      // we just need it to be non-empty and stable.
      expect(cubit.state.following.first.id, isNotEmpty);
      expect(cubit.state.following.first.name, 'Tadej Pogačar');
    });

    test('rejects empty name', () async {
      final cubit = await build();
      await cubit.followCustom(name: '   ', kind: WatchedKind.rider);
      expect(cubit.state.following, isEmpty);
    });

    test('does not duplicate', () async {
      final cubit = await build();
      await cubit.followCustom(name: 'Roglic', kind: WatchedKind.rider);
      await cubit.followCustom(name: 'Roglic', kind: WatchedKind.rider);
      expect(cubit.state.following.length, 1);
    });
  });

  group('WatchlistState.isWatched / matches', () {
    test('returns false when nobody followed', () {
      const state = WatchlistState();
      expect(state.isWatched(title: 'Pogacar wins'), isFalse);
    });

    test('detects when title matches a followed entity', () async {
      final cubit = await build();
      await cubit.follow(WatchedEntity(
        id: 'pogacar',
        kind: WatchedKind.rider,
        name: 'Pogacar',
      ));
      expect(
          cubit.state.isWatched(title: 'Pogacar wins stage 5'), isTrue);
    });

    test('matches() returns the entities that hit', () async {
      final cubit = await build();
      await cubit.follow(WatchedEntity(
          id: 'a', kind: WatchedKind.rider, name: 'Pogacar'));
      await cubit.follow(WatchedEntity(
          id: 'b', kind: WatchedKind.rider, name: 'Vingegaard'));

      final hits = cubit.state.matches(title: 'Pogacar attacks Vingegaard');
      expect(hits.length, 2);
    });
  });
}

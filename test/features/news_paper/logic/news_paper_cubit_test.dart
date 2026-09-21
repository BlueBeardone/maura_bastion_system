import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maura_bastion_system/api/api_client.dart';
import 'package:maura_bastion_system/api/newspaper_api.dart';
import 'package:maura_bastion_system/data/models/news_paper/news_paper_article.dart';
import 'package:maura_bastion_system/features/bastions_page/data/filler_store.dart';
import 'package:maura_bastion_system/features/news_paper/logic/news_paper_cubit.dart';
import 'package:maura_bastion_system/features/news_paper/logic/news_paper_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  MockClient newspaperMockClient({
    required dynamic data,
    int statusCode = 200,
  }) {
    return MockClient((request) async {
      if (request.method == 'GET' &&
          request.url.path == '/maura/v1/newspapers') {
        return http.Response(
          jsonEncode({'success': true, 'message': 'ok', 'data': data}),
          statusCode,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response(
        jsonEncode({'success': false, 'message': 'unexpected'}),
        404,
        headers: {'content-type': 'application/json'},
      );
    });
  }

  NewsPaperCubit buildCubit(MockClient mock, {FillerStore? fillerStore}) {
    final apiClient = ApiClient(baseUrl: 'http://example.test', client: mock);
    return NewsPaperCubit(
      newspaperApi: NewspaperApi(client: apiClient),
      fillerStore: fillerStore,
    );
  }

  group('NewsPaperCubit.initNewsPaper', () {
    test('emits default newspaper when backend returns no articles',
        () async {
      final cubit = buildCubit(newspaperMockClient(data: []));
      await cubit.initNewsPaper();

      final state = cubit.state;
      expect(state, isA<DisplayNewsPaperState>());
      final newspapers = (state as DisplayNewsPaperState).newspapers;
      expect(newspapers.length, 1);
      expect(newspapers.first.newspaperName, 'Maura Weekly');
      expect(newspapers.first.leadArticle.title, isNotEmpty);
      expect(newspapers.first.leadArticle.imageUrl, isNull);
      expect(newspapers.first.otherArticles.length, 5);

      await cubit.close();
    });

    test('uses first backend article as lead when articles exist', () async {
      final cubit = buildCubit(newspaperMockClient(data: [
        {
          'title': 'Frontline Dispatch',
          'content': 'Something happened at the pass.',
          'imageUrl': null,
          'author': 'A Correspondent',
        },
        {
          'title': 'Tavern News',
          'content': 'Ale prices unchanged.',
          'imageUrl': null,
          'author': null,
        },
      ]));
      await cubit.initNewsPaper();

      final state = cubit.state;
      expect(state, isA<DisplayNewsPaperState>());
      final newspapers = (state as DisplayNewsPaperState).newspapers;
      expect(newspapers.length, 1);
      expect(newspapers.first.leadArticle.title, 'Frontline Dispatch');
      expect(newspapers.first.otherArticles.length, 1);
      expect(newspapers.first.otherArticles.first.title, 'Tavern News');

      await cubit.close();
    });

    test('emits error state when API fails', () async {
      final cubit =
          buildCubit(newspaperMockClient(data: null, statusCode: 500));
      await cubit.initNewsPaper();

      expect(cubit.state, isA<ErrorNewsPaperState>());

      await cubit.close();
    });

    test('pads thin editions with local fillers, shared lead first', () async {
      SharedPreferences.setMockInitialValues({});
      final store = FillerStore();
      await store.append('b1', NewspaperArticle(
        title: 'FILLER ONE', content: 'c', imageUrl: null, author: 'A Correspondent'));
      await store.append('b1', NewspaperArticle(
        title: 'FILLER TWO', content: 'c', imageUrl: null, author: 'A Correspondent'));

      final cubit = buildCubit(newspaperMockClient(data: [
        {
          'title': 'Frontline Dispatch',
          'content': 'Something happened.',
          'imageUrl': null,
          'author': 'A Correspondent',
        },
      ]), fillerStore: store);
      await cubit.initNewsPaper();

      final papers =
          (cubit.state as DisplayNewsPaperState).newspapers;
      expect(papers.first.leadArticle.title, 'Frontline Dispatch');
      expect(
        papers.first.otherArticles.map((a) => a.title),
        ['FILLER TWO', 'FILLER ONE'], // latest filler first
      );
      await cubit.close();
    });

    test('full editions are not padded', () async {
      SharedPreferences.setMockInitialValues({});
      final store = FillerStore();
      await store.append('b1', NewspaperArticle(
        title: 'FILLER ONE', content: 'c', imageUrl: null, author: null));

      final cubit = buildCubit(newspaperMockClient(data: [
        {'title': 'A', 'content': 'c', 'imageUrl': null, 'author': null},
        {'title': 'B', 'content': 'c', 'imageUrl': null, 'author': null},
        {'title': 'C', 'content': 'c', 'imageUrl': null, 'author': null},
      ]), fillerStore: store);
      await cubit.initNewsPaper();

      final papers = (cubit.state as DisplayNewsPaperState).newspapers;
      expect(papers.first.otherArticles.map((a) => a.title), ['B', 'C']);
      await cubit.close();
    });

    test('latest filler becomes lead when no shared articles', () async {
      SharedPreferences.setMockInitialValues({});
      final store = FillerStore();
      await store.append('b1', NewspaperArticle(
        title: 'OLDER FILLER', content: 'c', imageUrl: null, author: null));
      await store.append('b1', NewspaperArticle(
        title: 'LATEST FILLER', content: 'c', imageUrl: null, author: null));

      final cubit = buildCubit(newspaperMockClient(data: []), fillerStore: store);
      await cubit.initNewsPaper();

      final papers = (cubit.state as DisplayNewsPaperState).newspapers;
      expect(papers.first.leadArticle.title, 'LATEST FILLER');
      expect(papers.first.otherArticles.map((a) => a.title), ['OLDER FILLER']);
      await cubit.close();
    });

    test('filler read failures are swallowed', () async {
      final explodingStore = _ExplodingFillerStore();
      final cubit = buildCubit(newspaperMockClient(data: [
        {'title': 'A', 'content': 'c', 'imageUrl': null, 'author': null},
        {'title': 'B', 'content': 'c', 'imageUrl': null, 'author': null},
        {'title': 'C', 'content': 'c', 'imageUrl': null, 'author': null},
      ]), fillerStore: explodingStore);
      await cubit.initNewsPaper();

      expect(cubit.state, isA<DisplayNewsPaperState>());
      await cubit.close();
    });
  });
}

class _ExplodingFillerStore extends FillerStore {
  @override
  Future<List<NewspaperArticle>> readAll() async => throw Exception('boom');
}

import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/models/news_paper/news_paper_article.dart';
import 'package:maura_bastion_system/features/bastions_page/data/filler_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

NewspaperArticle _article(String title) => NewspaperArticle(
      title: title,
      content: 'Content for $title.',
      imageUrl: null,
      author: 'A Correspondent',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('append then read round-trips articles', () async {
    SharedPreferences.setMockInitialValues({});
    final store = FillerStore();
    await store.append('b1', _article('FIRST'));
    await store.append('b1', _article('SECOND'));

    final read = await store.read('b1');
    expect(read.map((a) => a.title), ['FIRST', 'SECOND']);
    expect(read.first.author, 'A Correspondent');
  });

  test('history is capped at the 10 most recent', () async {
    SharedPreferences.setMockInitialValues({});
    final store = FillerStore();
    for (var i = 0; i < 12; i++) {
      await store.append('b1', _article('N$i'));
    }

    final read = await store.read('b1');
    expect(read.length, 10);
    expect(read.first.title, 'N2');
    expect(read.last.title, 'N11');
  });

  test('bastions are stored independently', () async {
    SharedPreferences.setMockInitialValues({});
    final store = FillerStore();
    await store.append('b1', _article('FOR_B1'));
    await store.append('b2', _article('FOR_B2'));

    expect((await store.read('b1')).single.title, 'FOR_B1');
    expect((await store.read('b2')).single.title, 'FOR_B2');
  });

  test('readAll merges across bastions', () async {
    SharedPreferences.setMockInitialValues({});
    final store = FillerStore();
    await store.append('b1', _article('B1_A'));
    await store.append('b2', _article('B2_A'));
    await store.append('b1', _article('B1_B'));

    final all = await store.readAll();
    expect(all.map((a) => a.title), containsAll(['B1_A', 'B1_B', 'B2_A']));
    expect(all.length, 3);
  });

  test('read of corrupt data is empty, no throw', () async {
    SharedPreferences.setMockInitialValues({'fillers_b1': 'not json'});
    final store = FillerStore();
    expect(await store.read('b1'), isEmpty);
  });

  test('read skips corrupt entries but keeps good ones', () async {
    SharedPreferences.setMockInitialValues({
      'fillers_b1':
          '[{"title":"GOOD","content":"c"},{"nope":true},{"title":5,"content":"c"}]',
    });
    final store = FillerStore();
    final read = await store.read('b1');
    expect(read.single.title, 'GOOD');
  });
}

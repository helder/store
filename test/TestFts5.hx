package test;

import helder.store.sqlite.SqliteStore;
import test.DbSuite.dbSuite;
import test.db.Node.Node;
using test.db.Node;

final TestFts5 = dbSuite(test -> {
  #if !sql.js
  test('Fts5', () -> {
    final store: SqliteStore = new Store();
    final Search = new Collection<{id: String, title: String, body: String}>('Search', {
      flat: true,
      columns: ['id', 'title', 'body']
    });
    store.createFts5Table(Search, 'Search', search -> {
      return {title: search.title, body: search.body}
    });
    final record1 = store.insert(Search, {
      title: 'my title',
      body: 'my bodytext'
    });
    final record2 = store.insert(Search, {title: 'c', body: 'd'});
    assert.is(
      store.first(Search.where(Search.title.match('my'))).title,
      record1.title
    );
    assert.is(store.first(Search.where(Search.title.match('c'))).id, record2.id);
    final addFields = store.first(
      Search.where(Search.title.match('my')).select(
        Search.with({
          int: Expression.value(123)
        })
      )
    );
    assert.is(addFields.int, 123);
    assert.is(addFields.title, record1.title);
  });
  #end
});
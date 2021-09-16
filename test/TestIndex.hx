package test;

import test.DbSuite.dbSuite;
import test.db.Node.Node;
using test.db.Node;

final TestIndex = dbSuite(test -> {

  test('Index property', () -> {
    final db = new Store();
    assert.not.throws(() -> 
      db.createIndex(Node, 'index', [Node.index])
    );
  });

});
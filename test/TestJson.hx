package test;

import haxe.Json;
import test.DbSuite.dbSuite;
import helder.Unit.suite;
import helder.store.Cursor;

final TestJson = dbSuite(test -> {

  test('Basic', () -> {
    final db = new Store();
    final Node = new Collection<{id: String, index: Int, ?empty: String}>('node');
    final amount = 10;
    final objects = [for (i in 0 ... amount) {index: i}];
    assert.is(objects.length, amount);
    final stored = db.insertAll(Node, objects);
    assert.is(db.count(Node), amount);
    final q = Node.where(Node.index.is(1)).select({
      fieldA: Expression.value(12),
      fieldB: Node.index
    });
    final res1 = db.first(q);
    assert.is(res1.fieldA, 12);
    assert.is(res1.fieldB, 1);
    final res2 = db.first(Cursor.fromJSON(q.toJSON()));
    assert.is(res2.fieldA, 12);
    assert.is(res2.fieldB, 1);
  });

});
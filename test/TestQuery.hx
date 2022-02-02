package test;

import helder.store.Query.query;
import test.DbSuite.dbSuite;
import helder.Unit.suite;

final Test = new Collection<{id: String, prop: Int}>('test');

final byProp = query(vars -> Test.where(Test.prop.is(vars.prop)));

final TestQuery = dbSuite(test -> {

  test('Query', () -> {
    final db = new Store();
    final a = {prop: 10}
    final b = {prop: 20}
    db.insertAll(Test, [a, b]);
    final shouldBeA = db.first(byProp({prop: 10}));
    assert.is(shouldBeA.prop, 10);
    final shouldBeB = db.first(byProp({prop: 20}));
    assert.is(shouldBeB.prop, 20);
  });

});
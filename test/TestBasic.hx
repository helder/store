package test;

import helder.Unit.suite;

final TestBasic = suite(test -> {

  test('Basic', () -> {
    final db = new Store();
    final Node = new Collection<{id: String, index: Int}>('node');
    final amount = 10;
    final objects = [for (i in 0 ... amount) {index: i}];
    assert.is(objects.length, amount);
    final stored = db.insertAll(Node, objects);
    assert.is(db.count(Node), amount);
    final id = stored[amount - 1].id;
    assert.is(
      db.first(
        Node.where(Node.index >= amount - 1 && Node.index < amount)
      ).id,
      id
    );
  });

  test('Filters', () -> {
    final db = new Store();
    final Test = new Collection<{id: String, prop: Int}>('test');
    final a = {prop: 10}
    final b = {prop: 20}
    db.insertAll(Test, [a, b]);
    final gt10 = db.first(Test.where(Test.prop > 10));
    assert.is(gt10.prop, 20);
  });

  test('Limit', () -> {
    final db = new Store();
    final Test = new Collection<{id: String, prop: Int}>('test');
    final a = {prop: 10}
    db.insertAll(Test, [a, a, a, a]);
    final two = Test.take(2);
    assert.is(db.count(two), 2);
    final one = Test.skip(3).take(2);
    assert.is(db.count(one), 1);
  });
  
  test('Stuctures', () -> {
    final db = new Store();
    final Test = new Collection<{id: String, a: Int}>('test');
    db.insert(Test, {a: 25});
    assert.is(db.first(Test.where(Test.a in [25])).a, 25);
    assert.is(db.first(Test.where(
      Test.a.isNotIn([1, 1])
    )).a, 25);
    final Structure = new Collection<{id: String, deep: {structure: Int}}>('structure');
    db.insert(Structure, {deep: {structure: 1}});
    assert.is(
      db.first(Structure.where(Structure.deep.structure == 0)),
      null
    );
    assert.not.is(
      db.first(Structure.where(Structure.deep.structure == 1)),
      null
    );
  });

});
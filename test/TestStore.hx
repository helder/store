package test;

import helder.store.Collection;
import helder.store.sqlite.SqliteStore as Store;

@:asserts
class TestStore {
  public function new() {}

  public function testBasic() {
    final db = new Store();
    final Node = new Collection<{index: Int}>('node');
	  final amount = 10;
	  final objects = [for (i in 0 ... amount) {index: i}];
	  asserts.assert(objects.length == amount);
	  final stored = db.insert(Node, objects);
	  asserts.assert(db.count(Node) == amount);
	  final id = stored[amount - 1].id;
    final last = db.first(
      Node.where(Node.index >= amount - 1 && Node.index < amount)
    );
    asserts.assert(
      last.id == id
    );
    return asserts.done();
  }

  public function testFilters() {
    final db = new Store();
    final Test = new Collection<{prop: Int}>('test');
    final a = {prop: 10}
    final b = {prop: 20}
    db.insert(Test, [a, b]);
    final gt10 = db.first(Test.where(Test.prop > 10));
    return assert(gt10.prop == 20);
  }

  public function testLimit() {
    final db = new Store();
    final Test = new Collection<{prop: Int}>('test');
    final a = {prop: 10}
    db.insert(Test, [a, a, a, a]);
    final two = Test.take(2);
    asserts.assert(db.count(two) == 2);
    final one = Test.skip(3).take(2);
    asserts.assert(db.count(one) == 1);
    return asserts.done();
  }

  public function testStuctures() {
    final db = new Store();
    final Test = new Collection<{a: Int}>('test');
    db.insertOne(Test, {a: 25});
    asserts.assert(db.first(Test.where(Test.a in [25])).a == 25);
    asserts.assert(db.first(Test.where(
      Test.a.isNotIn([1, 1])
    )).a == 25);
    final Structure = new Collection<{deep: {structure: Int}}>('structure');
    db.insertOne(Structure, {deep: {structure: 1}});
    asserts.assert(
      db.first(Structure.where(Structure.deep.structure == 0))
      == null
    );
    asserts.assert(
      db.first(Structure.where(Structure.deep.structure == 1))
      != null
    );
    return asserts.done();
  }
}
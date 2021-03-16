package test;

import helder.store.Collection;
import helder.store.sqlite.SqliteStore in Store;
import helder.store.sqlite.Functions;
import helder.store.Expression;
import tink.Anon.merge;

@:asserts
class TestStore {
  public function new() {}

  public function testBasic() {
    final db = new Store();
    final Node = new Collection<{id: String, index: Int}>('node');
	  final amount = 10;
	  final objects = [for (i in 0 ... amount) {index: i}];
	  asserts.assert(objects.length == amount);
	  final stored = db.insert(Node, objects);
	  asserts.assert(db.count(Node) == amount);
	  final id = stored[amount - 1].id;
    asserts.assert(
      db.first(
        Node.where(Node.index >= amount - 1 && Node.index < amount)
      ).id == id
    );
    return asserts.done();
  }

  public function testFilters() {
    final db = new Store();
    final Test = new Collection<{id: String, prop: Int}>('test');
    final a = {prop: 10}
    final b = {prop: 20}
    db.insert(Test, [a, b]);
    final gt10 = db.first(Test.where(Test.prop > 10));
    return assert(gt10.prop == 20);
  }

  public function testLimit() {
    final db = new Store();
    final Test = new Collection<{id: String, prop: Int}>('test');
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
    final Test = new Collection<{id: String, a: Int}>('test');
    db.insertOne(Test, {a: 25});
    asserts.assert(db.first(Test.where(Test.a in [25])).a == 25);
    asserts.assert(db.first(Test.where(
      Test.a.isNotIn([1, 1])
    )).a == 25);
    final Structure = new Collection<{id: String, deep: {structure: Int}}>('structure');
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

  public function testIncludeMany() {
    final db = new Store();
    final Role = new Collection<{id: String, name: String}>('Role');
    final role1 = db.insertOne(Role, {name: 'role1'});
    final role2 = db.insertOne(Role, {name: 'role2'});
    final User = new Collection<{id: String, roles: Array<String>}>('User');
    final user = db.insertOne(User, {roles: [role1.id, role2.id]});
    final UserAlias = User.as('user1');
    final RoleAlias = Role.as('role');
    final bundled = db.first(
      UserAlias.select(
        UserAlias.fields.with({
          roles: RoleAlias.where(RoleAlias.id.isIn(UserAlias.roles)).select({
            name: RoleAlias.name
          }).orderBy([RoleAlias.name.asc()])
        })
      )
    );
    asserts.compare( 
      [{name: 'role1'}, {name: 'role2'}],
      bundled.roles
    );
    final Entry = new Collection<{id: String}>('Entry');
    final Language = new Collection<{id: String, entry: String}>('Language');
    final Version = new Collection<{id: String, language: String}>('Version');
    final entry = db.insertOne(Entry, {});
    final language = db.insertOne(Language, {entry: entry.id});
    final version1 = db.insertOne(Version, {
      language: language.id
    });
    final version2 = db.insertOne(Version, {
      language: language.id
    });
    final page = db.first(
      Entry.select(
        Entry.fields.with({
          languages: Language.where(Language.entry.is(Entry.id)).select(
            Language.fields.with({
              versions: Version.where(Version.language.is(Language.id))
            })
          )
        })
      )
    );
    asserts.compare(merge(entry, {
      languages: [
        merge(language, {
          versions: [version1, version2]
        })
      ]
    }), page);
    return asserts.done();
  }

  public function testFunctions() {
  final store = new Store();
  final User = new Collection<{id: String, birthdate: String}>('User');
  final now = '1920-01-01';
  final age: Expression<Int> = 
    Functions.strftime('%Y', now)
    .substract(
      Functions.castAs(
        Functions.strftime('%Y', User.birthdate), 
        'integer'
      )
    )
    .substract(
      Functions.castAs(
        Functions.strftime('%m-%d', now).less(
          Functions.strftime('%m-%d', User.birthdate)
        ), 
        'integer'
      )
    );
  final me = store.insertOne(User, {birthdate: '1900-01-01'});
  return assert(
    store.first(User.select({age: age}).where(User.id.is(me.id))).age
    ==
    20
  );
  }
}
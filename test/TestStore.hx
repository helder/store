package test;

import helder.store.Collection;
import helder.store.sqlite.SqliteStore in Store;
import tink.Anon.*;

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
    asserts.assert(
      db.first(
        Node.where(Node.index >= amount - 1 && Node.index < amount)
      ).id == id
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

  public function testIncludeMany() {
    final db = new Store();
    final Role = new Collection<{name: String}>('Role');
    final role1 = db.insertOne(Role, {name: ('role1')});
    final role2 = db.insertOne(Role, {name: ('role2')});
    final User = new Collection<{roles: Array<String>}>('User');
    final user = db.insertOne(User, {roles: [role1.id, role2.id]});
    final UserAlias = User.as('user1');
    final RoleAlias = Role.as('role');
    final bundled = db.first(
      UserAlias.select(
        UserAlias.fields().with({
          roles: RoleAlias.where(RoleAlias.id.isIn(UserAlias.roles)).select({
            name: RoleAlias.name
          })
        })
      )
    );
    asserts.compare( 
      [{name: 'role1'}, {name: 'role2'}],
      bundled.roles
    );
    /*
    final entry = db.insertOne(Test, {type: 'entry'});
    final language = db.insertOne(Test, {type: 'language', entry: entry.id});
    final version1 = db.insertOne(Test, {
      type: 'version1',
      language: language.id
    });
    final version2 = db.insertOne(Test, {
      type: 'version2',
      language: language.id
    });
    final Entry = Test.as('entry');
    final Language = Test.as('language');
    final Version = Test.as('version');
    final page = db.sure(
      Entry.where(Entry.type.is('entry')).select(
        Entry.fields.with({
          languages: Language.where(Language.entry.is(Entry.id)).select(
            Language.fields.with({
              versions: Version.where(Version.language.is(Language.id))
            })
          )
        })
      )
    );
    asserts.compare(page, entry.merge({
      languages: [{versions: [version1, version2]}]
    }));*/
    return asserts.done();
  }
}
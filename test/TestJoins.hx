package test;

import test.DbSuite.dbSuite;

typedef Entry = {
  id: String,
  type: String,
  num: Int
}

final TestJoins = dbSuite(test -> {

  test('OrderBy', () -> {
    final store = new Store();
    final User = new Collection<{id: String, name: String}>('user');
    final Contact = new Collection<{id: String, user: String}>('contact');
    final user1 = store.insert(User, {name: 'b'});
    final user2 = store.insert(User, {name: 'a'});
    final contact1 = store.insert(Contact, {user: user1.id});
    final contact2 = store.insert(Contact, {user: user2.id});
    final results = store.all(
      Contact
        .leftJoin(User, User.id == Contact.user)
        .select(
          Contact.fields.with({
            user: User.fields
          })
        )
        .orderBy(User.name.asc())
    );
    assert.is(results[0].user.name, 'a');
    assert.is(results[1].user.name, 'b');
  });

  test('Cursor joins', () -> {
    final store = new Store();
    final Entry = new Collection<Entry>('Entry');
    final Type1 = new Collection<Entry>('Entry', {where: Entry.as('Type1').type == 'Type1', alias: 'Type1'});
    final Type2 = new Collection<Entry>('Entry', {where: Entry.as('Type2').type == 'Type2', alias: 'Type2'});
    store.insert(Entry, {type: 'Type1', num: 1});
    store.insert(Entry, {type: 'Type2', num: 1});
    store.insert(Entry, {type: 'Type3', num: 1});
    final res = store.first(Type1.leftJoin(Type2, Type1.num == Type2.num).select(
      Type1.fields.with({
        linked: Type2.fields
      })
    ));
    assert.is(res.linked.type, 'Type2');
  });

});
package test;

@:asserts
class TestJoins {
  public function new() {}
      
  public function testOrderBy() {
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
        .orderBy([User.name.asc()])
    );
    asserts.assert(results[0].user.name == 'a');
    asserts.assert(results[1].user.name == 'b');
    return asserts.done();
  }
}
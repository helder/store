package test;

@:asserts
class TestUpdate {
  public function new() {}

  public function testUpdate() {
    final db = new Store();
    final user = db.insert(User, {
      name: {
        given: 'abc', 
        last: 'test'
      }
    });
    final res = db.update(User.where(User.id == user.id), {
      email: 'test'
    });
    asserts.assert(res.changes == 1);
    asserts.assert(db.first(User).email == 'test');
    final res2 = db.update(User.where(User.id == user.id), {
      email: User.email.concat('@example.com')
    });
    asserts.assert(res2.changes == 1);
    asserts.assert(db.first(User).email == 'test@example.com');
    final res3 = db.update(User.where(User.id == user.id), {
      name: {
        given: 'def',
        last: 'okay'
      }
    });
    asserts.assert(res3.changes == 1);
    asserts.assert(db.first(User).name.given == 'def');
    return asserts.done();
  }
}
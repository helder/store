package test;

final TestUpdate = suite(test -> {

  test('Update', () -> {
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
    assert.is(res.changes, 1);
    assert.is(db.first(User).email, 'test');
    final res2 = db.update(User.where(User.id == user.id), {
      email: User.email.concat('@example.com')
    });
    assert.is(res2.changes, 1);
    assert.is(db.first(User).email, 'test@example.com');
    final res3 = db.update(User.where(User.id == user.id), {
      name: {
        given: 'def',
        last: 'okay'
      }
    });
    assert.is(res3.changes, 1);
    assert.is(db.first(User).name.given, 'def');
  });

});
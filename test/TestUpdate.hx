package test;

import test.DbSuite.dbSuite;

final TestUpdate = dbSuite(test -> {

  final db = new Store();

  test('Update', () -> {
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

  test('Update object', () -> {
    final user = db.insert(User, {
      name: {
        given: 'abc', 
        last: 'test'
      }
    });
    final res = db.update(User.where(User.id == user.id), {
      name: {
        given: '123', 
        last: '456'
      }
    });
    assert.is(res.changes, 1);
    final user2 = db.first(User.where(User.id == user.id));
    assert.is(user2.name.given, '123');
    assert.is(user2.name.last, '456');
  });

});
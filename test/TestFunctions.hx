package test;

import test.DbSuite.dbSuite;

final TestFunctions = dbSuite(test -> {

  test('Functions', () -> {
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
    final me = store.insert(User, {birthdate: '1900-01-01'});
    assert.is(
      store.first(User.select({age: age}).where(User.id.is(me.id))).age,
      20
    );
  });

});
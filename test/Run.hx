package test;

import test.db.User;
import test.db.Schema.User;

function main() {
  final test: User = {name: {given: 'a', last: 'b'}}
  trace(User.select({
    id: User.id
  }).where(
    User.name.given.is('test')
      .and(User.id.is('abc'))
  ));
  trace(User.id.greater('test'));
}
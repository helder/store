package test;

import helder.store.Collection;

typedef User = {name: String}
final db = {
  User: new Collection<User>('User')
}

function main() {
  trace(db.User.id.greater('test'));
}
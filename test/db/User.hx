package test.db;

typedef User = {
  id: String,
  name: {
    given: String,
    last: String
  },
  ?email: String
}

package helder.store;

import helder.store.Expression.Expr;

enum JoinType {
  Left;
  Inner;
}

enum From {
  Table(name: String, ?alias: String);
  Join(left: From, right: From, type: JoinType, on: Expr);
  Column(of: From, column: String);
}
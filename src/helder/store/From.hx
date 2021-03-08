package helder.store;

import helder.store.Expression.Expr;

enum JoinType {
  Left;
  Inner;
}

@:using(helder.store.From.FromTools) enum From {
  Table(name: String, ?alias: String);
  Join(left: From, right: From, type: JoinType, on: Expr);
  Column(of: From, column: String);
}

class FromTools {
  public static function source(from: From): String {
    return switch from {
			case Column(Table(name, alias), _) | Table(name, alias):
        if (alias != null) alias else name;
			default: throw 'Cannot from join';
		}
  }
}
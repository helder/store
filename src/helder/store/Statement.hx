package helder.store;

class StatementImpl {
  public final sql: String;
  public final params: Array<Any>;

  public function new(sql: String, params: Array<Any>) {
    this.sql = sql;
    this.params = params;
  }

  public function wrap(adder: (sql: String) -> Statement) {
    final a = this;
    final b = adder(sql);
    return new Statement(
      b.sql, a.params.concat(b.params)
    );
  }
}

@:forward
abstract Statement(StatementImpl) {
  public function new(sql: String, params: Array<Any>)
    this = new StatementImpl(sql, params);
  @:from public static function fromString(str: String) {
    return new Statement(str, []);
  }
  @:op(a+b) public function add(that: Statement) {
    return new Statement(
      this.sql + ' ' + that.sql, 
      this.params.concat(that.params)
    );
  }
}
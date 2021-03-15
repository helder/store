package helder.store.sqlite;

import helder.store.sqlite.SqliteConnection;
import better_sqlite3.Database;

class BetterSqlite3Connection implements SqliteConnection {
  final db: Database;
  public function new(file: String = ':memory:', ?options: SqliteConnectionOptions)
    db = BetterSqlite3.call(file, (cast options: better_sqlite3.Options));
  public function exec(sql: String)
    db.exec(sql);
  public function pragma(sql: String) 
    db.pragma(sql);
  public function prepare(sql: String): SqliteStatement
    return new Statement(db.prepare(sql));
  public function transaction<T>(run: () -> T): T
    return db.transaction(run).call();
}

typedef PreparedStatement = {
  function pluck(bool: Bool): PreparedStatement;
  function all<T>(...params: Dynamic): Array<T>;
  function run<T>(...params: Dynamic): {changes: Int};
  function get<T>(...params: Dynamic): T;
}

private class Statement {
  final stmt: PreparedStatement;
  public function new(stmt: PreparedStatement)
    this.stmt = stmt;
  public function all<T>(params: Array<Dynamic>): Array<T>
    return stmt.pluck(true).all(...params);
  public function run<T>(params: Array<Dynamic>): {changes: Int}
  return stmt.run(...params);
  public function get<T>(params: Array<Dynamic>): T
    return stmt.pluck(true).get(...params);
}

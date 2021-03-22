package helder.store.sqlite;

import helder.store.sqlite.SqliteConnection;
import php.db.SQLite3;
import php.db.SQLite3Stmt;
import uuid.Uuid;

class Sqlite3Connection implements SqliteConnection {
  final db: SQLite3;
  private static var transactionId = 0;
  public function new(file: String = ':memory:', ?options: SqliteConnectionOptions) {
    db = new SQLite3(file);
    db.enableExceptions(true);
  }
  public function exec(sql: String)
    db.exec(sql);
  public function prepare(sql: String): SqliteStatement
    return new Statement(db, db.prepare(sql));
  public function transaction<T>(run: () -> T): T {
    final id = 't${transactionId++}';
    exec('savepoint $id');
    try {
      final res = run();
      exec('release $id');
      return res;
    } catch(e) {
      exec('rollback to $id');
      throw e;
    }
  }
}

private class Statement {
  final db: SQLite3;
  final stmt: SQLite3Stmt;
  public function new(db, stmt: SQLite3Stmt) {
    this.db = db;
    this.stmt = stmt;
  }
  public function all<T>(params: Array<Dynamic>): Array<T> {
    for (i in 0 ... params.length) stmt.bindValue(i + 1, params[i]);
    final res = [];
    final resultSet = stmt.execute();
    while (true) {
      final row = resultSet.fetchArray(2);
      if (row == false) break;
      res.push((row: Dynamic)[0]);
    }
    resultSet.finalize();
    return cast res;
  }
  public function run<T>(params: Array<Dynamic>): {changes: Int} {
    for (i in 0 ... params.length) stmt.bindValue(i + 1, params[i]);
    stmt.execute();
    return {changes: db.changes()}
  }
  public function get<T>(params: Array<Dynamic>): T {
    return all(params)[0];
  }
}
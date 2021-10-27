package test;

import helder.store.sqlite.SqliteStore;
import helder.store.sqlite.drivers.*;

@:forward
abstract Memory(SqliteStore) {
  public function new()
    this = new SqliteStore(
      #if sqljs new SqlJs(new SqlJs.Database())
      #elseif js new BetterSqlite3()
      #elseif php new Sqlite3()
      #else #error 'Not supported' #end,
      () -> uuid.Uuid.nanoId()
    );
} 
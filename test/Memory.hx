package test;

import helder.store.sqlite.SqliteStore;

@:forward
abstract Memory(SqliteStore) {
  public function new()
    this = new SqliteStore(
      #if sqljs new helder.store.drivers.SqlJs(
        new helder.store.drivers.SqlJs.Database()
      )
      #elseif js new helder.store.drivers.BetterSqlite3()
      #elseif php new helder.store.drivers.Sqlite3()
      #else #error 'Not supported' #end
    );
} 
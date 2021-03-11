package helder.store.sqlite;

typedef SqliteStore =
  #if js helder.store.sqlite.BetterSqlite3Store;
  #else #error 'Not available on this platform' #end

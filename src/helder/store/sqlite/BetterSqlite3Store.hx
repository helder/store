package helder.store.sqlite;

import helder.store.FormatCursor.formatCursorDelete;
import helder.store.FormatCursor.formatCursorSelect;
import helder.store.sqlite.SqlEscape.escape;
import helder.store.sqlite.SqlEscape.escapeId;
import haxe.Json;
import uuid.Uuid;
import BetterSqlite3;
import helder.store.FormatCursor.FormatCursorContext;
import better_sqlite3.Database;
import helder.Store;

@:jsRequire('better-sqlite3-with-prebuilds', 'SqliteError')
extern class SqliteError {
  final message: String;
}

typedef SqliteStoreOptions = {
  ?readonly: Bool
}

function formatField(path: Array<String>) {
  return switch path {
    case []: throw 'assert';
    case [from]: escapeId(from);
    default: 
      final target = escapeId(path[0]) + '.' + escapeId(path[1]);
      if (path.length == 2) return target;
      final rest = "$." + path.slice(2).join('.');
      'json_extract($target, ${escape(rest)})';
  }
}

final context: FormatCursorContext = {
  formatInline: false,
  formatSubject: (selection) -> selection,
  formatAccess: (on, field) -> 'json_extract(${on}, \'$.${field}\')',
  formatField: formatField,
  escape: escape,
  escapeId: escapeId
}

typedef PreparedStatement = {
  function pluck(bool: Bool): PreparedStatement;
  function all<T>(params: haxe.Rest<Dynamic>): Array<T>;
  function run<T>(params: haxe.Rest<Dynamic>): {changes: Int};
  function get<T>(params: haxe.Rest<Dynamic>): T;
}

class BetterSqlite3Store implements Store {
  final db: Database;

  public function new(file: String = ':memory:', ?options: better_sqlite3.Options) {
    this.db = BetterSqlite3.call(file, options);
    this.db.pragma('journal_mode = WAL');
    this.db.pragma('optimize');
  }

  public function all<Row:{}, R:Row&Document>(cursor: Cursor<Row>): Array<R> {
    final stmt = formatCursorSelect(cursor, context);
    final prepared = prepare(stmt.sql);
    return prepared
      .pluck(true)
      .all(...stmt.params)
      .map((col: String) -> haxe.Json.parse(col));
  }

  public function first<Row:{}, R:Row&Document>(cursor: Cursor<Row>): Null<R> {
    return all(cursor.take(1))[0];
  }

  public function delete<Row:{}>(cursor: Cursor<Row>): {changes: Int} {
    final stmt = formatCursorDelete(cursor, context);
    final prepared = prepare(stmt.sql);
    return prepared.run(...stmt.params);
  }

  public function count<Row:{}>(cursor: Cursor<Row>): Int {
    final stmt = formatCursorSelect(cursor, context);
    return prepare('select count(*) from (${stmt.sql})')
      .pluck(true)
      .get(...stmt.params);
  }
  
  public function insert<Row:{}, R:Row&Document>(
    collection: Collection<Row>, 
    objects: Array<Row>
  ): Array<R> {
    final table = escapeId(switch collection.cursor.from {
      case Table(name, _) | Column(Table(name, _), _): name;
      default: throw 'assert';
    });
    for (document in objects) {
      // TODO don't mutate
      if (!Reflect.hasField(document, 'id'))
        Reflect.setField(document, 'id', Uuid.nanoId());
      prepare('insert into ${table} values (?)').run(
        Json.stringify(document)
      );
    }
    return cast objects;
  }

  public function insertOne<Row:{}, R: Row & Document>(
    collection: Collection<Row>, 
    object: Row
  ): R {
    return insert(collection, [object])[0];
  }

  public function save<Row:{}>(collection: Collection<Row>, objects: Array<Row>): Array<Row> {
    final update = db.transaction(() -> {

    });
    update.call();
    return objects;
  }

  public function saveOne<Row:{}>(collection: Collection<Row>, object: Row): Row {
    return save(collection, [object])[0];
  }

  public function transaction<T>(run: () -> T): T {
    return db.transaction(run).call();
  }

  function prepare(query: String): PreparedStatement {
    trace(query);
    return createOnError(() -> db.prepare(query));
  }

  function createOnError<T>(run: () -> T): T {
    function next(?retry: String): T {
      try return run()
      catch (e: SqliteError) {
        final NO_TABLE = 'no such table: ';
        if (e.message.startsWith(NO_TABLE)) {
          final table = e.message.substr(NO_TABLE.length).split('.').pop();
          if (retry != table) {
            createTable(table);
            return next(table);
          }
        }
        throw e;
      }
    }
    return next();
  }

  function createTable(name: String) {
    db.exec('
      create table if not exists ${escapeId(name)}(data json);
      create index if not exists 
        ${escape([name, 'id'].join('.'))} 
        on ${escapeId(name)}(json_extract(data, \'$.id\'));
    ');
  }
}
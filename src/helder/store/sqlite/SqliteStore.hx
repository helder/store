package helder.store.sqlite;

import helder.store.FormatCursor.formatCursorUpdate;
import helder.store.FormatCursor.formatWhere;
import helder.store.FormatCursor.formatCursorDelete;
import helder.store.FormatCursor.formatCursorSelect;
import helder.store.sqlite.SqlEscape.escape;
import helder.store.sqlite.SqlEscape.escapeId;
import helder.store.sqlite.SqliteConnection;
import haxe.Json;
import uuid.Uuid;
import helder.store.FormatCursor.FormatCursorContext;
import helder.Store;

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
  formatUnwrapArray: sql -> '(select value from json_each($sql))',
  escape: escape,
  escapeId: escapeId
}

typedef Connection =
  #if js BetterSqlite3Connection;
  #elseif php Sqlite3Connection;
  #else #error 'Not available on this platform' #end

class SqliteStore implements Store {
  final db: SqliteConnection;

  public function new(file: String = ':memory:', ?options: SqliteConnectionOptions) {
    this.db = new Connection(file, options);
    this.db.exec('PRAGMA journal_mode = WAL');
    this.db.exec('PRAGMA optimize');
  }

  public function all<Row>(cursor: Cursor<Row>): Array<Row> {
    final stmt = formatCursorSelect(cursor, context);
    return prepare(stmt.sql)
      .all(stmt.params)
      .map((col: String) -> haxe.Json.parse(col));
  }

  public function first<Row>(cursor: Cursor<Row>): Null<Row> {
    return all(cursor.take(1))[0];
  }

  public function delete<Row>(cursor: Cursor<Row>): {changes: Int} {
    final stmt = formatCursorDelete(cursor, context);
    return prepare(stmt.sql).run(stmt.params);
  }

  public function count<Row>(cursor: Cursor<Row>): Int {
    final stmt = formatCursorSelect(cursor, context);
    return prepare('select count(*) from (${stmt.sql})')
      .get(stmt.params);
  }
  
  public function insertAll<Row:Document, In:{?id: String} & Row>(
    collection: Collection<Row>, 
    objects: Array<In>
  ): Array<Row> {
    return db.transaction(() -> {
      final table = escapeId(switch collection.cursor.from {
        case Table(name, _) | Column(Table(name, _), _): name;
        default: throw 'assert';
      });
      for (document in objects) {
        // TODO don't mutate
        if (!Reflect.hasField(document, 'id'))
          Reflect.setField(document, 'id', Uuid.nanoId());
        prepare('insert into ${table} values (?)').run(
          [Json.stringify(document)]
        );
      }
      return cast objects;
    });
  }

  public function insert<Row:Document, In:{?id: String} & Row>(
    collection: Collection<Row>, 
    object: In
  ): Row {
    return insertAll(collection, [object])[0];
  }

  public function update<Row>(cursor: Cursor<Row>, update: Update<Row>): {changes: Int} {
    return db.transaction(() -> {
      final stmt = formatCursorUpdate(cursor, update, context);
      return prepare(stmt.sql)
        .run(stmt.params);
    });
  }

  public function transaction<T>(run: () -> T): T {
    return db.transaction(run);
  }

  function prepare(query: String): SqliteStatement {
    // trace(query);
    return createOnError(() -> db.prepare(query));
  }

  function createOnError<T>(run: () -> T): T {
    function next(?retry: String): T {
      try return run()
      catch (e) {
        final NO_TABLE = 'no such table: ';
        final index = e.message.indexOf(NO_TABLE);
        if (index > -1) {
          final table = e.message.substr(index + NO_TABLE.length).split('.').pop();
          if (retry != table && table != null) {
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

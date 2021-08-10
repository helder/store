package helder;

import helder.store.*;

@:genes.type("Omit<Row, 'id'>")
typedef IdLess<Row> = Row;

typedef QueryOptions = {
  ?debug: Bool
}

@:expose
interface Store {
  function all<Row>(cursor: Cursor<Row>, ?options: QueryOptions): Array<Row>;
  function first<Row>(cursor: Cursor<Row>, ?options: QueryOptions): Null<Row>;
  function delete<Row>(cursor: Cursor<Row>): {changes: Int};
  function count<Row>(cursor: Cursor<Row>): Int;
  function insert<Row:Document, In:{?id: String} & Row>(
    collection: Collection<Row>, 
    object: IdLess<In>
  ): Row;
  function insertAll<Row:Document, In:{?id: String} & Row>(
    collection: Collection<Row>,
    objects: Array<IdLess<In>>
  ): Array<Row>;
  function update<Row>(cursor:Cursor<Row>, partial:Update<Row>): {changes: Int};
  function createIndex<Row:Document>(
    collection: Collection<Row>,
    name: String,
    on: Array<Expression<Dynamic>>
  ): Void;
  function transaction<T>(run: () -> T): T;
}
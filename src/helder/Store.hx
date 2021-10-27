package helder;

import helder.store.*;

@:genes.type("Omit<Row, 'id'> & {id?: string}")
typedef IdLess<Row> = Row;

typedef QueryOptions = {
  ?debug: Bool
}

@:expose
interface Store {
  function all<Row>(cursor: Cursor<Row>, ?options: QueryOptions): Array<Row>;
  function first<Row>(cursor: Cursor<Row>, ?options: QueryOptions): Null<Row>;
  function delete<Row>(
    cursor: Cursor<Row>, 
    ?options: QueryOptions
  ): {changes: Int};
  function count<Row>(cursor: Cursor<Row>, ?options: QueryOptions): Int;
  function insert<Row:Document, In:{?id: String} & Row>(
    collection: Collection<Row>, 
    object: IdLess<In>, 
    ?options: QueryOptions
  ): Row;
  function insertAll<Row:Document, In:{?id: String} & Row>(
    collection: Collection<Row>,
    objects: Array<IdLess<In>>, 
    ?options: QueryOptions
  ): Array<Row>;
  function update<Row>(
    cursor:Cursor<Row>,
    partial:Update<Row>,
    ?options: QueryOptions
  ): {changes: Int};
  function createIndex<Row:Document>(
    collection: Collection<Row>,
    name: String,
    on: Array<Expression<Dynamic>>
  ): Void;
  function transaction<T>(run: () -> T): T;
}
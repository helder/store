package helder.store;

import helder.store.From;

@:structInit 
@:allow(helder.store.Cursor)
class CursorImpl<Row> {
  public var from(default, null): From;
  public var where(default, null): Expression<Bool> = null;
  public var select(default, null): Selection<Row> = null;
  public var limit(default, null): Null<Int> = null;
  public var offset(default, null): Null<Int> = null;
  public var orderBy(default, null): Array<OrderBy> = null;
}

class Cursor<Row> {
  public final cursor: CursorImpl<Row>;

  public function new(cursor: CursorImpl<Row>)
    this.cursor = cursor;

  public function leftJoin<T>(that: Collection<Dynamic>, on: Expression<Bool>): Cursor<Row> {
    return with(cursor, c -> 
      c.from = From.Join(
        this.cursor.from,
        that.cursor.from,
        JoinType.Left,
        on.expr
      )
    );
  }

  public function innerJoin(that: Collection<Dynamic>, on: Expression<Bool>): Cursor<Row> {
    return with(cursor, c ->
      c.from = From.Join(
        this.cursor.from,
        that.cursor.from,
        JoinType.Inner,
        on.expr
      )
    );
  }

  public function take(limit: Int): Cursor<Row> {
    return with(cursor, c -> c.limit = limit);
  }

  public function skip(offset: Int): Cursor<Row> {
    return with(cursor, c -> c.offset = offset);
  }

  public function first(): CursorSingleRow<Row> {
    return new CursorSingleRow(take(1).cursor);
  }

  public function where(where: Expression<Bool>): Cursor<Row> {
    return with(cursor, c -> 
      c.where = 
        if (c.where != null) c.where.and(where) 
        else where
    );
  }
  
  public function select<T>(select: Selection<T>): Cursor<T> {
    return cast with(cursor, c -> c.select = cast select);
  }

  public function orderBy(orderBy: Array<OrderBy>) {
    return with(cursor, c -> 
      c.orderBy = 
        (if (this.cursor.orderBy == null) [] else this.cursor.orderBy).concat(orderBy)
    );
  }
}

class CursorSingleRow<Row> extends Cursor<Row> {}

private inline function with<Row>(cursor: CursorImpl<Row>, mutate: (cursor: CursorImpl<Row>) -> Void) {
  final res: CursorImpl<Row> = {
    from: cursor.from,
    where: cursor.where,
    select: cursor.select,
    limit: cursor.limit,
    offset: cursor.offset,
    orderBy: cursor.orderBy
  }
  mutate(res);
  return new Cursor<Row>(res);
}
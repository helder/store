package helder.store;

import helder.store.Expression.toExpr;
import helder.store.From;
import helder.store.Collection;
import helder.store.Selection;
import helder.store.util.TSTypes;

typedef ParameterizedCursor<Row> = {
  cursor: Cursor<Row>,
  params: Dynamic
}

@:structInit 
@:allow(helder.store.Cursor)
class CursorImpl<Row> {
  public var from(default, null): From;
  public var where(default, null): Null<Expression<Bool>> = null;
  public var select(default, null): Null<Selection<Row>> = null;
  public var limit(default, null): Null<Int> = null;
  public var offset(default, null): Null<Int> = null;
  public var orderBy(default, null): Null<Array<OrderBy>> = null;
  public var parameterized(default, null): Null<ParameterizedCursor<Row>> = null;

  public var collections(default, null): Map<String, CollectionImpl<Dynamic>>;

  public function toJSON(): Dynamic {
    return switch parameterized {
      case null: {
        from: from,
        where: where != null ? where.toJSON() : null,
        select: select != null ? select.toJSON() : null,
        limit: limit,
        offset: offset,
        orderBy: orderBy
      }
      case {cursor: cursor, params: params}: {
        cursor: cursor.toJSON(),
        params: params
      }
    }
  }
}

@:expose
class Cursor<Row> {
  public final cursor: CursorImpl<Row>;

  public function new(cursor: CursorImpl<Row>)
    this.cursor = cursor;

  public function leftJoin<T>(that: Collection<Dynamic>, on: Expression<Bool>): Cursor<Row> {
    return with(cursor, c -> {
      final condition = if (that.cursor.where == null) on else on && that.cursor.where;
      c.collections.set(Collection.getName(that), that);
      c.from = From.Join(
        this.cursor.from,
        that.cursor.from,
        JoinType.Left,
        condition.expr
      );
    });
  }

  public function innerJoin(that: Collection<Dynamic>, on: Expression<Bool>): Cursor<Row> {
    return with(cursor, c -> {
      final condition = if (that.cursor.where == null) on else on && that.cursor.where;
      c.collections.set(Collection.getName(that), that);
      c.from = From.Join(
        this.cursor.from,
        that.cursor.from,
        JoinType.Inner,
        condition.expr
      );
    });
  }

  public function take(limit: Null<Int>): Cursor<Row> {
    return with(cursor, c -> c.limit = limit);
  }

  public function skip(offset: Null<Int>): Cursor<Row> {
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
  
  #if (genes && js) 
  @:native('select') 
  public final __select: CursorSelect = js.Syntax.code('this.__select');
  @:native('__select')
  #end
  @:genes.internal 
  public function select<T>(select: Selection<T>): Cursor<T> {
    return cast with(cursor, c -> c.select = cast new SelectionImpl(SelectionImpl.create(select)));
  }

  public function orderBy(...orderBy: OrderBy) {
    return with(cursor, c -> 
      c.orderBy = 
        (if (this.cursor.orderBy == null) [] else this.cursor.orderBy).concat(orderBy)
    );
  }

  public static function fromJSON(data: Dynamic): Cursor<Dynamic> {
    if (data.cursor != null) {
      return fromJSON(data).parameterize(data.params);
    }
    return new Cursor({
      from: data.from,
      select: data.select != null ? new Selection(data.select) : null,
      where: data.where != null ? new Expression(toExpr(data.where)) : null,
      limit: data.limit,
      offset: data.offset,
      orderBy: data.orderBy,
      collections: new Map()
    });
  }

  public function toJSON() {
    return this.cursor.toJSON();
  }

  private function parameterize(params: Dynamic) {
    return with(cursor, c -> c.parameterized = {
      cursor: this,
      params: params
    });
  }
}

class CursorSingleRow<Row> extends Cursor<Row> {}

private function with<Row>(cursor: CursorImpl<Row>, mutate: (cursor: CursorImpl<Row>) -> Void) {
  final res: CursorImpl<Row> = {
    from: cursor.from,
    where: cursor.where,
    select: cursor.select,
    limit: cursor.limit,
    offset: cursor.offset,
    orderBy: cursor.orderBy,
    collections: new Map(),
    parameterized: cursor.parameterized
  }
  for (key => value in  cursor.collections)
    res.collections.set(key, value);
  mutate(res);
  return new Cursor<Row>(res);
}
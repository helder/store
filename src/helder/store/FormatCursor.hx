package helder.store;

import helder.store.Expression.toExpr;
import helder.store.From.JoinType;
import helder.store.FormatExpr.FormatExprContext;
import helder.store.FormatExpr.formatExpr;
import helder.store.Expression.ExpressionImpl;
import helder.store.Cursor;
using helder.store.Statement;
using helder.store.util.Arrays;
import tink.Anon.*;

typedef FormatCursorContext = {
  ?includeSelection: Bool,
  ?formatInline: Bool,
  formatSubject: (selection: Statement) -> Statement,
  formatAccess: (on: String, field: String) -> String,
  formatField: (path: Array<String>) -> String,
  formatUnwrapArray: (sql: String) -> String,
  escape: (value: Null<Any>) -> String,
  escapeId: (id: String) -> String
}

function formatSelection<T>(selection: Null<Selection<T>>, ctx: FormatExprContext): Statement {
  return switch selection {
    case null: '`data`';
    case Cursor(cursor) if (cursor is CursorSingleRow):
      formatCursor(cursor, ctx).wrap(sql -> 
        '(select $sql)'
      );
    case Cursor(cursor):
      final select = cursor.cursor.select;
      final isJson = select == null || !(select.match(Expression(_)));
      final res = if (isJson) 'json(res)' else 'res';
      formatCursor(cursor, merge(ctx, {
        formatSubject: (subject) -> subject.wrap(sql -> '$sql as res')
      })).wrap(sql -> 
        '(select json_group_array($res) from (select $sql))'
      );
    case Expression(e): formatExpr(e.expr, ctx);
    case FieldsOf(source, with):
      var target = 'json(${ctx.escapeId(source)}.`data`)';
      if (with == null) target;
      else formatSelection(with, ctx).wrap(sql -> 'json_patch($target, $sql)');
    case Fields(fields):
      var res = Statement.EMPTY;
      final chunks = [for (key in fields.keys()) key].chunk(50);
      for (keys in chunks) {
        var props = Statement.EMPTY;
        var i = 0;
        for (key in keys) {
          final select = fields[key];
          props += 
            formatSelection(select, ctx)
              .wrap(sql -> '${ctx.escape(key)}, $sql');
          if (i++ < keys.length - 1) props += ',';
        }
        final object = props.wrap(sql -> 'json_object(${sql})');
        if (res.isEmpty()) res = object;
        else res = new Statement('json_patch(') + res + ', ' + object + ')';
      }
      res;
  }
}

private function joinType(t: JoinType) {
  return switch t {
    case Left: 'left';
    case Inner: 'inner';
  }
}

function formatFrom(from: From, ctx: FormatExprContext): Statement {
  return switch from {
    case Table(name, null): ctx.escapeId(name);
    case Table(name, alias): '${ctx.escapeId(name)} as ${ctx.escapeId(alias)}';
    case Column(t, _): formatFrom(t, ctx);
    case Join(a, b, type, condition):
      final left = formatFrom(a, ctx);
      final right = formatFrom(b, ctx);
      final on = formatExpr(condition, ctx);
      left + joinType(type) + 'join' + right + 'on' + on;
  }
}

function formatOrderBy(orderBy: Null<Array<OrderBy>>, ctx: FormatExprContext): Statement {
  if (orderBy == null || orderBy.length == 0) return '';
  var orders = [];
  var params = [];
  for (o in orderBy) {
    final stmt = formatExpr(o.expr, ctx);
    orders.push('${stmt.sql} ${switch o.order {
      case Asc: 'asc';
      case Desc: 'desc';
    }}');
    params = params.concat(stmt.params);
  }
  return new Statement('order by ${orders.join(', ')}', params);
}

function formatWhere(where: Null<Expression<Bool>>, ctx: FormatExprContext): Statement {
  return
    if (where != null) formatExpr(where.expr, ctx)
    else '1';
}

function formatUpdate<Row>(update: Update<Row>, ctx: FormatExprContext): Statement {
  var source: Statement = '`data`';
  @:nullSafety(Off) for (field => expr in update) {
    final e = formatExpr(toExpr(expr), ctx);
    source = 
      ('json_set(': Statement) +
        source +
        ', ' + ctx.escape('$.'+field) +
        ', ' + e +
      ')';
  }
  return ('set `data`=': Statement) + source;
}

private function formatCursor<Row>(
  cursor: Cursor<Row>, 
  ctx: FormatCursorContext
): Statement {
  final c = @:privateAccess cursor.cursor;
  final exprCtx: FormatExprContext = merge(ctx, {
    formatCursor: cursor -> formatCursor(cursor, ctx)
  });
  final limit = if (c.limit != null || c.offset != null)
    'limit ${if (c.limit == null) '0' else ctx.escape(c.limit)}' else '';
  final offset = if (c.offset != null)
    'offset ${ctx.escape(c.offset)}' else '';
  final selection: Statement = ctx.includeSelection == true
    ? ctx.formatSubject(formatSelection(c.select, exprCtx))
    : '';
  final from = formatFrom(c.from, exprCtx);
  final where = formatWhere(c.where, exprCtx);
  final order = formatOrderBy(c.orderBy, exprCtx);
  final sql = selection + 'from' + from + 'where' + where + order + limit + offset;
  return sql;
}

function formatCursorUpdate<Row>(cursor: Cursor<Row>, update: Update<Row>, ctx: FormatCursorContext) {
  final c = @:privateAccess cursor.cursor;
  final exprCtx: FormatExprContext = merge(ctx, {
    formatCursor: cursor -> formatCursor(cursor, ctx)
  });
  final from = formatFrom(c.from, exprCtx);
  final set = formatUpdate(update, exprCtx);
  final where = formatWhere(c.where, exprCtx);
  return new Statement('update') + from + set + 'where' + where;
}

function formatCursorSelect<Row>(cursor: Cursor<Row>, ctx: FormatCursorContext) {
  return new Statement('select') + formatCursor(cursor, merge(ctx, {includeSelection: true}));
}

function formatCursorDelete<Row>(cursor: Cursor<Row>, ctx: FormatCursorContext) {
  return new Statement('delete') + formatCursor(cursor, merge(ctx, {includeSelection: false}));
}
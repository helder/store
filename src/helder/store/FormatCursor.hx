package helder.store;

import helder.store.From.JoinType;
import helder.store.FormatExpr.FormatExprContext;
import helder.store.FormatExpr.formatExpr;
import tink.Anon.*;

typedef FormatCursorContext = {
  ?includeSelection: Bool,
  ?formatInline: Bool,
  formatSubject: (selection: String) -> String,
  formatAccess: (on: String, field: String) -> String,
  formatField: (path: Array<String>) -> String,
  escape: (value: Any) -> String,
  escapeId: (id: String) -> String
}

function formatSelection<T>(selection: Selection<T>, ctx: FormatCursorContext): String {
  return switch selection {
    case null: '*';
    default: '*';
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

function formatOrderBy(orderBy: Array<OrderBy>, ctx: FormatExprContext): Statement {
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
  final selection: Statement = ctx.includeSelection
    ? ctx.formatSubject(formatSelection(c.select, ctx))
    : '';
  final from = formatFrom(c.from, exprCtx);
  final where: Statement = 
    if (c.where != null) formatExpr(c.where.expr, exprCtx)
    else '1';
  final order = formatOrderBy(c.orderBy, exprCtx);
  final sql = selection + 'from' + from + 'where' + where + order + limit + offset;
  return sql;
}

function formatCursorSelect<Row>(cursor: Cursor<Row>, ctx: FormatCursorContext) {
  return ('select': Statement) + formatCursor(cursor, merge(ctx, {includeSelection: true}));
}

function formatCursorDelete<Row>(cursor: Cursor<Row>, ctx: FormatCursorContext) {
  return ('delete': Statement) + formatCursor(cursor, merge(ctx, {includeSelection: false}));
}
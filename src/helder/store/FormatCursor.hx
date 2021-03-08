package helder.store;

import helder.store.FormatExpr.FormatExprContext;
import helder.store.FormatExpr.formatExpr;
import tink.Anon.*;

typedef FormatCursorContext = {
  ?formatInline: Bool,
  formatSubject: (selection: String) -> String,
  formatAccess: (on: String, field: String) -> String,
  formatField: (path: Array<String>) -> String,
  escape: (value: Any) -> String,
  escapeId: (id: String) -> String
}

function formatSelection<T>(selection: Selection<T>, ctx: FormatCursorContext): String {
  return '1';
}

function formatFrom(from: From, ctx: FormatCursorContext): String {
  return switch from {
    case Table(name, alias): ctx.escapeId(from.source());
    case Column(_, column): '${ctx.escapeId(from.source())}.${ctx.escapeId(column)}';
    case Join(a, _, _, _): formatFrom(a, ctx);
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

function formatCursor<Row>(cursor: Cursor<Row>, ctx: FormatCursorContext): Statement {
  final c = @:privateAccess cursor.cursor;
  final exprCtx: FormatExprContext = merge(ctx, {
    formatCursor: cursor -> formatCursor(cursor, ctx)
  });
	final limit = if (c.limit != null || c.offset != null)
    'limit ${if (c.limit == null) '0' else ctx.escape(c.limit)}' else '';
  final offset = if (c.offset != null)
    'offset ${ctx.escape(c.offset)}' else '';
  final selection = ctx.formatSubject(formatSelection(c.select, ctx));
  final from = formatFrom(c.from, ctx);
  final where: Statement = 
    if (c.where != null) formatExpr(c.where.expr, exprCtx)
    else '1';
  final order = formatOrderBy(c.orderBy, exprCtx);
  final sql = selection + 'from' + from + 'where' + where + order + limit + offset;
  return sql;
}

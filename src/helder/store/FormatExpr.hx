package helder.store;

import helder.store.FormatCursor.FormatCursorContext;
import helder.store.Expression.BinOp;
import helder.store.Expression.Expr;

final binOps: Map<BinOp, String> = [
  Add => '+',
  Subt => '-',
  Mult => '*',
  Mod => '%',
  Div => '/',
  Greater => '>',
  GreaterOrEqual => '>=',
  Less => '<',
  LessOrEqual => '<=',
  Equals => '=',
  NotEquals => '!=',
  And => 'and',
  Or => 'or',
  Like => 'like',
  Glob => 'glob',
  Match => 'match',
  In => 'in',
  NotIn => 'not in',
  Concat => '||'
];

typedef FormatExprContext = FormatCursorContext & {
  formatCursor: (cursor: Cursor<Any>) -> Statement
}

function formatExpr(expr: Expr, ctx: FormatExprContext): Statement {
  switch expr {
    case UnOp(Not, e):
      return formatExpr(e, ctx).wrap(sql -> '!($sql)');
    case UnOp(IsNull, e):
      return formatExpr(e, ctx).wrap(sql -> '$sql is null');
    case BinOp(op, a, b):
      return formatExpr(a, ctx).wrap(aSql -> 
          formatExpr(b, ctx).wrap(bSql -> 
            switch op {
              case In | NotIn if (b.match(Expr.Field(_))):
                '($aSql ${binOps[op]} ${ctx.formatUnwrapArray(bSql)})';
              default: '($aSql ${binOps[op]} $bSql)';
            }
          )
        );
    case Value(value):
      if (value == null)
        return 'null';
      if (value is Bool)
        return if (value) '1' else '0';
      if (value is Array)
        return '(${(cast value: Array<Any>).map(ctx.escape).join(', ')})';
      return 
        if (ctx.formatInline == true) ctx.escape(value)
        else new Statement('?', [value]);
    case Field(path):
      return ctx.formatField(path);
    case Call('cast', [e, Value(type)]):
      final stmt = formatExpr(e, ctx);
      return new Statement(
        'cast(${stmt.sql} as ${ctx.escape(type)})',
        stmt.params
      );
    case Call(method, params):
      final params = params.map(e -> formatExpr(e, ctx));
      final expressions = params.map(stmt -> stmt.sql).join(', ');
      return new Statement(
        '${ctx.escapeId(method)}($expressions)',
        Lambda.flatMap(params, stmt -> stmt.params)
      );
    case Access(e, field):
      return formatExpr(e, ctx).wrap(sql -> ctx.formatAccess(sql, field));
    case Query(cursor):
      return ctx.formatCursor(cursor).wrap(sql -> '($sql)');
  }
}
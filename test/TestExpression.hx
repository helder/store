package test;

import helder.store.FormatExpr.FormatExprContext;
import helder.store.FormatExpr.formatExpr;
import helder.store.FormatCursor.formatCursor;
import helder.store.Expression;
import helder.store.Expression.*;

final ctx: FormatExprContext = {
  formatInline: true,
  formatSubject: selection -> selection,
  formatAccess: (on, field) -> '${on}.${field}',
  formatField: (path) -> '$.' + path.join('.'),
  escape: (value) -> '${value}',
  escapeId: (id) -> id,
  formatCursor: cursor -> formatCursor(cursor, ctx)
}

final f = (expr: Expression<Dynamic>) -> formatExpr(expr.expr, ctx).sql;

@:asserts
class TestExpression {
  public function new() {}

  public function testBasic() {
    asserts.assert(f(value(1).is(1)) == '(1 = 1)');
    asserts.assert(f(field('a').is(1)) == '($.a = 1)');
    asserts.assert(
      f(field('a').is(1).and(field('b').is(2))) == '(($.a = 1) and ($.b = 2))'
    );
    return asserts.done();
  }

  public function testPath() {
    return assert(f(field('a.b').is(1)) == '($.a.b = 1)');
  }
}
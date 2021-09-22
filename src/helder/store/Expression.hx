package helder.store;

import helder.store.OrderBy.OrderDirection;
import haxe.extern.EitherType in Either;

enum UnOp {
  Not;
  IsNull;
}

enum BinOp {
  Add;
  Subt;
  Mult;
  Mod;
  Div;
  Greater;
  GreaterOrEqual;
  Less;
  LessOrEqual;
  Equals;
  NotEquals;
  And;
  Or;
  Like;
  Glob;
  Match;
  In;
  NotIn;
  Concat;
}

enum Expr {
  UnOp(op: UnOp, expr: Expr);
  BinOp(op: BinOp, a: Expr, b: Expr);
  Field(path: Array<String>);
  Value(value: Null<Any>);
  Call(method: String, params: Array<Expr>);
  Access(expr: Expr, field: String);
  Query(cursor: Cursor<Any>);
}

typedef EV<T> = Either<Expression<T>, T>;

function toExpr<T>(ev: Null<Either<EV<T>, Cursor<T>>>): Expr {
  return 
    if (ev == null) return Value(null);
    else if (ev is ExpressionImpl) (cast ev).expr
    else if (ev is Expr) (cast ev: Expr) 
    else if (ev is Cursor) Query(ev)
    else Value((cast ev: T));
}

private function isConstant(e: Expr, value: Any) {
  return switch e {
    case Value(v): v == value;
    default: false;
  }
}

@:forward
abstract Expression<T>(ExpressionImpl<T>) {
  public function new(expr: Expr) {
    final inst = new ExpressionImpl<T>(expr);
    this = 
      #if js new helder.store.util.RuntimeProxy(inst, inst.get)
      #else inst #end;
  }

  @:op(a.b)
  macro public function getProp(expr: haxe.macro.Expr, property: String) {
    #if macro
    return helder.store.macro.Expression.getProp(expr, property);
    #end
  }
  
  inline public static function value<T>(value: T) {
    return ExpressionImpl.value(value);
  }

  inline public static function field(...path: String) {
    return ExpressionImpl.field(path.toArray());
  }

  @:op(a in b) inline static function isIn<T>(a:Expression<T>, b:Expression<Array<T>>):Expression<Bool>
    return a.isIn(b);

  @:op(a in b) inline static function inCursor<T>(a:Expression<T>, b:Cursor<T>):Expression<Bool>
    return a.isIn(b);

  @:op(a + b) inline static function add<T:Float>(a:Expression<T>, b:Expression<T>):Expression<T>
    return a.add(b);

  @:op(a - b) inline static function substract<T:Float>(a:Expression<T>, b:Expression<T>):Expression<T>
    return a.substract(b);

  @:op(a * b) inline static function multiply<T:Float>(a:Expression<T>, b:Expression<T>):Expression<T>
    return a.multiply(b);

  @:op(a / b) inline static function divide<T:Float>(a:Expression<T>, b:Expression<T>):Expression<Float>
    return a.divide(b);

  @:op(a in b) inline static function isInC<T>(a:Expression<T>, b:Array<T>):Expression<Bool>
    return a.isIn(b);

  @:op(a == b) inline static function eq<T>(a:Expression<T>, b:Expression<T>):Expression<Bool>
    return a.is(b);

  @:op(a != b) inline static function neq<T>(a:Expression<T>, b:Expression<T>):Expression<Bool>
    return a.is(b).not();

  @:op(a > b) inline static function gt<T:Float>(a:Expression<T>, b:Expression<T>):Expression<Bool>
    return a.greater(b);

  @:op(a < b) inline static function lt<T:Float>(a:Expression<T>, b:Expression<T>):Expression<Bool>
    return a.less(b);

  @:op(a >= b) inline static function gte<T:Float>(a:Expression<T>, b:Expression<T>):Expression<Bool>
    return a.greaterOrEqual(b);

  @:op(a <= b) inline static function lte<T:Float>(a:Expression<T>, b:Expression<T>):Expression<Bool>
    return a.lessOrEqual(b);

  @:op(!a) inline static function not(c:Expression<Bool>):Expression<Bool>
    return c.not();

  @:op(a && b) inline static function and(a:Expression<Bool>, b:Expression<Bool>):Expression<Bool>
    return a.and(b);

  @:op(a || b) inline static function or(a:Expression<Bool>, b:Expression<Bool>):Expression<Bool>
    return a.or(b);

  @:op(a || b) inline static function constOr(a:Bool, b:Expression<Bool>):Expression<Bool>
    return b.or(a);

  @:op(a || b) inline static function orConst(a:Expression<Bool>, b:Bool):Expression<Bool>
    return a.or(b);

  @:commutative
  @:op(a == b) inline static function eqC<T>(a:Expression<T>, b:T):Expression<Bool>
    return a.is(b);

  @:commutative
  @:op(a != b) inline static function neqC<T>(a:Expression<T>, b:T):Expression<Bool>
    return a.is(b).not();

  @:op(a > b) inline static function gtConst<T:Float>(a:Expression<T>, b:T):Expression<Bool>
    return a.greater(b);

  @:op(a < b) inline static function ltConst<T:Float>(a:Expression<T>, b:T):Expression<Bool>
    return a.less(b);

  @:op(a >= b) inline static function gteConst<T:Float>(a:Expression<T>, b:T):Expression<Bool>
    return a.greaterOrEqual(b);

  @:op(a <= b) inline static function lteConst<T:Float>(a:Expression<T>, b:T):Expression<Bool>
    return a.lessOrEqual(b);
}

@:expose
@:native('Expression')
class ExpressionImpl<T> {
  public final expr: Expr;

  public function new(expr: Expr)
    this.expr = expr;

  public function asc()
    return {expr: expr, order: OrderDirection.Asc}

  public function desc()
    return {expr: expr, order: OrderDirection.Desc}

  public function not(): Expression<Bool>
    return new Expression(UnOp(Not, expr));
  
  public function or(
    that: EV<Bool>
  ): Expression<Bool> {
    final a = expr;
    final b = toExpr(that);
    if (isConstant(b, true)) return new Expression(cast b);
    if (isConstant(a, true)) return cast this;
    if (isConstant(a, false)) return new Expression(cast b);
    if (isConstant(b, false)) return cast this;
    return new Expression(BinOp(Or, expr, b));
  }

  public function and(that: EV<Bool>): Expression<Bool> {
    final a = expr;
    final b = toExpr(that);
    if (isConstant(b, true)) return cast this;
    if (isConstant(a, true)) return new Expression(cast b);
    if (isConstant(a, false)) return cast this;
    if (isConstant(b, false)) return new Expression(cast b);
    return new Expression(BinOp(And, a, b));
  }
  static final NULL = Expr.Value(null);
  public function is(that: EV<T>): Expression<Bool> {
    if (that == null || NULL.equals((that: Expression<T>).expr)) return isNull();
    return new Expression(BinOp(Equals, expr, toExpr(that)));
  }
  public function isNot(that: EV<T>): Expression<Bool> {
    if (that == null || NULL.equals((that: Expression<T>).expr)) return isNotNull();
    return new Expression(BinOp(NotEquals, expr, toExpr(that)));
  }
  public function isIn(that: Either<EV<Array<T>>, Cursor<Any>>): Expression<Bool> {
    return new Expression(BinOp(In, expr, toExpr(that)));
  }
  public function isNotIn(that: Either<EV<Array<T>>, Cursor<Any>>): Expression<Bool> {
    return new Expression(BinOp(NotIn, expr, toExpr(that)));
  }
  public function isNull(): Expression<Bool> {
    return new Expression(UnOp(IsNull, expr));
  }
  public function isNotNull(): Expression<Bool> {
    return new Expression(UnOp(Not, UnOp(IsNull, expr)));
  }
  public function add<T:Float>(that: EV<T>): Expression<T> {
    return new Expression(BinOp(Add, expr, toExpr(that)));
  }
  public function substract<T:Float>(that: EV<T>): Expression<T> {
    return new Expression(BinOp(Subt, expr, toExpr(that)));
  }
  public function multiply<T:Float>(that: EV<T>): Expression<T> {
    return new Expression(BinOp(Mult, expr, toExpr(that)));
  }
  public function remainder(that: EV<Float>): Expression<Float> {
    return new Expression(BinOp(Mod, expr, toExpr(that)));
  }
  public function divide<T:Float>(that: EV<T>): Expression<Float> {
    return new Expression(BinOp(Div, expr, toExpr(that)));
  }
  public function greater(
    that: EV<Dynamic>
  ): Expression<Bool> {
    return new Expression(BinOp(Greater, expr, toExpr(that)));
  }
  public function greaterOrEqual(
    that: EV<Dynamic>
  ): Expression<Bool> {
    return new Expression(
      BinOp(GreaterOrEqual, expr, toExpr(that))
    );
  }
  public function less(
    that: EV<Dynamic>
  ): Expression<Bool> {
    return new Expression(BinOp(Less, expr, toExpr(that)));
  }
  public function lessOrEqual(
    that: EV<Dynamic>
  ): Expression<Bool> {
    return new Expression(BinOp(LessOrEqual, expr, toExpr(that)));
  }
  public function concat(
    that: EV<String>
  ): Expression<String> {
    return new Expression(BinOp(Concat, expr, toExpr(that)));
  }
  public function like(that: EV<String>): Expression<Bool> {
    return new Expression(BinOp(Like, expr, toExpr(that)));
  }
  public function glob(that: EV<String>): Expression<Bool> {
    return new Expression(BinOp(Glob, expr, toExpr(that)));
  }
  public function match(that: EV<String>): Expression<Bool> {
    return new Expression(BinOp(Match, expr, toExpr(that)));
  }
  public function get<T>(path: String): Expression<T> {
    switch expr {
      case Field(prev): 
        return new Expression(Field(prev.concat([path])));
      default:
        return new Expression(Access(expr, path));
    }
  }

  #if php
  @:keep @:phpMagic function __get(name:String) {
    return php.Global.property_exists(this, name)
      ? php.Syntax.field(this, name)
      : get(name);
  }
  #end

  public static function value<T>(value: T): Expression<T> {
    return new Expression<T>(Value(value));
  }
  public static function field(path: Array<String>) {
    return new Expression(Field(path));
  }
}
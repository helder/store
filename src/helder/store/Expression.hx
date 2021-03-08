package helder.store;

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
}

enum Expr {
	UnOp(op: UnOp, expr: Expr);
	BinOp(op: BinOp, a: Expr, b: Expr);
	Field(path: Array<String>);
	Value(value: Any);
	Call(method: String, params: Array<Expr>);
	Access(expr: Expr, field: String);
	Query(cursor: Cursor<Any>);
}

typedef EV<T> = Either<Expression<T>, T>;

private function toExpr<T>(ev: EV<T>): Expr {
	return if ((ev is Expr)) (cast ev: Expr) else Value((cast ev: T));
}

private function isConstant(e: Expr, value: Any) {
	return switch e {
		case Value(v): v == value;
		default: false;
	}
}

class Expression<T> {
  public final expr: Expr;

  public function new(expr: Expr)
    this.expr = expr;

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
		return new Expression(BinOp(And, expr, b));
	}

	public function is(that: EV<T>): Expression<Bool> {
		return new Expression(BinOp(Equals, expr, toExpr(that)));
	}

	public function isNot(that: EV<T>): Expression<Bool> {
		return new Expression(BinOp(NotEquals, expr, toExpr(that)));
	}
	public function isIn(that: Either<EV<Array<T>>, Cursor<Any>>): Expression<Bool> {
		return new Expression(BinOp(In, expr, toExpr(that)));
	}
	public function isNotIn(that: Either<EV<Array<T>>, Cursor<Any>>): Expression<Bool> {
		return new Expression(BinOp(NotIn, expr, toExpr(that)));
	}
	public function add(that: EV<Float>): Expression<Float> {
		return new Expression(BinOp(Add, expr, toExpr(that)));
	}
	public function substract(that: EV<Float>): Expression<Float> {
		return new Expression(BinOp(Subt, expr, toExpr(that)));
	}
	public function multiply(that: EV<Float>): Expression<Float> {
		return new Expression(BinOp(Mult, expr, toExpr(that)));
	}
	public function remainder(that: EV<Float>): Expression<Float> {
		return new Expression(BinOp(Mod, expr, toExpr(that)));
	}
	public function divide(that: EV<Float>): Expression<Float> {
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
}
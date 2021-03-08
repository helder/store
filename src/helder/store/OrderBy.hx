package helder.store;

import helder.store.Expression.Expr;

enum abstract OrderDirection(String) {
	final Asc = 'asc';
	final Desc = 'desc';
}

typedef OrderBy = {
	expr: Expr,
	order: OrderDirection
}
package helder.store;

import helder.store.From;

class Collection<Row> extends Cursor<Row> {
	public var id(get, never): Expression<String>;
	public var alias(get, never): String;

	public function new(name: String, ?options: {?alias: String}) {
		super({
			from: Table(
				name, 
				if (options == null) null else options.alias
			)
		});
	}

	public function get(name: String): Expression<Any> {
		final path = switch cursor.from {
			case Column(From.Table(name, alias), column): [if (alias != null) alias else name, column];
			case Table(name, alias): [if (alias != null) alias else name];
			default: throw 'Cannot field access';
		}
		return new Expression(Field(path.concat([name])));
		// todo:  return new Proxy(expr, exprProxy);
	}

	function get_id(): Expression<String> {
		return cast get('id');
	}

	public function as(name: String): Collection<Row> {
		return new Collection<Row>(
			switch cursor.from {
				case Table(name, _): name;
				default: throw 'assert';
			}, 
			{alias: name}
		);
	}

	public function fields(): Selection<Row> {
		return Selection.FieldsOf(alias);
	}

	function get_alias(): String {
		return switch cursor.from {
			case Column(Table(name, a), _) | Table(name, a): 
				if (a != null) a else name;
			default: throw 'unexpected';
		}
	}
}
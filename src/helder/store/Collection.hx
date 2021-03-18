package helder.store;

import helder.store.From;

@:forward
abstract Collection<T:{}>(CollectionImpl<T>) to CollectionImpl<T> {
  public function new(name: String, ?options: {?alias: String}) {
    final inst = new CollectionImpl<T>(name, options);
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
}

class CollectionImpl<Row:{}> extends Cursor<Row> {
  public var id(get, never): Expression<String>;
  public var alias(get, never): String;
  public var fields(get, never): Selection<Row>;

  public function new(name: String, ?options: {?alias: String}) {
    super({
      from: Column(
        Table(
          name, 
          if (options == null) null else options.alias
        ),
        'data'
      )
    });
  }

  public function get<T>(name: String): Expression<T> {
    final path: Array<String> = switch cursor.from {
      case Column(From.Table(name, alias), column): [if (alias != null) alias else name, column];
      case Table(name, alias): [if (alias != null) alias else name];
      default: throw 'Cannot field access';
    }
    return new Expression(Field(path.concat([name])));
    // todo: return new Proxy(expr, exprProxy);
  }

  #if php
  @:keep @:phpMagic function __get(name:String) {
    return php.Global.property_exists(this, name)
      ? php.Syntax.field(this, name)
      : get(name);
  }
  #end

  function get_id(): Expression<String> {
    return cast get('id');
  }

  public function as(name: String): Collection<Row> {
    return new Collection<Row>(
      switch cursor.from {
        case Table(name, _) | Column(Table(name, _), _): name;
        default: throw 'assert';
      }, 
      {alias: name}
    );
  }

  function get_fields(): Selection<Row> {
    return Selection.fieldsOf(this);
  }

  function get_alias(): String {
    return switch cursor.from {
      case Column(Table(name, a), _) | Table(name, a): 
        if (a != null) a else name;
      default: throw 'unexpected';
    }
  }
}
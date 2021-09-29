package helder.store;

import helder.store.From;

#if (js && genes)
@:genes.type('(U extends any ? (k: U) => void : never) extends (k: infer I) => void ? I : never')
typedef UnionToIntersection<U> = Dynamic;

@:genes.type('Row extends object
  ? {[K in keyof Row]-?: Expression<Row[K]> & FieldsOf<Row[K]>}
  : unknown
')
typedef FieldsOf<Row> = Dynamic;

@:genes.type('CollectionOf<Row> & UnionToIntersection<FieldsOf<Row>>')
typedef TSCollection<Row> = Dynamic;

@:expose
@:native('Collection')
@:genes.type('{new<Row extends {}>(name: string, options?: {}): TSCollection<Row>}')
final ESCollection = js.Syntax.code('
  class Collection extends CollectionOf {
    constructor(name, options) {
      super(name, options);
      return new Proxy(this, {
        get: (target, property) => {
          if (property in target) return target[property];
          return target.get(property);
        }
      });
    }
  }
');
#end

@:forward
abstract Collection<T:{}>(CollectionOf<T>) to CollectionOf<T> from CollectionOf<T> {
  inline public function new(name: String, ?options: CollectionOptions) {
    final inst = new CollectionOf<T>(name, options);
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

  public static function name(collection: CollectionOf<Dynamic>): String {
    return switch collection.cursor.from {
      case Column(Table(name, _), _) | Table(name, _): name;
      default: throw 'unexpected';
    }
  }
}

typedef CollectionOptions = {
  ?idColumn: String,
  ?alias: String
}

typedef GenericCollection = CollectionOf<Dynamic>;

class CollectionOf<Row:{}> extends Cursor<Row> {
  private final idColumn: String;
  public var id(get, never): Expression<String>;
  public var alias(get, never): String;
  public var fields(get, never): Selection<Row>;

  public function new(name: String, ?options: CollectionOptions) {
    final collections = new Map();
    super({
      from: Column(
        Table(
          name, 
          if (options == null) null else options.alias
        ),
        'data'
      ),
      collections: collections
    });
    idColumn = 
      if (options == null || options.idColumn == null) 'id' 
      else options.idColumn;
    collections.set(name, this);
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
    return cast get(idColumn);
  }

  #if (genes && js) 
  @:native('as') 
  @:genes.type('(name: string) => TSCollection<Row>')
  public final __as = js.Syntax.code('this.__as');
  @:native('__as')
  #end
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
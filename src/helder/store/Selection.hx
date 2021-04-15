package helder.store;

import haxe.DynamicAccess;
import helder.store.Collection.CollectionImpl;
import helder.store.Expression.ExpressionImpl;

@:using(helder.store.Selection)
@:expose
enum Select<T> {
  Expression<T>(e: Expression<T>): Select<T>;
  Cursor<T>(c: Cursor<T>): Select<T>;
  FieldsOf<T>(source: String, ?add: Selection<Dynamic>): Select<T>;
  Fields<T>(fields: DynamicAccess<Select<Dynamic>>): Select<T>;
}

@:forward
abstract Selection<T>(Select<T>) from Select<T> {
  public function new(selection: Select<T>) 
    this = selection;

  // Create the selection at runtime - we could do this at compile time too
  // but then the lib is only useable from haxe
  public static function create<T>(input: Dynamic): Select<T> {
    if (input is ExpressionImpl) return Select.Expression(input);
    if (input is Cursor) return Select.Cursor(input);
    if (input is Select) return input;
    final obj: DynamicAccess<Dynamic> = input;
    final res: DynamicAccess<Select<Dynamic>> = {}
    @:nullSafety(Off) for (key => value in obj)
      res[key] = create(value);
    return Select.Fields(res);
  }

  @:from
  public static macro function ofAny(expr: haxe.macro.Expr) {
    #if macro
    return helder.store.macro.Selection.create(expr);
    #end
  }

  @:noUsing
  public static function fieldsOf<T:{}>(collection: CollectionImpl<T>): Selection<T> {
    return new Selection(FieldsOf(collection.alias));
  }
  
  // Extern generic inline is useless, but forces the compiler to close
  // what is otherwise a constrained monomorph.
  @:extern @:generic inline
  public static function with<A: {}, B: {}, C: A & B>(a: Selection<A>, b:Selection<B>): Selection<C> {
    return switch a {
      case FieldsOf(name, null): FieldsOf(name, b);
      default: throw 'assert';
    };
  }
}
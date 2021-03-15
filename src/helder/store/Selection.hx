package helder.store;

import haxe.DynamicAccess;
import helder.store.Collection.CollectionImpl;

@:using(helder.store.Selection)
enum Select<T> {
  Expression<T>(e: Expression<T>): Select<T>;
  FieldsOf<T>(source: String, ?with: Selection<Dynamic>): Select<T>;
  // Should be Expression | Cursor
  Fields<T>(fields: DynamicAccess<Expression<Dynamic>>): Select<T>;
}

@:forward
abstract Selection<T>(Select<T>) from Select<T> {
  public function new(selection: Select<T>) 
    this = selection;

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
  public static function with<A: {}, B: {}, C: B & A>(a: Selection<A>, b:Selection<B>): Selection<C> {
    return switch a {
      case FieldsOf(name, null): FieldsOf(name, b);
      default: throw 'assert';
    };
  }
}
package helder.store;

import haxe.DynamicAccess;
import helder.store.Collection.CollectionImpl;

enum Select<T> {
  Expression<T>(e: Expression<T>): Select<T>;
  FieldsOf<T>(name: String): Select<T>;
  Fields<T>(fields: DynamicAccess<Expression<Dynamic>>): Select<T>;
}

abstract Selection<T>(Select<T>) {
  public function new(selection: Select<T>) 
    this = selection;

	@:from
	public static macro function ofAny(expr: haxe.macro.Expr) {
    #if macro
    return helder.store.macro.Selection.create(expr);
    #end
  }

  public static function fieldsOf<T>(collection: CollectionImpl<T>): Selection<T> {
    return new Selection(FieldsOf(collection.alias));
  }
}
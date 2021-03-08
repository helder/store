package helder.store;

import helder.store.Collection.CollectionImpl;

enum SelectionImpl<Fields> {
  FieldsOf<Row>(name: String): SelectionImpl<Row>;
}

abstract Selection<T>(SelectionImpl<T>) {
  public function new(selection: SelectionImpl<T>) 
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
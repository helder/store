package helder.store;

import haxe.DynamicAccess;

typedef UpdateImpl<T> = DynamicAccess<Expression<Dynamic>>;

@:forward
abstract Update<T>(UpdateImpl<T>) {
  public function new(update: UpdateImpl<T>) 
    this = update;

  @:from
  public static macro function ofAny(expr: haxe.macro.Expr) {
    #if macro
    return helder.store.macro.Update.create(expr);
    #end
  }
}
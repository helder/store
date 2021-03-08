package helder.store;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;

class SelectionFields {
  public static function build() {
    switch (Context.getLocalType()) {
      case t:
        trace(t);
    }
    return null;
  }
}
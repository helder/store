package helder.store.util;

class RuntimeProxyImpl<T> {
  var __subject: T;
  var __getter: (property: String) -> Dynamic;
  public function new(subject: T, get: (property: String) -> Dynamic) {
    this.__subject = subject;
    this.__getter = get;
  }
  @:keep @:phpMagic function __get(name:String) {
    return php.Global.property_exists(__subject, name)
      ? php.Syntax.field(__subject, name)
      : __getter(name);
  }
}

@:forward
abstract RuntimeProxy<T>(T) to T {
  public function new(subject: T, get: (property: String) -> Dynamic) {
    this = cast new RuntimeProxyImpl(subject, get);
  }
}

package helder.store.util;

@:forward
abstract RuntimeProxy<T>(T) to T {
  public function new(subject: T, get: (property: String) -> Dynamic)
    this = subject;
}

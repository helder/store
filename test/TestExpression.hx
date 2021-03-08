package test;

@:asserts @:publicFields
class TestExpression {
  function new() {}

  function testA() {
    return assert(1 == 1);
  }
}
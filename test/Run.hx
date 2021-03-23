package test;

import tink.unit.TestBatch;
import tink.testrunner.Runner;

function run() {
  Runner.run(TestBatch.make([
    new TestExpression(),
    new TestBasic(),
    new TestFunctions(),
    new TestJoins(),
    new TestSubQueries(),
    new TestUpdate(),
  ])).handle(Runner.exit);
}

function main() {
  #if sqljs
  helder.store.drivers.SqlJs.init().then(_ -> run());
  #else
  run();
  #end
}
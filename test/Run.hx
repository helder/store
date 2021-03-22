package test;

import tink.unit.TestBatch;
import tink.testrunner.Runner;

function main() {
  Runner.run(TestBatch.make([
    new TestExpression(),
    new TestBasic(),
    new TestFunctions(),
    new TestJoins(),
    new TestSubQueries(),
    new TestUpdate(),
  ])).handle(Runner.exit);
}
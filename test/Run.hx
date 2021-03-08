package test;

import tink.unit.TestBatch;
import tink.testrunner.Runner;

function main() {
  Runner.run(TestBatch.make([
    new TestExpression()
  ])).handle(Runner.exit);
}
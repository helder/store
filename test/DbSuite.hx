package test;

final dbSuite = suite({
  setup: done -> {
    #if sqljs
    helder.store.drivers.SqlJs.init().then(done);
    #else
    done();
    #end
  }
});
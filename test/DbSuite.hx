package test;

final dbSuite = suite({
  setup: done -> {
    #if sqljs
    helder.store.sqlite.drivers.SqlJs.init().then(done);
    #else
    done();
    #end
  }
});
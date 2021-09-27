package test;

typedef Node = {id: String, v: String}

final TestSub = dbSuite(test -> {

  final Node = new Collection<Node>('Node');

  test('Sub', () -> {
    final db = new Store();
    db.insert(Node, {v: 'test1'});
    db.insert(Node, {v: 'test2'});
    final resOne = db.first(
      Node.select(
        Node.where(Node.v == 'test2').subOne()
      ).first()
    );
    assert.equal(resOne.v, 'test2');
    final resMulti = db.first(
      Node.select(
        Node.where(Node.v == 'test2').select(Node.v).subAll()
      ).first(), {debug: true}
    );
    assert.equal(resMulti, ['test2']);
  });

});
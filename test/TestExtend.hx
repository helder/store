package test;

import test.DbSuite.dbSuite;
import test.db.Node.Node;
using test.db.Node;

final TestExtend = dbSuite(test -> {

  test('Extend', () -> {
    final db = new Store();
    final root: NodeData = {id: 'root', index: 0}
    final child1: NodeData = {id: 'child1', index: 0, parent: root.id}
    final child2: NodeData = {id: 'child2', index: 1, parent: root.id}
    db.insertAll(Node, [root, child1, child2]);
    final children = Node.where(Node.id == root.id).children();
    final res1 = db.all(children);
    assert.equal(res1.map(node -> node.id), [child1.id, child2.id]);
    final second = db.first(children.where(Node.index.is(1)));
    assert.is(second.id, child2.id);
  });

});
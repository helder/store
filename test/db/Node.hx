package test.db;

import helder.store.Cursor;
import helder.store.Collection;

typedef NodeData = {id: String, index: Int, ?parent: String}

final Node = new Collection<NodeData>('node');

class NodeEdges {
  public static function children(cursor: Cursor<NodeData>): Cursor<NodeData> {
    final ids = cursor.select(Node.id);
    return Node
      .where(Node.parent in ids);
  }
}

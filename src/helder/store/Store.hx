package helder.store;

interface Store {
	function all<Row>(cursor: Cursor<Row>): Array<Row>;
	function first<Row>(cursor: Cursor<Row>): Option<Row>;
	function delete<Row>(cursor: Cursor<Row>): {changes: Int};
	function count<Row>(cursor: Cursor<Row>): Int;
	function insert<Row>(
		collection: Collection<Row>,
		objects: Array<Row>
	): Array<Row>;
	function insertOne<Row>(
		collection: Collection<Row>,
		object: Without<Row, 'id'>
	): Row;
	function save<Row: Document>(
		collection: Collection<Row>,
		objects: Array<Row>
	): Array<Row>;
	function saveOne<Row: Document>(collection: Collection<Row>, object: Row): Row;
	function createIndex<Row>(
		collection: Collection<Row>,
		name: String,
		on: Array<Expression<Dynamic>>
	): Void;
	function transaction<T>(run: () -> T): T;
}
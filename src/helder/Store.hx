package helder;

import helder.store.*;

interface Store {
	function all<Row:{}, R: Row & Document>(cursor: Cursor<Row>): Array<R>;
	function first<Row:{}, R: Row & Document>(cursor: Cursor<Row>): Null<R>;
	function delete<Row:{}>(cursor: Cursor<Row>): {changes: Int};
	function count<Row:{}>(cursor: Cursor<Row>): Int;
	function insert<Row:{}, R: Row & Document>(
		collection: Collection<Row>, 
		objects: Array<Row>
	): Array<R>;
	function insertOne<Row:{}, R: Row & Document>(
		collection: Collection<Row>, 
		object: Row
	): R;
	function save<Row:{}>(collection: Collection<Row>, objects: Array<Row>): Array<Row>;
	function saveOne<Row:{}>(collection: Collection<Row>, object: Row): Row;
	/*function createIndex<Row>(
		collection: Collection<Row>,
		name: String,
		on: Array<Expression<Dynamic>>
	): Void;*/
	function transaction<T>(run: () -> T): T;
}
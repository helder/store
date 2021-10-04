import {Collection, Expression, SqliteStore} from 'helder.store'
import {BetterSqlite3} from 'helder.store/drivers/BetterSqlite3'
import {test} from 'uvu'
import * as assert from 'uvu/assert'

function store() {
  return new SqliteStore(new BetterSqlite3())
}

test('basic', () => {
  const db = store()
  const Node = new Collection<{id: string; index: number}>(`node`)
  const amount = 10
  const objects = Array.from({length: amount}).map((_, index) => ({index}))
  assert.equal(objects.length, amount)
  const stored = db.insertAll(Node, objects)
  assert.equal(db.count(Node), amount)
  const id = stored[amount - 1].id
  assert.equal(
    db.first(
      Node.where(
        Node.index.greaterOrEqual(amount - 1).and(Node.index.less(amount))
      )
    )!.id,
    id
  )
})

test('filters', () => {
  const db = store()
  const Test = new Collection<typeof a & {id: string}>('test')
  const a = {prop: 10}
  const b = {prop: 20}
  db.insertAll(Test, [a, b])
  const gt10 = db.first(Test.where(Test.prop.greater(10)))!
  assert.equal(gt10.prop, 20)
})

test('select', () => {
  const db = store()
  const Test = new Collection<typeof a & {id: string}>('test')
  const a = {propA: 10, propB: 5}
  const b = {propA: 20, propB: 5}
  db.insertAll(Test, [a, b])
  const res = db.all(Test.select({a: Test.propA, b: Test.propB}))
  assert.equal(res, [{a: 10, b: 5}, {a: 20, b: 5}])
  const res2 = db.first(Test.select(Test.fields.with({
    testProp: Expression.value(123)
  })))
  assert.is(res2.testProp, 123)
})

test.run()

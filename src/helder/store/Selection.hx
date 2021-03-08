package helder.store;

#if !macro
@:genericBuild(helder.store.SelectionFields.build()) 
#end
class Fields<T> {}

enum Selection<Fields> {
  FieldsOf<Row>(name: String): Selection<Row>;
}

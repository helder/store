package helder.store.macro;

function fieldFromType(type: Type) {
  return switch type {
    case TAbstract(_.get() => {
      module: 'helder.store.Expression', 
      name: 'Expression'
    }, [t]):
      return t.toComplexType();
    case TInst(_.get() => {
      module: 'helder.store.Cursor',
      name: 'Cursor'
    }, [t]):
      return t.toComplexType();
    default:
      return (macro: Dynamic);
  }
}

function create(expr: Expr) {
  switch Context.typeof(expr) {
    case TAnonymous(_.get() => {fields: fields}):
      final fields = [for (field in fields)
        ({
          name: field.name,
          kind: FVar(fieldFromType(field.type)),
          access: [APublic],
          pos: field.pos
        }: Field)
      ]; 
      final f = TAnonymous(fields);
      return macro @:pos(expr.pos) 
        (helder.store.Selection.Select.Fields(cast $expr): helder.store.Selection<$f>);
    case TAbstract(_.get() => {module: 'helder.store.Selection', name: 'Selection'}, params):
      return expr;
    case TAbstract(_.get() => {
        module: 'helder.store.Expression', 
        name: 'Expression'
      }, _):
      return macro @:pos(expr.pos) helder.store.Selection.Select.Expression($expr);
    case v: 
      trace(v);  
      throw 'todo';
  }
}
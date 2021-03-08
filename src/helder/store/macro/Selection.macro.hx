package helder.store.macro;

function fieldFromType(type: Type) {
  return switch type {
    case TInst(_.get() => {
      module: 'helder.store.Expression', 
      name: 'Expression'
    }, [t]):
      return t.toComplexType();
    default:
      return (macro: Dynamic);
  }
}

function create(expr: Expr) {
  final type = Context.typeof(expr);
  final fields = switch type {
    case TAnonymous(_.get() => {fields: fields}):
      [for (field in fields)
        ({
          name: field.name,
          kind: FVar(fieldFromType(field.type)),
          access: [APublic],
          pos: field.pos
        }: Field)
      ]; 
    default: throw 'todo';
  }
  final type = TAnonymous(fields);
  return macro (null: helder.store.Selection<$type>);
}
package helder.store.sqlite;

private inline var BACKTICK = '`'.code;

function escape(v:Any):String {
  if (Std.is(v, Bool)) return v ? '1' : '0';
  if (v == null || Std.is(v, Int)) return '$v';
  return escapeString('$v');
}

function escapeString(s: String) {
  return "'"+s.replace("'", "''")+"'";
}

function escapeId(s: String) {
  var buf = new StringBuf();
  inline function tick()
    buf.addChar(BACKTICK);
  tick();
  for (c in 0...s.length) 
    switch s.fastCodeAt(c) {
      case BACKTICK: tick(); tick();
      case v: buf.addChar(v);
    }
  tick();
  return buf.toString();
}
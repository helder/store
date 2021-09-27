package helder.store.util;

function chunk<T>(array: Array<T>, length: Int): Array<Array<T>> {
  var chunks = [];
  var i = 0;
  var n = array.length;
  while (i < n)
    chunks.push(array.slice(i, (i += length)));
  return chunks;
}
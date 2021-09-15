package scripts;

import sys.FileSystem;
import haxe.io.Path;

final esm = './dist/esm';
final cjs = './dist/cjs';

function main() {
  function clean(target: String) {
    final dir = Path.join([esm, target]);
    final files = FileSystem.readDirectory(dir);
    var removed = 0;
    for (file in files) {
      if (FileSystem.isDirectory(Path.join([esm, target, file]))) 
        removed += clean(Path.join([target, file])) ? 1 : 0;
      else 
        if (!FileSystem.exists(Path.join([cjs, target, file]))) {
          removed++;
          FileSystem.deleteFile(Path.join([esm, target, file]));
        }
    }
    final isEmpty = removed == files.length;
    if (isEmpty) FileSystem.deleteDirectory(dir);
    return isEmpty;
  }
  clean('');
}
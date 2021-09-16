package scripts;

import sys.FileSystem;
import haxe.io.Path;
using StringTools;

final esm = './dist/esm';
final cjs = './dist/cjs';

final keep = ['OrderBy', 'Document', 'Map', 'StdTypes'];

function main() {
  function clean(target: String) {
    final dir = Path.join([esm, target]);
    final files = FileSystem.readDirectory(dir);
    var removed = 0;
    for (file in files) {
      if (FileSystem.isDirectory(Path.join([esm, target, file]))) {
        removed += clean(Path.join([target, file])) ? 1 : 0;
      } else {
        final name = file.substr(0, file.indexOf('.'));
        if (keep.indexOf(name) > -1) continue;
        if (!FileSystem.exists(
          Path.join([esm, target, name + '.js'])
        )) {
          removed++;
          FileSystem.deleteFile(Path.join([esm, target, file]));
        }
      } 
    }
    final isEmpty = removed == files.length;
    if (isEmpty) FileSystem.deleteDirectory(dir);
    return isEmpty;
  }
  clean('');
}
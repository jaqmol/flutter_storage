import 'package:path/path.dart' as p;
import 'dart:io';

Directory existingDirectory(String basePath, String directoryName) {
  var directoryPath = p.join(basePath, directoryName);
  var directoryDir = Directory(directoryPath);
  directoryDir.createSync(recursive: true);
  return directoryDir;
}

File existingFile(String basePath, String fileName) {
  var filePath = p.join(basePath, fileName);
  var fileFile = File(filePath);
  fileFile.createSync(recursive: true);
  return fileFile;
}

// Future<File> renameFile(String currentPath, String newPath) async {
//   var currentFile = File(currentPath);
//   return currentFile.rename(newPath);
// }
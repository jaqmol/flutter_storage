abstract class CompBuffer {
  fill();
  List<int> get bytes;
  readAllBytes();
  fixReadPosition();
}

enum CompBufferEndType {
  Semicolon,
  EOL,
  EOF,
}
import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import '../lib/src/escaping.dart';
import '../lib/src/unescaping.dart';
import '../lib/src/control_chars.dart';

void main() {
  test('String escaping', () {
    var escaped = escapeString(_text);
    expect(escaped.contains(ControlChars.newlineChar), isFalse);
    expect(escaped.contains(ControlChars.returnChar), isFalse);
    expect(escaped.contains(ControlChars.semicolonChar), isFalse);
    expect(escaped.contains(ControlChars.colonChar), isFalse);
  });
  test('String unescaping', () {
    var escaped = escapeString(_text);
    var unescaped = unescapeString(escaped);
    expect(unescaped, equals(_text));
  });
  test('Byte escaping and unescaping', () {
    var textBytes = utf8.encode(_text);
    var escaped = escapeBytes(textBytes);
    expect(escaped, isNotNull);
    expect(escaped.length, greaterThan(0));
    var unescaped = unescapeBytes(escaped);
    expect(unescaped, isNotNull);
    expect(unescaped.length, greaterThan(0));
    for (int i = 0; i < textBytes.length; i++) {
      int expectedByte = textBytes[i];
      int unescapedByte = unescaped[i];
      expect(unescapedByte, equals(expectedByte));
    }
  });
  test('Float radix encoding and decoding', () {
    double value = 42.23;
    String encoded = radixEncodeFloat(value);
    double decoded = radixDecodeFloat(encoded);
    expect(decoded, equals(value));
  });
}

const _text = """Lorem ipsum dolor sit amet, consectetur adipiscing elit: Quisque augue turpis; varius in dignissim at, tempus id sem. Donec sodales, enim quis semper suscipit, felis diam sollicitudin augue, eu euismod augue ligula sed arcu. Fusce blandit risus in augue auctor, nec faucibus leo placerat. Vivamus suscipit accumsan leo sed rutrum. Nunc non ornare eros. Vivamus eget lacinia felis. Pellentesque eget magna ut lectus tristique auctor. Phasellus rhoncus mi sed cursus placerat. Suspendisse imperdiet urna eget dolor sollicitudin, a faucibus nunc tempor. Cras ut nisi odio. Praesent rhoncus consectetur augue, at condimentum quam laoreet non. Aenean in dictum libero. Fusce molestie tortor nisl, quis varius ligula venenatis sed. Aenean felis ex, sodales sit amet est sed, molestie volutpat lorem. Nam metus ante, varius tincidunt augue ac, blandit lacinia massa. Morbi vitae quam non mi ultrices scelerisque.
Phasellus convallis nibh eros, quis faucibus felis feugiat eu. Morbi augue nisl, convallis a consequat id, dignissim et leo. Mauris eu massa augue. Quisque ornare risus nibh, non porta nisi aliquet sit amet. Donec quis lorem placerat, consequat ipsum viverra, tincidunt tellus. Suspendisse vel metus elementum, hendrerit purus sed, varius dolor. Nullam id porttitor sapien. Donec posuere purus sed ipsum porttitor, at euismod orci accumsan. Donec vestibulum elit id magna fermentum, ac maximus elit mattis. Integer sit amet vulputate ante.
Etiam a magna ligula. Nunc ut vestibulum nulla, quis vulputate quam. Phasellus eget purus pharetra, iaculis mi quis, convallis elit. Donec tempus vitae ex mattis pretium. Cras elementum laoreet justo, ut maximus nunc feugiat eu. Curabitur id lectus blandit, tempor sem id, posuere arcu. Praesent vitae porttitor enim. Proin est nisl, pharetra a mi sed, fringilla congue est. Sed nec ex elit. Nam at magna non libero sodales bibendum id sit amet augue. Mauris a erat elementum, euismod justo ac, lacinia orci. In venenatis nisl a felis dictum, id scelerisque risus rutrum. Ut aliquet turpis id bibendum tempor. Ut imperdiet elementum euismod. Duis placerat congue velit, eu tempus sapien egestas id.
Suspendisse ac ornare libero. Cras commodo erat tellus, vitae ultricies libero tristique eget. Vivamus interdum nibh ut quam viverra, eget auctor quam dictum. Curabitur feugiat vel dolor ut facilisis. Maecenas fermentum pellentesque metus. Fusce eu fringilla dui. Curabitur mattis sapien sit amet eros congue auctor. Vestibulum nec odio dui.
Nunc at nisi eu nunc hendrerit viverra eu eu elit. Phasellus maximus massa eget mi malesuada porttitor ac quis tellus. Sed finibus risus vehicula tellus imperdiet, ac maximus tellus ornare. Donec auctor est vel euismod faucibus. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Vivamus dignissim, lacus vitae mollis dignissim, dolor lectus iaculis sapien, quis vehicula massa ligula eu neque. Vestibulum tincidunt iaculis tempor. Maecenas ligula felis, commodo ut mauris eget, dignissim venenatis eros. Aliquam lobortis egestas aliquam. Vestibulum convallis ipsum non ex cursus fringilla. Nulla auctor enim augue, in auctor ipsum pharetra vitae. Aenean non ex tristique, rutrum turpis id, pharetra eros. Nulla risus justo, lacinia quis mollis eu, venenatis at lacus. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Vestibulum tempus neque ac quam convallis viverra. Proin lacinia, arcu eget sollicitudin molestie, nulla quam vulputate lectus, vitae fermentum dui sem id neque.""";
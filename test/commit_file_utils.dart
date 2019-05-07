import '../lib/src/commit_file.dart';
import '../lib/src/identifier.dart';
import '../lib/src/serialization/serializer.dart';
import '../lib/src/serialization/deserializer.dart';
import '../lib/src/serialization/model.dart';
import '../lib/src/index.dart';
import 'package:meta/meta.dart';
import 'line_serializer_utils.dart';

class CommitFileUtils {
  static String testCSV = """firstName	lastName	postalCode	birthday
Jerry	Austin	72544	2019-08-03T12:07:12-07:00
Hollee	Todd	7098	2018-09-24T15:40:28-07:00
Sarah	Hahn	9694	2018-06-01T03:05:32-07:00
Sierra	Aguirre	22-438	2020-01-07T10:40:38-08:00
Jescie	Barnes	99702-486	2019-04-14T13:44:49-07:00
Caldwell	Meyers	16223	2019-05-06T00:31:16-07:00
Aphrodite	Burgess	39772	2018-08-17T12:00:27-07:00
Geoffrey	Dorsey	R4L 8R1	2019-07-04T11:55:15-07:00
Xanthus	Lindsay	72549	2019-01-23T01:02:58-08:00
Demetrius	Moreno	4281	2019-11-26T10:12:31-08:00
Jeanette	Pace	61602	2019-08-09T09:19:47-07:00
Hayden	Roy	15812	2019-06-18T23:15:08-07:00
Vanna	Monroe	678414	2020-01-05T22:41:06-08:00
Willow	Powell	68856-203	2018-10-09T18:46:50-07:00
Jescie	Stuart	281345	2019-05-28T18:40:41-07:00
Fitzgerald	Barron	J3M 8C0	2020-03-21T20:59:18-07:00
Cathleen	Reyes	46452	2019-01-18T11:10:31-08:00
Maggie	Sweeney	1400	2019-06-03T04:45:21-07:00
Shafira	Montgomery	61814	2018-11-08T15:50:37-08:00
Jack	Ashley	13584	2018-05-04T16:15:42-07:00
Rama	Alvarado	097630	2020-01-03T03:06:53-08:00
Kamal	Alston	15927	2018-09-08T07:07:36-07:00
Mannix	Ruiz	19-355	2018-12-02T14:54:59-08:00
Karly	Ramos	263306	2018-09-05T14:20:28-07:00
Noble	Rutledge	5024	2019-01-11T19:46:06-08:00
Theodore	George	19757-349	2019-08-31T14:43:22-07:00
Chancellor	Morin	59760-622	2019-12-17T00:26:44-08:00
Coby	Jackson	78-113	2019-01-10T15:45:54-08:00
Emmanuel	Huffman	N8C 5QH	2018-11-20T02:14:45-08:00
Fitzgerald	Gallagher	70586-370	2018-09-14T04:30:58-07:00
Plato	Bishop	72121	2018-12-22T10:48:44-08:00
Alisa	Henry	01406	2018-11-11T15:36:10-08:00
Odette	Bender	24776-312	2019-02-24T10:16:52-08:00
Cameran	Delacruz	8867 PW	2018-09-08T17:05:26-07:00
Branden	Woodard	T6M 7H3	2019-06-09T20:05:00-07:00
Dorothy	Adkins	35399	2020-04-11T15:28:23-07:00
Echo	Valdez	22472	2018-09-26T13:30:40-07:00
Robert	Dotson	8200	2020-04-23T07:48:15-07:00
Bryar	Welch	9327	2018-10-17T11:50:34-07:00
Reed	Shepherd	DC7F 5WC	2019-03-25T07:49:20-07:00
Jarrod	Ross	2471	2019-06-04T09:51:45-07:00
Iona	Roberson	91232-666	2018-11-03T04:23:08-07:00
Lara	Sutton	92704	2020-02-27T11:16:07-08:00
Wynne	Mays	G8C 3S7	2018-07-17T17:38:00-07:00
Graham	Haynes	48008	2019-07-15T10:40:15-07:00
Noelani	Harrell	68147	2020-04-04T13:50:26-07:00
Steven	Elliott	2713	2019-12-08T09:16:28-08:00
Hillary	Beasley	2226	2018-05-10T03:20:58-07:00
Elmo	Alford	01149	2019-04-23T13:18:45-07:00
Melissa	Norman	28062	2020-01-29T20:53:02-08:00
Vincent	Peck	934380	2018-12-24T15:41:38-08:00
Roary	Shepard	67584	2020-03-24T04:17:35-07:00
Griffith	Preston	451151	2019-06-16T19:51:38-07:00
Keaton	Marks	047125	2018-08-22T16:29:31-07:00
Cole	Leonard	80673	2019-03-03T12:57:37-08:00
Damon	Dickson	9717	2019-02-09T22:38:41-08:00
Velma	Robertson	27616-611	2019-03-23T22:17:02-07:00
Athena	Lowe	T0Z 8QS	2018-08-17T16:34:43-07:00
Byron	Cote	439914	2019-05-26T08:10:01-07:00
Scarlett	Sanders	40314	2019-05-24T17:32:11-07:00
Candace	Fox	97557	2020-01-13T19:54:17-08:00
Maia	Gaines	93555	2020-01-12T04:32:08-08:00
Kaseem	Atkins	39968	2020-04-21T06:28:30-07:00
Imelda	Mejia	H6E 0L0	2018-09-09T07:03:54-07:00
Yoko	Decker	418126	2019-02-21T07:42:08-08:00
Lesley	Levy	27726	2020-01-07T12:01:25-08:00
Joan	Sloan	HN2 7YF	2020-01-17T10:10:43-08:00
Zahir	Mcdowell	24627	2018-07-20T20:25:48-07:00
Camilla	Pena	94894-311	2019-04-22T00:49:34-07:00
Kirby	Calderon	19773	2019-09-22T17:05:11-07:00
Alfonso	Harvey	1534	2018-04-29T21:26:34-07:00
Chava	Hooper	R5N 8B0	2020-01-29T04:31:07-08:00
Josephine	Burnett	69682	2019-05-04T07:39:20-07:00
Blythe	Harrell	24850	2018-07-28T01:40:05-07:00
Irma	Dorsey	34437	2019-11-25T14:30:25-08:00
Caleb	Kent	5103	2019-12-05T07:38:53-08:00
Kimberly	Mccarty	21512	2019-09-04T13:42:47-07:00
Ferdinand	Owen	10905	2018-07-28T07:38:12-07:00
Coby	Hancock	94035	2019-08-14T08:38:18-07:00
Mara	Workman	8417	2018-09-11T04:25:16-07:00
Sawyer	Murray	ZQ9X 4FI	2018-09-05T12:08:52-07:00
Angelica	Cherry	46706-250	2018-06-23T01:42:50-07:00
Rhoda	Gonzalez	685351	2019-07-02T21:18:55-07:00
Luke	Winters	94578	2019-04-15T13:24:22-07:00
Cheyenne	Nixon	138003	2019-06-03T13:34:59-07:00
Cain	Berger	925204	2019-09-20T20:54:57-07:00
Stewart	Washington	6663	2019-05-22T15:14:09-07:00
Alexis	Mcfadden	8406 WU	2019-02-07T05:09:21-08:00
Genevieve	Santiago	19746	2020-01-16T08:38:31-08:00
Noah	Jensen	06239	2018-06-24T04:59:17-07:00
Colby	Sutton	14688	2020-04-20T12:08:21-07:00
Hanae	Crosby	74344	2019-12-03T08:01:33-08:00
Britanney	Lott	60153	2018-11-21T06:32:05-08:00
Chaim	Stephenson	01155	2019-08-24T02:45:44-07:00
Lee	Finley	31229-805	2019-04-25T09:06:50-07:00
Caleb	Osborn	11313	2019-06-21T09:16:18-07:00
Justin	Ratliff	298587	2019-01-28T04:56:31-08:00
Graiden	Noble	38369	2020-03-16T16:48:16-07:00
Lewis	Mann	75180	2019-11-17T03:54:58-08:00
Kalia	Bryant	57006	2018-10-10T04:49:59-07:00""";

  static List<List<String>> testDataTable() =>
    testCSV.split('\n')
      .map<List<String>>((String s) => s.split('\t'))
      .toList();

  static CommitFileValueResult serializeValue() {
    var filename = 'value_commit_file.scl';
    var c = CommitFile(filename);
    var key = identifier();
    int startIndex;
    var s = c.valueSerializer(key, (int idx) {
      startIndex = idx;
    });
    s.string(LineSerializerUtils.testText);
    s.conclude();
    return CommitFileValueResult(c, filename, key, startIndex);
  }

  static CommitFileIndexResult serializeEmptyIndex() {
    var filename = 'empty_index_commit_file.scl';
    var c = CommitFile(filename);
    var i = Index();
    var s = c.indexSerializer(i.version);
    i.encode(s);
    int startIndex = s.concludeWithStartIndex();
    return CommitFileIndexResult(c, filename, i, startIndex);
  }
  
  static CommitFileFullIndexResult serializeFullIndex([CommitFile commitFile, Index index]) {
    var filename = 'full_index_commit_file.scl';
    var c = commitFile ?? CommitFile(filename);
    var idx = index ?? Index();
    var r1 = serializeMultipleValues(c);
    for (int i = 0; i < r1.keys.length; i++) {
      idx[r1.keys[i]] = r1.startIndexes[i];
    }
    var r2 = serializeMultipleModels(c);
    for (int i = 0; i < r2.keys.length; i++) {
      idx[r2.keys[i]] = r2.startIndexes[i];
    }
    var s = c.indexSerializer(idx.version);
    idx.encode(s);
    s.concludeWithStartIndex();
    return CommitFileFullIndexResult(c, filename, r1.keys, r1.words, r2.keys, r2.users, idx);
  }

  static MultipleCommitFileValueResults serializeMultipleValues([CommitFile commitFile]) {
    var filename = 'multiple_values_commit_file.scl';
    var c = commitFile ?? CommitFile(filename);
    var words = LineSerializerUtils.testText.split(' ');
    var keys = List<String>();
    var startIndexes = List<int>();
    for (String word in words) {
      var key = identifier();
      int startIndex;
      var s = c.valueSerializer(key, (int idx) {
        startIndex = idx;
      });
      s.string(word);
      s.conclude();
      keys.add(key);
      startIndexes.add(startIndex);
    }
    return MultipleCommitFileValueResults(c, filename, keys, words, startIndexes);
  }

  static CommitFileModelResult serializeModel() {
    var row = CommitFileUtils.testDataTable()[1];
    var user = User.fromRow(row);
    var filename = 'model_commit_file.scl';
    var c = CommitFile(filename);
    var k = identifier();
    var s = c.modelSerializer(k, user.type, user.version);
    user.encode(s);
    int startIndex = s.concludeWithStartIndex();
    return CommitFileModelResult(c, filename, k, user, startIndex);
  }

  static MultipleCommitFileModelResults serializeMultipleModels([CommitFile commitFile]) {
    var table = CommitFileUtils.testDataTable();
    var users = table.sublist(1).map<User>(
      (List<String> row) => User.fromRow(row),
    ).toList();
    var filename = 'multiple_models_commit_file.scl';
    var c = commitFile ?? CommitFile(filename);
    var startIndexes = List<int>();
    var keys = List<String>();
    for (User u in users) {
      var k = identifier();
      var s = c.modelSerializer(k, u.type, u.version);
      u.encode(s);
      startIndexes.add(s.concludeWithStartIndex());
      keys.add(k);
    }
    return MultipleCommitFileModelResults(c, filename, keys, users, startIndexes);
  }
}

class CommitFileFullIndexResult {
  final CommitFile commitFile;
  final String filename;
  final List<String> wordKeys;
  final List<String> words;
  final List<String> userKeys;
  final List<User> users;
  final Index index;
  CommitFileFullIndexResult(
    this.commitFile,
    this.filename,
    this.wordKeys,
    this.words,
    this.userKeys,
    this.users,
    this.index,
  );
}

class CommitFileValueResult {
  final CommitFile commitFile;
  final String filename;
  final String key;
  final int startIndex;
  CommitFileValueResult(
    this.commitFile, 
    this.filename, 
    this.key, 
    this.startIndex,
  );
}

class CommitFileIndexResult {
  final CommitFile commitFile;
  final String filename;
  final Index index;
  final int startIndex;
  CommitFileIndexResult(
    this.commitFile, 
    this.filename,
    this.index, 
    this.startIndex,
  );
}

class CommitFileModelResult {
  final CommitFile commitFile;
  final String filename;
  final String key;
  final User user;
  final int startIndex;
  CommitFileModelResult(
    this.commitFile, 
    this.filename, 
    this.key,
    this.user, 
    this.startIndex,
  );
}

class MultipleCommitFileValueResults {
  final CommitFile commitFile;
  final String filename;
  final List<String> keys;
  final List<String> words;
  final List<int> startIndexes;
  MultipleCommitFileValueResults(
    this.commitFile,
    this.filename,
    this.keys,
    this.words,
    this.startIndexes,
  );
}

class MultipleCommitFileModelResults {
  final CommitFile commitFile;
  final String filename;
  final List<String> keys;
  final List<User> users;
  final List<int> startIndexes;
  MultipleCommitFileModelResults(
    this.commitFile,
    this.filename,
    this.keys,
    this.users,
    this.startIndexes,
  );
}

// class KeyAndStartIndex {
//   final String key;
//   final int startIndex;
//   final int orderIndex;
//   KeyAndStartIndex(this.key, this.startIndex, this.orderIndex);
// }

class User extends Model {
  final String type = 'user';
  final int version = 0;

  final String firstName;
  final String lastName;
  final String postalCode;
  final String birthday;

  User({
    @required this.firstName,
    @required this.lastName,
    @required this.postalCode,
    @required this.birthday,
  });

  Serializer encode(Serializer serialize) =>
    serialize
      .string(firstName)
      .string(lastName)
      .string(postalCode)
      .string(birthday);

  User.decode(String type, int version, Deserializer deserialize) 
    : firstName = deserialize.string(),
      lastName = deserialize.string(),
      postalCode = deserialize.string(),
      birthday = deserialize.string();

  User.fromRow(List<String> row)
    : firstName = row[0],
      lastName = row[1],
      postalCode = row[2],
      birthday = row[3];
}
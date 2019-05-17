import 'package:flutter_test/flutter_test.dart';
import '../lib/src/serialization/model.dart';
import 'package:meta/meta.dart';
import '../lib/src/serialization/serializer.dart';
import '../lib/src/serialization/deserializer.dart';
import '../lib/src/storage.dart';
import '../lib/src/identifier.dart';
import '../lib/src/serialization/entry_info.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

void main() {
  var tmp = Directory.systemTemp.path;
  print('Temporary directory: $tmp');
  test('Write and read single model', () async {
    var filename = path.join(tmp, 'write_read_single_model_test.scl');
    var tu = _testUsers[42];
    var key = identifier();
    var st = await Storage.open(filename);
    await st.putModel(key, tu);
    var des1 = await st.deserializer(key);
    var info = des1.entryInfo as ModelInfo;
    var tu1 = decodeUser(info.modelType, info.modelVersion, des1);
    expect(tu1.firstName, equals(tu.firstName));
    expect(tu1.lastName, equals(tu.lastName));
    expect(tu1.postalCode, equals(tu.postalCode));
    expect(tu1.birthday, equals(tu.birthday));
    var tu2 = await st.getModel<User>(key, decodeUser);
    expect(tu2.firstName, equals(tu.firstName));
    expect(tu2.lastName, equals(tu.lastName));
    expect(tu2.postalCode, equals(tu.postalCode));
    expect(tu2.birthday, equals(tu.birthday));
    await File(filename).delete();
  });
  test('Write and read multiple models', () async {
    var filename = path.join(tmp, 'write_read_multiple_models_test.scl');
    var st = await Storage.open(filename);
    var expectedUsers = <String, User>{};
    for (var tu in _testUsers) {
      var key = identifier();
      await st.putModel(key, tu);
      expectedUsers[key] = tu;
    }
    for (var key in expectedUsers.keys) {
      var eu = expectedUsers[key];
      var gu = await st.getModel<User>(key, decodeUser);
      expect(gu.firstName, equals(eu.firstName));
      expect(gu.lastName, equals(eu.lastName));
      expect(gu.postalCode, equals(eu.postalCode));
      expect(gu.birthday, equals(eu.birthday));
    }
    await File(filename).delete();
  });
  test('Indexing models', () async {
    var filename = path.join(tmp, 'indexing_models_test.scl');
    var st = await Storage.open(filename);
    var expectedUsers = _testUsers.map<MapEntry<String, User>>(
      (User u) => MapEntry<String, User>(identifier(), u),
    ).toList();
    for (var me in expectedUsers) {
      await st.putModel(me.key, me.value);
    }
    await st.flush();
    st = await Storage.open(filename);
    for (var me in expectedUsers) {
      var gu = await st.getModel<User>(me.key, decodeUser);
      expect(gu, isNotNull);
      expect(usersEqual(gu, me.value), isTrue);
    }
    await File(filename).delete();
  });
  test('Modify multiple models with correct flushing', () async {
    var filename = path.join(tmp, 'modify_multiple_models_wflush_test.scl');
    var st = await Storage.open(filename);
    var expectedUsers = _testUsers.map<MapEntry<String, User>>(
      (User u) => MapEntry<String, User>(identifier(), u),
    ).toList();
    for (var me in expectedUsers) {
      await st.putModel(me.key, me.value);
    }
    await st.flush();
    var changedUsers = _testUsersChanges.sublist(0, 42);
    for (int i = 0; i < changedUsers.length; i++) {
      var cu = changedUsers[i];
      var eume = expectedUsers[i];
      await st.putModel(eume.key, cu);
    }
    await st.flush();
    st = await Storage.open(filename);
    for (int i = 0; i < changedUsers.length; i++) {
      var eume = expectedUsers[i];
      var gu = await st.getModel<User>(eume.key, decodeUser);
      if (i < 42) {
        var cu = changedUsers[i];
        expect(usersEqual(gu, eume.value), isFalse);
        expect(usersEqual(gu, cu), isTrue);
      } else {
        expect(usersEqual(gu, eume.value), isTrue);
      }
    }
    await File(filename).delete();
  });
  test('Modify multiple models with incorrect flushing', () async {
    var filename = path.join(tmp, 'modify_multiple_models_woflush_test.scl');
    var st = await Storage.open(filename);
    var expectedUsers = _testUsers.map<MapEntry<String, User>>(
      (User u) => MapEntry<String, User>(identifier(), u),
    ).toList();
    for (var me in expectedUsers) {
      await st.putModel(me.key, me.value);
    }
    await st.flush();
    var changedUsers = _testUsersChanges.sublist(0, 42);
    for (int i = 0; i < changedUsers.length; i++) {
      var cu = changedUsers[i];
      var eume = expectedUsers[i];
      await st.putModel(eume.key, cu);
    }
    // DELIBERATELY OMITTING: await st.flush();
    st = await Storage.open(filename);
    for (int i = 0; i < changedUsers.length; i++) {
      var eume = expectedUsers[i];
      var gu = await st.getModel<User>(eume.key, decodeUser);
      if (i < 42) {
        var cu = changedUsers[i];
        expect(usersEqual(gu, eume.value), isFalse);
        expect(usersEqual(gu, cu), isTrue);
      } else {
        expect(usersEqual(gu, eume.value), isTrue);
      }
    }
    await File(filename).delete();
  });
}

List<User> get _testUsers => _decodeCSV(_testCSV);
List<User> get _testUsersChanges => _decodeCSV(_testChangesCSV);

List<User> _decodeCSV(String csvStr) => csvStr.split('\n')
    .sublist(1)
    .map<List<String>>((String line) => line.split('\t'))
    .map<User>((List<String> props) => User.fromRow(props))
    .toList();

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

  User.fromRow(List<String> row)
    : firstName = row[0],
      lastName = row[1],
      postalCode = row[2],
      birthday = row[3];
}

User decodeUser(String type, int version, Deserializer deserialize) => User(
  firstName: deserialize.string(),
  lastName: deserialize.string(),
  postalCode: deserialize.string(),
  birthday: deserialize.string(),
);

bool usersEqual(User a, User b) =>
  a.firstName == b.firstName &&
  a.lastName == b.lastName &&
  a.postalCode == b.postalCode &&
  a.birthday == b.birthday;

String _testCSV = """firstName	lastName	postalCode	birthday
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

String _testChangesCSV = """firstName	lastName	postalCode	birthday
Jordan	Contreras	47980	2018-10-03T12:47:04-07:00
Indira	Chaney	21517	2019-09-14T18:20:56-07:00
Sylvester	Jenkins	5704	2019-02-07T06:31:03-08:00
Jana	Figueroa	48900	2018-12-23T04:41:24-08:00
Maisie	Wheeler	B8J 1J3	2019-12-19T13:07:50-08:00
Daryl	Mosley	0211	2018-07-28T09:29:45-07:00
Casey	Keller	92-397	2019-03-25T13:54:20-07:00
John	Wong	2939	2019-07-01T16:18:11-07:00
Marny	Dorsey	56145	2018-11-03T14:38:20-07:00
Ingrid	Baird	23181	2019-01-12T15:25:53-08:00
Claire	Mason	7951 PJ	2019-12-12T15:24:39-08:00
Ayanna	Walter	4757	2018-12-17T04:22:18-08:00
Drew	Maddox	11773-316	2018-06-07T16:06:48-07:00
Jael	Calderon	3149	2019-07-12T01:34:21-07:00
Jenna	Barlow	2483	2019-08-07T18:07:05-07:00
Carson	Simon	43175	2019-02-12T20:37:18-08:00
Caryn	Poole	G8 6BU	2019-07-29T22:21:37-07:00
Risa	Blackburn	330709	2018-05-29T08:48:55-07:00
Maisie	Montgomery	1358 ZS	2018-07-24T08:08:36-07:00
Catherine	Goodwin	40620	2019-03-03T21:28:48-08:00
Althea	Hutchinson	29652	2018-11-01T05:20:24-07:00
Neville	Sawyer	4198	2018-11-19T12:52:51-08:00
Aidan	Ramos	7916 HP	2018-07-13T07:35:34-07:00
Isaiah	Mathews	204214	2018-06-18T12:32:00-07:00
Plato	Stephens	IX4 2VP	2020-01-14T23:03:43-08:00
Chadwick	Santiago	41779	2018-11-16T01:53:30-08:00
Quinn	Gould	31310	2018-10-19T00:56:27-07:00
Raymond	Murray	1352	2018-08-11T19:47:49-07:00
Daniel	Atkinson	IA3A 7PQ	2019-09-27T15:28:17-07:00
Dalton	Cherry	76993	2019-08-26T18:04:47-07:00
Ferdinand	Mays	73346-257	2020-05-09T16:13:12-07:00
Shelby	Brennan	30582	2020-03-17T04:10:09-07:00
Moses	Snow	71802	2018-08-07T12:52:25-07:00
Daniel	Raymond	A8T 7K7	2019-01-14T10:56:46-08:00
Kuame	Mcclain	703667	2019-08-04T03:10:35-07:00
Gemma	Potts	53628	2020-05-13T14:35:32-07:00
Cooper	Madden	MT9 2SJ	2018-08-09T07:55:29-07:00
Sloane	Goff	11414	2019-10-28T17:04:20-07:00
Levi	Curry	3662	2018-08-05T08:12:08-07:00
Florence	Blake	56726	2019-09-12T12:20:17-07:00
Remedios	Coleman	7000	2019-02-14T01:41:20-08:00
Nichole	Donovan	925868	2019-11-06T06:42:50-08:00
Lenore	Vasquez	2856	2019-10-05T20:21:59-07:00
Devin	Barker	61344	2019-06-07T12:46:48-07:00
Hammett	Kline	79375	2020-05-14T05:48:06-07:00
Summer	Brooks	50101	2019-05-30T09:20:30-07:00
Dorothy	Harrell	44073	2020-01-13T09:21:59-08:00
Uriel	Poole	43830	2019-09-18T21:53:44-07:00
Francis	Reed	18227	2020-05-13T20:48:40-07:00
Kelsie	Acevedo	968098	2018-05-16T08:25:30-07:00
Clarke	Bender	31000-214	2018-07-05T13:17:30-07:00
Guinevere	Owens	43314	2020-05-09T17:49:59-07:00
Nathan	Phelps	4666	2019-02-20T03:24:07-08:00
Brady	Moody	73750	2019-04-25T00:04:03-07:00
Cyrus	Delacruz	5274	2018-11-19T04:03:29-08:00
Howard	Finley	505175	2019-11-17T11:15:48-08:00
Coby	Ellison	7751	2019-03-31T07:29:34-07:00
Kane	Allen	314051	2019-09-01T20:07:27-07:00
Robert	Patterson	6515	2020-05-08T17:11:33-07:00
Lyle	Mullins	1631	2018-08-10T13:16:46-07:00
Hammett	Glenn	69353	2019-11-28T15:52:01-08:00
Julian	Nielsen	09164	2018-12-27T13:19:49-08:00
Randall	Villarreal	9660 KR	2018-05-19T18:15:44-07:00
Clarke	Harding	03870	2020-03-27T21:14:16-07:00
Odysseus	Cameron	1273	2019-08-08T11:44:32-07:00
Quinlan	Weber	522352	2018-11-23T00:52:15-08:00
Wylie	Willis	8477	2018-09-23T20:48:50-07:00
Susan	Nielsen	Q7T 4IS	2018-05-20T19:51:58-07:00
Timothy	Mcconnell	UC6 1XZ	2018-07-14T06:35:59-07:00
Brandon	Cohen	S7T 2W4	2018-11-26T19:26:51-08:00
Paul	Henson	2646	2019-10-06T00:53:23-07:00
Jolie	Bentley	284236	2018-11-17T04:09:36-08:00
Jane	Golden	4292	2018-07-13T06:15:30-07:00
Arsenio	Petersen	96711	2019-10-27T17:38:14-07:00
Adara	Palmer	72720	2019-11-16T21:48:34-08:00
Garrett	Sykes	11005	2019-03-21T04:51:12-07:00
Howard	Carey	260135	2020-01-03T00:46:02-08:00
Brenda	Hurley	38176	2020-03-28T23:03:22-07:00
Preston	Mitchell	83683	2018-11-21T08:30:04-08:00
Angela	Stanton	08427	2018-09-01T15:19:41-07:00
Alisa	Small	51400-132	2019-03-27T19:23:59-07:00
Heidi	Christian	30639	2019-02-20T08:25:44-08:00
Tatyana	Guthrie	2164 XI	2018-10-13T10:27:26-07:00
Callum	Cash	997958	2019-02-03T16:39:51-08:00
Camille	Knowles	02974-724	2018-08-14T21:05:40-07:00
Blaze	Larsen	11220	2020-05-16T06:42:07-07:00
Montana	Forbes	56975	2019-01-24T15:00:57-08:00
Sharon	Wise	46203	2019-10-17T14:07:47-07:00
Ramona	Espinoza	NF66 5BH	2018-06-20T04:49:29-07:00
Kerry	Bonner	09317	2018-06-03T08:08:31-07:00
Garrett	Leonard	79663	2018-10-17T22:32:32-07:00
Curran	Lott	37019	2018-11-13T00:41:57-08:00
Hammett	Montgomery	42404	2019-11-13T08:20:18-08:00
Micah	Flowers	474685	2019-04-16T01:19:42-07:00
Bruno	Johnson	72733	2018-11-21T07:45:29-08:00
Denise	Rush	42676	2018-07-23T17:01:40-07:00
Ray	Bishop	J8W 3E0	2019-01-31T17:23:51-08:00
Neville	Herrera	593069	2018-06-25T04:49:47-07:00
Erich	Moss	7140	2018-05-22T22:39:47-07:00
Donovan	Guthrie	79325	2019-11-25T00:00:52-08:00""";
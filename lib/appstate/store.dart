import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class IdGenerator {
  // Generating the current timestamp in milliseconds since Unix epoch
  static int _getTimestamp() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  // Generating a random 5-byte value
  static String _getRandomPart() {
    final rand = Random();
    List<int> randomBytes =
        List.generate(5, (index) => rand.nextInt(256)); // 5 bytes
    return base64Url
        .encode(randomBytes); // Encoding to base64 to get the random string
  }

  // Creating a counter or machine-specific part (e.g., machine ID, process ID, or simple counter)
  static String _getCounter() {
    // This is a simplistic approach; you'd replace this with a process or machine ID in a real-world case.
    return Random().nextInt(256).toString().padLeft(3, '0');
  }

  // Combine the parts and generate the final ID
  static String generateId() {
    final timestamp = _getTimestamp()
        .toRadixString(16)
        .padLeft(8, '0'); // 8-character hex timestamp
    final randomPart = _getRandomPart();
    final counter = _getCounter();

    // Combine them into one string
    return '$timestamp$randomPart$counter';
  }
}

class Store {
  String collection;
  Store._internal(this.collection);
  static Future<Store> create(String collection) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(collection) == false) {
//      print("Creating collection");
      await prefs.setStringList(collection, []);
    } else {
      //    print("Collection already exists");
    }
    return Store._internal(collection);
  }

  static Future<List<String>> _get(String collection) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(collection) ?? [];
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print("collection $collection");

    List<String>? rawList = prefs.getStringList(collection);
    if (rawList == null) {
      return [];
    }

    List<Map<String, dynamic>> decodedList =
        rawList.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

    return decodedList;
  }

  Future<int> count() async {
    List<String> data = await _get(collection);
    return data.length;
  }

  Future<bool> insert(Map<String, dynamic> value) async {
    //collectionName.insert({"name": value["name"], "age": value["age"]});
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> currentData = await _get(collection);
    value["_id"] = IdGenerator.generateId();
    currentData.add(jsonEncode(value));
    return await prefs.setStringList(collection, currentData);
  }

  Future<bool> insertMany(List<Map<String, dynamic>> value) async {
    //collectionName.insertMany([{"name": value["name"], "age": value["age"]}]);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> currentData = await _get(collection);
    currentData.addAll(value.map((e) {
      e["_id"] = IdGenerator.generateId();
      return jsonEncode(e);
    }).toList());

    return await prefs.setStringList(collection, currentData);
  }

//to be fixed
  Future<bool> updateOneById(String id, Map<String, dynamic> value) async {
    //collectionName.update({"name": value["name"], "age": value["age"]});
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> currentData = await _get(collection);
    int index =
        currentData.indexWhere((element) => jsonDecode(element)["_id"] == id);
    if (index != -1) {
      currentData[index] =
          jsonEncode({...jsonDecode(currentData[index]), ...value});
    }

    return await prefs.setStringList(collection, currentData);
  }

  Future<bool> deleteOneById(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> currentData = await _get(collection);
    currentData.removeWhere((element) => jsonDecode(element)["_id"] == id);
    return await prefs.setStringList(collection, currentData);
  }

  Future<bool> deleteCollection() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.remove(collection);
  }

  Future<List<Map<String, dynamic>>> find(Map<String, dynamic> query) async {
    List<Map<String, dynamic>> allData = await getAll();

    return allData.where((document) {
      return _matchesQuery(document, query);
    }).toList();
  }

  /// Matches a single document against the query
  bool _matchesQuery(
      Map<String, dynamic> document, Map<String, dynamic> query) {
    for (var key in query.keys) {
      var queryValue = query[key];

      if (queryValue is Map<String, dynamic>) {
        // If the query value is a map, check for special MongoDB-like operators
        for (var op in queryValue.keys) {
          var expectedValue = queryValue[op];

          switch (op) {
            case r'$gt': // Greater than
              if (!(document[key] > expectedValue)) return false;
              break;
            case r'$lt': // Less than
              if (!(document[key] < expectedValue)) return false;
              break;
            case r'$gte': // Greater than or equal
              if (!(document[key] >= expectedValue)) return false;
              break;
            case r'$lte': // Less than or equal
              if (!(document[key] <= expectedValue)) return false;
              break;
            case r'$ne': // Not equal
              if (document[key] == expectedValue) return false;
              break;
            case r'$in': // Value exists in a list
              if (!(expectedValue is List &&
                  expectedValue.contains(document[key]))) return false;
              break;
            case r'$like': // Partial match (string contains)
              if (!(document[key] is String &&
                  (document[key] as String).contains(expectedValue))) {
                return false;
              }
              break;
            case r'$or': // Logical OR
              if (expectedValue is List) {
                bool orMatch = expectedValue
                    .any((subQuery) => _matchesQuery(document, subQuery));
                if (!orMatch) return false;
              }
              break;
            case r'$and': // Logical AND
              if (expectedValue is List) {
                bool andMatch = expectedValue
                    .every((subQuery) => _matchesQuery(document, subQuery));
                if (!andMatch) return false;
              }
              break;
            case r'$not': // Logical NOT
              if (_matchesQuery(document, expectedValue)) return false;
              break;
            default:
              throw ArgumentError('Unknown operator: $op');
          }
        }
      } else {
        // Normal exact match
        if (document[key] != queryValue) return false;
      }
    }
    return true;
  }
}

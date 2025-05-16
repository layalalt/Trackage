import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;

class CsvDataProvider {
  static List<dynamic> headers = [];
  static List<List<dynamic>> dataRows = [];

  static Future<void> fetchData(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Pre-process CSV to handle empty columns
        final csvString = _normalizeCsv(response.body);
        final csvTable = _parseCsv(csvString);

        headers = csvTable[0];
        dataRows = _ensureColumnCount(csvTable.sublist(1), headers.length);

        _logDataStats();
      } else {
        throw Exception("Failed to load CSV: HTTP ${response.statusCode}");
      }
    } catch (e) {
      print("❌ CSV Error: ${e.toString()}");
      rethrow;
    }
  }

  static List<dynamic>? getUserRow(String reservationID, String lastName) {
    try {
      final cleanResID = reservationID.trim().toLowerCase();
      final cleanLastName = lastName.trim().toLowerCase();

      return dataRows.firstWhere(
            (row) => _isMatch(row, cleanResID, cleanLastName),
        orElse: () => <dynamic>[],
      );
    } catch (e) {
      print("⚠️ getUserRow error: ${e.toString()}");
      return [];
    }
  }

  // -- Helper Methods -- //

  static String _normalizeCsv(String rawCsv) {
    return rawCsv
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
  }

  static List<List<dynamic>> _parseCsv(String csvString) {
    return const CsvToListConverter(
      shouldParseNumbers: false,
      allowInvalid: true,
      textDelimiter: '"',
      eol: '\n',
    ).convert(csvString);
  }

  static List<List<dynamic>> _ensureColumnCount(
      List<List<dynamic>> rows,
      int expectedCount
      ) {
    return rows.map((row) {
      return List<dynamic>.generate(
        expectedCount,
            (i) => i < row.length ? row[i]?.toString()?.trim() ?? '' : '',
      );
    }).toList();
  }

  static bool _isMatch(List<dynamic> row, String resID, String lastName) {
    try {
      return row.length > 5 &&
          row[3].toString().toLowerCase() == resID &&
          row[5].toString().toLowerCase() == lastName;
    } catch (e) {
      return false;
    }
  }

  static void _logDataStats() {
    print('''
✅ CSV Load Successful
- Headers: ${headers.length} columns
- Data Rows: ${dataRows.length}
- Sample Row: ${dataRows.first.take(6)}...''');
  }

  static int getColumnIndex(String headerName) {
    return headers.indexOf(headerName);
  }

}
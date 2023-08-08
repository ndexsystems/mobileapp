import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

class Positions extends StatefulWidget {
  const Positions({Key? key}) : super(key: key);

  @override
  _PositionsState createState() => _PositionsState();
}

class _PositionsState extends State<Positions> {
  Future<Database>? hhposdbFuture;

  @override
  void initState() {
    super.initState();
    hhposdbFuture = loadCsvData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Database>(
      future: hhposdbFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          if (snapshot.data != null) {
            return PositionList(hhposdb: hhposdbFuture!);
          } else {
            return const Text('Something went wrong');
          }
        }
      },
    );
  }

  Future<Database> loadCsvData() async {
    final csvData = await rootBundle.loadString('assets/hhpositions.csv');

    List<List<dynamic>> rowsAsListOfValues =
        const CsvToListConverter().convert(csvData);

    String path = join(await getDatabasesPath(), 'hhpositions.db');

    Database hhposdb = await openDatabase(path, version: 1,
        onCreate: (Database hhposdb, int version) async {
      await hhposdb.execute(
          "CREATE TABLE hhpositions (Symbol TEXT, Description TEXT, Value REAL)");
    });

    await hhposdb.delete('hhpositions');

    Batch batch = hhposdb.batch();
    for (List<dynamic> row in rowsAsListOfValues) {
      batch.insert('hhpositions',
          {'Symbol': row[0], 'Description': row[1], 'Value': row[2]});
    }

    await batch.commit();

    return hhposdb;
  }

  @override
  void dispose() {
    hhposdbFuture!.then((hhposdb) => hhposdb.close());
    super.dispose();
  }
}

class PositionList extends StatelessWidget {
  final Future<Database> hhposdb;

  const PositionList({
    Key? key,
    required this.hhposdb,
  }) : super(key: key);

  Future<List<Map<String, dynamic>>> _fetchPositions() async {
    final database = await hhposdb;
    return await database.query('hhpositions');
  }

  DataRow _dataRow(Map<String, dynamic> record) {
    final value = double.tryParse(record['Value'].toString()) ?? 0.0;
    final formattedValue = NumberFormat('#,##0.00').format(value);

    return DataRow(
      cells: [
        DataCell(Text(
          record['Symbol'].toString(),
          style: const TextStyle(fontSize: 12.0, color: Colors.black),
        )),
        DataCell(Text(
          record['Description'].toString(),
          style: const TextStyle(fontSize: 12.0, color: Colors.black),
        )),
        DataCell(Align(
          alignment: Alignment.centerRight,
          child: Text(
            '\$$formattedValue',
            style: const TextStyle(fontSize: 12.0, color: Colors.black),
          ),
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchPositions(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          return SingleChildScrollView(
            child: DataTable(
              columns: [
                DataColumn(
                  label: Text(
                    'Symbol',
                    style: headingTextStyle(),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Description',
                    style: headingTextStyle(),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Value',
                    style: headingTextStyle(),
                  ),
                ),
              ],
              rows: snapshot.data!.map(_dataRow).toList(),
            ),
          );
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }

  TextStyle headingTextStyle() {
    return TextStyle(
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.bold,
      fontSize: 14,
      color: Colors.indigo.shade800,
    );
  }
}

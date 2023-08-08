import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path/path.dart';

class PieChartPage extends StatefulWidget {
  const PieChartPage({Key? key}) : super(key: key);

  @override
  _PieChartPageState createState() => _PieChartPageState();
}

class _PieChartPageState extends State<PieChartPage> {
  late Database db;
  List<PieChartSectionData> pieChartSections = [];

  Future<void> loadCsvData() async {
    final csvData = await rootBundle.loadString('assets/hhallocation.csv');
    List<List<dynamic>> rowsAsListOfValues =
        const CsvToListConverter().convert(csvData);

    String path = join(await getDatabasesPath(), 'hhallocation.db');

    db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute(
          "CREATE TABLE hhallocation (id INTEGER PRIMARY KEY, classification TEXT, allocation REAL)");
    });

    // Delete all rows from the 'hhallocation' table before loading new data.
    await db.delete('hhallocation');

    Batch batch = db.batch();
    for (List<dynamic> row in rowsAsListOfValues) {
      batch.insert('hhallocation',
          {'id': row[0], 'classification': row[1], 'allocation': row[2]});
    }
    await batch.commit();

    List<Map<String, dynamic>> result = await db.query('hhallocation');

    Map<String, double> dataMap = {};
    for (Map<String, dynamic> item in result) {
      dataMap[item['classification']] = item['allocation'];
    }

    int i = 0;
    for (var element in dataMap.entries) {
      Color color;
      switch (i % 3) {
        case 0:
          color = Colors.blue;
          break;
        case 1:
          color = Colors.red;
          break;
        case 2:
          color = Colors.green;
          break;
        default:
          color = Colors.grey;
      }
      pieChartSections.add(PieChartSectionData(
        color: color,
        value: element.value,
        title: element.key,
        radius: 30,
      ));
      i++;
    }
    await db.close(); // Closing the database connection
  }

  Future? _loadDataFuture;

  @override
  void initState() {
    super.initState();
    _loadDataFuture = loadCsvData(); // Save the Future returned by loadCsvData
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                "Asset Allocation",
                style: TextStyle(
                    color: Color.fromARGB(255, 5, 34, 58), fontSize: 14),
              ),
              backgroundColor: Colors.white,
              centerTitle: true, // this will center the title
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Stack(
                  children: <Widget>[
                    SizedBox(
                      width:
                          350, // Adjust this value to give enough space for your legend text
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment
                            .start, // This aligns the column items to the left.
                        children: pieChartSections
                            .map((section) => Padding(
                                  padding:
                                      const EdgeInsets.only(left: 2, top: 10),
                                  child: Row(
                                    children: <Widget>[
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.rectangle,
                                          color: section.color,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        // This wraps the text and makes sure it takes up the rest of the space in the row.
                                        child: Text(
                                          '${section.title} (${(section.value * 100).toStringAsFixed(1)}%)',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    Positioned(
                      top: 0, // Adjust this value to move the chart up or down
                      right: 0,
                      child: SizedBox(
                        width: 150,
                        height: 150,
                        child: PieChart(
                          PieChartData(
                            sections: pieChartSections.map((section) {
                              return PieChartSectionData(
                                color: section.color,
                                value: section.value,
                                title: '',
                                showTitle: false,
                                radius: section.radius,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ); // Show a progress indicator while loading the data
        }
      },
    );
  }
}

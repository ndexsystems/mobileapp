import 'dart:core';
import 'package:flutter/material.dart';
import 'customs/header.dart';
import 'customs/hhpositions.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade500,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Harris Family Household",
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 250, // Change this value as needed
              width: MediaQuery.of(context).size.width, // Full width
              child: const PieChartPage(),
            ),
            SizedBox(
              height: 400, // Change this value as needed
              width: MediaQuery.of(context).size.width, // Full width
              child: const Positions(),
            ),
          ],
        ),
      ),
    );
  }
}

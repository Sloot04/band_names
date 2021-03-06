import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:provider/provider.dart';

import 'package:band_names/models/band.dart';
import 'package:band_names/services/socket_services.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Band> bands = [];

  @override
  void initState() {
    final socketServices = Provider.of<SocketService>(context, listen: false);
    socketServices.socket.on('active-bands', _handleActiveBands);
    super.initState();
  }

  _handleActiveBands(dynamic payload) {
    this.bands = (payload as List).map((band) => Band.fromMap(band)).toList();
    setState(() {});
  }

  @override
  void dispose() {
    final socketServices = Provider.of<SocketService>(context, listen: false);
    socketServices.socket.off('active-bands');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socketServices = Provider.of<SocketService>(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'BandNames',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 10),
            child: socketServices.serverStatus == ServerStatus.Online
                ? Icon(Icons.check_circle, color: Colors.blue.shade300)
                : Icon(Icons.offline_bolt, color: Colors.red),
          ),
        ],
      ),
      body: Column(
        children: [
          _showGraph(),
          Expanded(
            child: ListView.builder(
              itemCount: bands.length,
              itemBuilder: (context, i) => _bandTile(bands[i]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addNewBand,
        child: Icon(Icons.add),
        elevation: 1,
      ),
    );
  }

  Widget _bandTile(Band band) {
    final socketService = Provider.of<SocketService>(context, listen: false);

    return Dismissible(
      key: Key(band.id),
      direction: DismissDirection.startToEnd,
      onDismissed: (DismissDirection dismiss) =>
          socketService.socket.emit('delete-band', {'id': band.id}),
      background: Container(
        padding: EdgeInsets.only(left: 8.0),
        color: Colors.red.withOpacity(0.8),
        child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Delete Band',
              style: TextStyle(color: Colors.white),
            )),
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(band.name.substring(0, 2)),
          backgroundColor: Colors.blue.shade100,
        ),
        title: Text(band.name),
        trailing: Text(
          '${band.votes}',
          style: TextStyle(fontSize: 20),
        ),
        onTap: () => socketService.socket.emit('vote-band', {'id': band.id}),
      ),
    );
  }

  addNewBand() {
    final TextEditingController textController = TextEditingController();

    if (Platform.isAndroid) {
      return showDialog(
          context: context,
          builder: (_) => AlertDialog(
                title: Text('New band name'),
                content: TextField(controller: textController),
                actions: [
                  MaterialButton(
                    onPressed: () => addBandToList(textController.text),
                    child: Text('Add'),
                    elevation: 5,
                    textColor: Colors.blue,
                  )
                ],
              ));
    }
    showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
              title: Text('New ban name'),
              content: CupertinoTextField(controller: textController),
              actions: [
                CupertinoDialogAction(
                  child: Text('add'),
                  isDefaultAction: true,
                  onPressed: () => addBandToList(textController.text),
                ),
                CupertinoDialogAction(
                  child: Text('Dismiss'),
                  isDestructiveAction: true,
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ));
  }

  void addBandToList(String name) {
    if (name.length > 1) {
      final socketServices = Provider.of<SocketService>(context, listen: false);
      socketServices.socket.emit('add-band', {'name': name});
    }
    Navigator.pop(context);
  }

  // Mostrar g??fica

  Widget _showGraph() {
    Map<String, double> dataMap = new Map();
    bands.forEach(
        (band) => dataMap.putIfAbsent(band.name, () => band.votes.toDouble()));

    final List<Color> colorList = [
      Colors.blue.shade50,
      Colors.blue.shade200,
      Colors.red.shade100,
      Colors.red.shade200,
      Colors.yellow.shade50,
      Colors.yellow.shade200,
      Colors.green.shade50,
      Colors.green.shade200,
    ];
    if (dataMap.isEmpty) {
      return Container(height: 0, width: 0);
    }
    return Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        width: double.infinity,
        height: 200,
        child: PieChart(
          dataMap: dataMap,
          animationDuration: Duration(milliseconds: 800),
          // chartLegendSpacing: 32,
          chartRadius: MediaQuery.of(context).size.width / 3.2,
          colorList: colorList,
          initialAngleInDegree: 0,
          chartType: ChartType.ring,
          ringStrokeWidth: 32,
          // centerText: "HYBRID",
          legendOptions: LegendOptions(
            showLegendsInRow: false,
            legendPosition: LegendPosition.right,
            showLegends: true,
            // legendShape: _BoxShape.circle,
            legendTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          chartValuesOptions: ChartValuesOptions(
            showChartValueBackground: false,
            showChartValues: true,
            showChartValuesInPercentage: false,
            showChartValuesOutside: true,
            decimalPlaces: 0,
          ),
        ));
  }
}

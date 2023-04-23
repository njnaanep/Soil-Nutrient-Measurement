import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MainPage extends StatefulWidget {
  @override
  _mainPage createState() => _mainPage();
}

class _mainPage extends State<MainPage> {
  //#region Fields
  String ph_value = "";
  String n_value = "";
  String p_value = "";
  String k_value = "";

  String header = "Current Reading";

  String _selectedCoordinate = coordinates.first;
  bool _toggleState = false;

  late Timer _timer;

  late Timer _commandTimer;

  late var recommendedFertilizers = [];

  late var topRecommended = [];

  late var currentOverallReading = [];
  //#endregion

  @override
  void initState() {
    retrieveCurrentData();
    updateTime();
    _commandTimer = Timer.periodic(Duration(seconds: 1), (timer) {});
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {});
  }

  //#region Functions
  //STATIC IP of RPI
  String link = 'http://0.0.0.0:8080/';

  void updateTime() async {
    DateTime now = DateTime.now();
    await http.post(Uri.parse('$link/update_time'), body: {'new_time': '$now'});
  }

  void startCollection() async {
    await http.post(Uri.parse('$link/start_collecting'),
        body: {'coordinate': _selectedCoordinate, 'mode': 'collecting'});

    setState(() {
      _commandTimer =
          Timer(const Duration(seconds: 10 * 60), toggleSwitchButton);
    });
  }

  void startViewing() async {
    await http.post(Uri.parse('$link/start_collecting'),
        body: {'coordinate': _selectedCoordinate, 'mode': 'view'});

    runTimer();
    setState(() {
      header = 'Current Reading';
      _commandTimer = Timer(const Duration(seconds: 15), stopTimer);
    });
  }

  void stopCollection() async =>
      await http.post(Uri.parse('$link/stop_collecting'), body: {});

  void generateAnalysis() async {
    try {
      final response =
          await http.get(Uri.parse('$link/generate_recommendation'));
      final decodedResponse = jsonDecode(response.body);

      var overallReading = decodedResponse['current'];
      var recommendations = decodedResponse['recommendation'];

      setState(() {
        header = 'Overall Reading';

        ph_value = '${overallReading[0]}';
        n_value = '${overallReading[1]}';
        p_value = '${overallReading[2]}';
        k_value = '${overallReading[3]}';

        recommendedFertilizers = recommendations;
        topRecommended = recommendations[0];
        currentOverallReading = overallReading;
      });

    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return const AlertDialog(
              content: Text("Collect Data from the field first"));
        },
      );
    }
  }

  void retrieveCurrentData() async {
    final response = await http.get(Uri.parse('$link/retrieve_current_data'));

    final decodedResponse = jsonDecode(response.body);

    final parameter = decodedResponse['value'].split(',');

    setState(() {
      ph_value = parameter[0];
      n_value = parameter[1];
      p_value = parameter[2];
      k_value = parameter[3];
    });
  }

  void runTimer() =>
      _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
        retrieveCurrentData();
      });

  void stopTimer() {
    stopCollection();
    _timer.cancel();
    _commandTimer.cancel();
  }

  void toggleSwitchButton() {
    if (!_toggleState) {
      startCollection();
      setState(() {
        _toggleState = true;
        runTimer();
        header = 'Current Reading';
      });
    } else {
      setState(() {
        _toggleState = false;
        stopTimer();
        _timer.cancel();
      });
    }
  }

  //#endregion

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
              margin: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    header,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Container(
                      alignment: Alignment.center,
                      width: 50,
                      child: TextButton.icon(
                        onPressed: () => startViewing(),
                        label: Text(''),
                        icon: const Icon(Icons.remove_red_eye_rounded),
                      )),
                ],
              )),
          Column(
            children: <Widget>[
              _soilParameter('ph Level', ph_value, ''),
              _soilParameter('Nitrogen', n_value, ' mg/Kg'),
              _soilParameter('Phosphorous', p_value, ' mg/Kg'),
              _soilParameter('Potassium', k_value, ' mg/Kg'),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 10),
                    width: 80,
                    child: const Text(
                      'Location: ',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  Container(
                    width: 120,
                    child: DropdownButton(
                      isExpanded: true,
                      value: _selectedCoordinate,
                      items: coordinates
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _selectedCoordinate = value!;
                        });
                      },
                    ),
                  ),
                  Container(
                      alignment: Alignment.centerRight,
                      width: 130,
                      child: TextButton(
                        onPressed: () => toggleSwitchButton(),
                        child: Container(
                          width: 90,
                          color:
                              !_toggleState ? Colors.green : Colors.redAccent,
                          padding: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 10),
                          child: Text(
                            !_toggleState ? 'Collect' : 'Finish',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                      )),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

//#region Widget Classes

class _soilParameter extends StatelessWidget {
  String parameter;
  String value;
  String unit;

  _soilParameter(this.parameter, this.value, this.unit);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              '$parameter :',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              '$value ',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              '$unit',
              style: const TextStyle(fontSize: 24),
            ),
          )
        ],
      ),
    );
  }
}

class _recommendedFertilizer extends StatefulWidget {
  var result;
  bool includePrice;

  _recommendedFertilizer(this.result, this.includePrice);

  @override
  State<_recommendedFertilizer> createState() => _recommendedFertilizerState();
}

class _recommendedFertilizerState extends State<_recommendedFertilizer> {
  @override
  Widget build(BuildContext context) {
    var container = Container();
    if (widget.result.isNotEmpty) {
      container = Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(8),
          height: widget.includePrice ? 160 : 120,
          decoration: BoxDecoration(
              border: Border.all(
            color: Colors.lightGreen,
            width: 3,
          )),
          child: Column(
            children: [
              SizedBox(
                width: 300,
                child: Text(widget.result[0][0],
                    textAlign: TextAlign.left,
                    style: const TextStyle(fontSize: 16)),
              ),
              SizedBox(
                width: 300,
                child: Text(widget.result[0][1],
                    textAlign: TextAlign.left,
                    style: const TextStyle(fontSize: 16)),
              ),
              SizedBox(
                width: 300,
                child: Text(widget.result[0][2],
                    textAlign: TextAlign.left,
                    style: const TextStyle(fontSize: 16)),
              ),
              if (widget.includePrice)
                Container(
                    margin: EdgeInsets.only(top: 16),
                    width: 300,
                    child: Text('Total Cost: ${widget.result[1]}',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 16)))
            ],
          ));
    }

    return container;
  }
}

//#endregion

//#region List variables
List<String> coordinates = <String>[
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J'
];

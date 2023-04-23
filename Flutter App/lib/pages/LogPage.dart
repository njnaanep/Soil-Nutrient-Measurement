import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:intl/intl.dart';

class LogPage extends StatefulWidget {
  @override
  logPage createState() => logPage();
}

class logPage extends State<LogPage> {


  String broker = '0.0.0.0';
  String username = 'user';
  String password = 'password';

  late MqttClient _client;
  late Timer _reconnectTimer;

  List<Widget> _logger = [];

  void addItem(Widget item) {
    setState(() {
      if (_logger.length == 300) {
        _logger.removeLast();
      }
      _logger.insert(0, item);
    });
  }

  @override
  void initState() {
    try{
      _client = MqttServerClient.withPort(broker, 'flutter', 1883);
      connect();
    }catch(e){}
  }

  void connect() async {
    if (_client?.connectionStatus!.state == MqttConnectionState.connected) {
      return;
    }

    _client.logging(on: false);
    _client.keepAlivePeriod = 20;
    _client.onDisconnected = onDisconnected;
    final MqttConnectMessage connMess = MqttConnectMessage()
        .withClientIdentifier('MyClientID')
        .keepAliveFor(20)
        .withWillTopic('willtopic')
        .withWillMessage('My Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce)
        .authenticateAs(username, password)
        .withWillRetain();
    print('EXAMPLES::Mosquitto client connecting....');
    _client.connectionMessage = connMess;

    try {
      await _client.connect();
    } catch (e) {
      print('EXAMPLES::client exception - $e');
      _client.disconnect();
    }

    if (_client.connectionStatus!.state == MqttConnectionState.connected) {
      print('EXAMPLES::Mosquitto client connected');
    } else {
      print(
          'EXAMPLES::ERROR Mosquitto client connection failed - disconnecting, status is ${_client.connectionStatus}');
      _reconnectTimer = Timer(const Duration(seconds: 10), connect);
    }

    _client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      DateTime now = DateTime.now();
      String formattedTime = DateFormat('hh:mm:ss').format(now);

      final MqttMessage message = c[0].payload;
      final topic = c[0].topic;
      if (message is MqttPublishMessage) {
        final MqttPublishMessage recMess = message;
        final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        var _log = ('$formattedTime --> $topic:  $pt');

        print(_log);
        addItem(Text(_log, style: const TextStyle(fontSize: 14)));
      }
    });

    _client!.subscribe('Soil/NPK', MqttQos.atLeastOnce);
    _client!.subscribe('Soil/pH', MqttQos.atLeastOnce);
    _client!.subscribe('esp8266/Command', MqttQos.atLeastOnce);
    _client!.subscribe('esp8266/Status', MqttQos.atLeastOnce);
    _client!.subscribe('topic/test', MqttQos.atLeastOnce);
  }

  void onDisconnected() {
    setState(() {
      _client.disconnect();
    });
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _client?.disconnect();
    super.dispose();
  }

  BoxDecoration _decor() {
    return BoxDecoration(
        border: Border.all(
          color: Colors.transparent,
          width: 1,
        ));
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
        decoration: _decor(),
        child: Column(
          children: [
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: _decor(),
                    child: const Text(
                      'Connection Log',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  TextButton(
                    onPressed: connect,
                    child: const Icon(Icons.refresh),
                  ),

                ],
              )

            ),
            Expanded(
              flex: 13,
              child: Container(
                padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                decoration: _decor(),
                child: ListView.builder(
                  itemCount: _logger.length,
                  itemBuilder: (context, index) {
                    return _logger[index];
                  },
                )


              ),
              ),

          ],
        )

    );
  }
}

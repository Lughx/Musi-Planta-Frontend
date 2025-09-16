import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _bluetooth = FlutterBluetoothSerial.instance;
  bool _bluetoothState = false;
  bool _isConnecting = false;
  BluetoothConnection? _connection;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _deviceConnected;
  double _temperature = 0.0;
  double _moisture = 0.0;
  double _light = 0.0;
  String lastCharacter = "";
  

  void _getDevices() async {
    var res = await _bluetooth.getBondedDevices();
    setState(() => _devices = res);
  }

  void _receiveData() {
    _connection?.input?.listen((event) {
      if (event.isNotEmpty) {
        setState(() {
          String s = String.fromCharCodes(event);
          print("-----------------");
          print(s);
          print(lastCharacter);
          //print(s == lastCharacter);

          try {
              //double d = double.parse(s);
              double received = double.parse(s.replaceAll(" ", ""));
              print(received);
              if (lastCharacter.replaceAll(" ", "") == "h") {
                _moisture = received;
              } else if (lastCharacter.replaceAll(" ", "") == "t") {
                _temperature = received;
              } else if (lastCharacter.replaceAll(" ", "") == "l") {
                _light = received;
              } 
          } catch (e) {
              print(e);
              print('Invalid input string');
          /* int receivedTest = int.parse(s);
          print(receivedTest); */
          
          }
          lastCharacter = s;
        });
      }
    });
  }

  void _sendData(String data) {
    if (_connection?.isConnected ?? false) {
      _connection?.output.add(ascii.encode(data));
    }
  }

  void _requestPermission() async {
    await Permission.location.request();
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
  }

  @override
  void initState() {
    super.initState();

    _requestPermission();

    _bluetooth.state.then((state) {
      setState(() => _bluetoothState = state.isEnabled);
    });

    _bluetooth.onStateChanged().listen((state) {
      switch (state) {
        case BluetoothState.STATE_OFF:
          setState(() => _bluetoothState = false);
          break;
        case BluetoothState.STATE_ON:
          setState(() => _bluetoothState = true);
          break;
        // case BluetoothState.STATE_TURNING_OFF:
        //   break;
        // case BluetoothState.STATE_TURNING_ON:
        //   break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Musi planta',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Color.fromARGB(255, 49, 141, 65),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage("assets/background.jpg"))
        ),
        child: Column(
          children: [
            Container(
              color: Color.fromARGB(255, 236, 201, 199),
              child: Column(
                children: [
                  _controlBT(),
                  _infoDevice()
                ],
              ),
            ),
            
            Expanded(child: _listDevices()),
            _buttons(),
          ],
        ),
      )
    );
  }

  Widget _controlBT() {
    return SwitchListTile(
      value: _bluetoothState,
      onChanged: (bool value) async {
        if (value) {
          await _bluetooth.requestEnable();
        } else {
          await _bluetooth.requestDisable();
        }
      },
      tileColor: Colors.black26,
      title: Text(
        _bluetoothState ? "Bluetooth encendido" : "Bluetooth apagado",
      ),
    );
  }

  Widget _infoDevice() {
    return ListTile(
      tileColor: Colors.black12,
      title: Text("Conectado a: ${_deviceConnected?.name ?? "ninguno"}"),
      trailing: _connection?.isConnected ?? false
          ? TextButton(
              onPressed: () async {
                _sendData("d");
                await _connection?.finish();
                _temperature = 0.0;
                setState(() => _deviceConnected = null);
              },
              child: const Text("Desconectar"),
            )
          : TextButton(
              onPressed: _getDevices,
              child: const Text("Ver dispositivos"),
            ),
    );
  }

  Widget _listDevices() {
    return _isConnecting
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Container(
              color: Colors.grey.shade100,
              child: Column(
                children: [
                  ...[
                    for (final device in _devices)
                      ListTile(
                        title: Text(device.name ?? device.address),
                        trailing: TextButton(
                          child: const Text('conectar'),
                          onPressed: () async {
                            setState(() => _isConnecting = true);

                            _connection = await BluetoothConnection.toAddress(
                                device.address);
                            _deviceConnected = device;
                            _devices = [];
                            _isConnecting = false;

                            _sendData("c");
                            _receiveData();

                            setState(() {});
                          },
                        ),
                      )
                  ]
                ],
              ),
            ),
          );
  }

  Widget _buttons() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 8.0),
      color: Color.fromARGB(255, 79, 161, 68),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  const Text('Humedad', style: TextStyle(fontSize: 18.0, color: Colors.white)),
                  const SizedBox(height: 16.0),
                  Text("$_moisture%", style: TextStyle(fontSize: 25, color: Colors.white)),
                ],
              ),
              Column(
                children: [
                  const Text('Temperatura', style: TextStyle(fontSize: 18.0, color: Colors.white)),
                  const SizedBox(height: 16.0),
                  Text("$_temperature°C",
                      style: TextStyle(fontSize: 25, color: Colors.white)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

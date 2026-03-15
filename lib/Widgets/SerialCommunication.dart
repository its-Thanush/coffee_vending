import 'package:usb_serial/usb_serial.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';

class SerialService {
  static final SerialService _instance = SerialService._internal();
  factory SerialService() => _instance;
  SerialService._internal();

  UsbPort? _port;
  bool isConnected = false;

  final List<Function(bool)> _connectionListeners = [];
  final List<Function(String)> _tempListeners = [];
  final List<Function(String)> _floatListeners = [];

  void addConnectionListener(Function(bool) listener) {
    if (!_connectionListeners.contains(listener)) {
      _connectionListeners.add(listener);
    }
  }

  void removeConnectionListener(Function(bool) listener) {
    _connectionListeners.remove(listener);
  }

  void addTempListener(Function(String) listener) {
    if (!_tempListeners.contains(listener)) {
      _tempListeners.add(listener);
    }
  }

  void removeTempListener(Function(String) listener) {
    _tempListeners.remove(listener);
  }

  void addFloatListener(Function(String) listener) {
    if (!_floatListeners.contains(listener)) {
      _floatListeners.add(listener);
    }
  }

  void removeFloatListener(Function(String) listener) {
    _floatListeners.remove(listener);
  }

  // Deprecated single-callbacks for backward compatibility during transition if any
  Function(bool)? onConnectionChanged;
  Function(String)? onTempReceived;
  Function(String)? onFloatReceived;

  StreamSubscription<Uint8List>? _subscription;
  String _buffer = '';

  Future<bool> connect() async {
    try {
      List<UsbDevice> devices = await UsbSerial.listDevices();

      if (devices.isEmpty) {
        print("No devices found");
        isConnected = false;
        onConnectionChanged?.call(false);
        return false;
      }

      print("Found ${devices.length} device(s)");

      _port = await devices[0].create();

      if (_port == null) {
        print("Failed to create port");
        isConnected = false;
        onConnectionChanged?.call(false);
        return false;
      }

      bool openResult = await _port!.open();

      if (!openResult) {
        print("Failed to open port");
        isConnected = false;
        onConnectionChanged?.call(false);
        return false;
      }

      await _port!.setDTR(true);
      await _port!.setRTS(true);
      await _port!.setPortParameters(
        115200,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      print("Connected successfully!");
      await Future.delayed(Duration(milliseconds: 500));

      _startListening();

      isConnected = true;
      onConnectionChanged?.call(true);
      return true;
    } catch (e) {
      print("Connection error: $e");
      isConnected = false;
      onConnectionChanged?.call(false);
      return false;
    }
  }

  void _startListening() {
    _subscription = _port!.inputStream?.listen((Uint8List data) {
      _buffer += String.fromCharCodes(data);

      int newlineIndex;
      while ((newlineIndex = _buffer.indexOf('\n')) != -1) {
        String line = _buffer.substring(0, newlineIndex).trim();
        _buffer = _buffer.substring(newlineIndex + 1);

        if (line.isNotEmpty) {
          _processReceivedData(line);
        }
      }
    });
  }

  void _processReceivedData(String data) {
    print("-------json Data---->"+data);
    try {
      final jsonData = json.decode(data);
      if (jsonData['TEMP'] != null) {
        print("--------------TEmp---Receiving--------->"+jsonData['TEMP'].toString());
        onTempReceived?.call(jsonData['TEMP']);
        for (var listener in _tempListeners) {
          listener(jsonData['TEMP']);
        }
      }
      if (jsonData['FLOAT'] != null) {
        onFloatReceived?.call(jsonData['FLOAT']);
        for (var listener in _floatListeners) {
          listener(jsonData['FLOAT']);
        }
      }
    } catch (e) {
      print("Error parsing JSON: $e");
    }
  }

  Future<void> sendData(String data) async {
    if (_port == null) {
      print("Port not connected");
      return;
    }

    try {
      String message = data + '\n';
      await _port!.write(Uint8List.fromList(message.codeUnits));
      print("Sent: $message");
    } catch (e) {
      print("Error sending data: $e");
      isConnected = false;
      onConnectionChanged?.call(false);
    }
  }

  Future<void> sendJsonData(Map<String, dynamic> data) async {
    if (_port == null) {
      print("Port not connected");
      return;
    }

    try {
      String jsonString = json.encode(data);
      jsonString += '\n';
      await _port!.write(Uint8List.fromList(jsonString.codeUnits));
      print("Sent: $jsonString");
    } catch (e) {
      print("Error sending data: $e");
      isConnected = false;
      onConnectionChanged?.call(false);
    }
  }

  Future<bool> checkConnection() async {
    try {
      List<UsbDevice> devices = await UsbSerial.listDevices();

      if (devices.isEmpty || _port == null) {
        if (isConnected) {
          isConnected = false;
          onConnectionChanged?.call(false);
        }
        return false;
      }

      if (!isConnected) {
        isConnected = true;
        onConnectionChanged?.call(true);
      }
      return true;
    } catch (e) {
      print("Error checking connection: $e");
      if (isConnected) {
        isConnected = false;
        onConnectionChanged?.call(false);
      }
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _subscription?.cancel();
      await _port?.close();
      _port = null;
      isConnected = false;
      onConnectionChanged?.call(false);
      for (var listener in _connectionListeners) {
        listener(false);
      }
      print("Disconnected");
    } catch (e) {
      print("Error disconnecting: $e");
    }
  }
}
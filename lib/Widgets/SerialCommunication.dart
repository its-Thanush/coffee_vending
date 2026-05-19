import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';

class SerialService {
  static final SerialService _instance = SerialService._internal();
  factory SerialService() => _instance;
  SerialService._internal();

  Socket? _socket;
  bool isConnected = false;

  final String serverIp = '192.168.4.1';
  final int serverPort = 8080;

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

  Function(bool)? onConnectionChanged;
  Function(String)? onTempReceived;
  Function(String)? onFloatReceived;

  StreamSubscription<Uint8List>? _subscription;
  String _buffer = '';

  // Future<bool> connect() async {
  //   try {
  //     _socket = await Socket.connect(
  //       serverIp,
  //       serverPort,
  //       timeout: const Duration(seconds: 5),
  //     );
  //
  //     print("Connected successfully!");
  //
  //     _startListening();
  //
  //     isConnected = true;
  //     onConnectionChanged?.call(true);
  //     return true;
  //   } catch (e) {
  //     print("Connection error: $e");
  //     isConnected = false;
  //     onConnectionChanged?.call(false);
  //     return false;
  //   }
  // }


  Future<bool> connect() async {
    int retry = 0;

    while (retry < 10) {
      try {
        print("Trying to connect... Attempt $retry");

        _socket = await Socket.connect(
          serverIp,
          serverPort,
          timeout: const Duration(seconds: 3),
        );

        print("Connected successfully!");

        _startListening();

        isConnected = true;
        onConnectionChanged?.call(true);
        return true;
      } catch (e) {
        print("Connection failed: $e");

        retry++;
        await Future.delayed(Duration(seconds: 2));
      }
    }

    print("Final: Unable to connect");
    isConnected = false;
    onConnectionChanged?.call(false);
    return false;
  }

  void _startListening() {
    _subscription = _socket!.listen(
      (Uint8List data) {
        _buffer += String.fromCharCodes(data);

        int newlineIndex;
        while ((newlineIndex = _buffer.indexOf('\n')) != -1) {
          String line = _buffer.substring(0, newlineIndex).trim();
          _buffer = _buffer.substring(newlineIndex + 1);

          if (line.isNotEmpty) {
            _processReceivedData(line);
          }
        }
      },
      onError: (error) {
        print("Socket error: $error");
        disconnect();
      },
      onDone: () {
        print("Socket done");
        disconnect();
      },
    );
  }

  void _processReceivedData(String data) {
    print("-------json Data---->" + data);
    try {
      final jsonData = json.decode(data);

      // ✅ NEW: HANDLE RESULT FROM ESP32
      if (jsonData['RESULT'] != null) {
        print("RESULT RECEIVED: ${jsonData['RESULT']}");
      }

      if (jsonData['TEMP'] != null) {
        print(
          "--------------Temp Receiving--------->" +
              jsonData['TEMP'].toString(),
        );
        onTempReceived?.call(jsonData['TEMP']);
        for (var listener in _tempListeners) {
          listener(jsonData['TEMP']);
        }
      }

      if (jsonData['FLOAT'] != null) {
        print(
          "--------------Float Receiving--------->" +
              jsonData['FLOAT'].toString(),
        );
        onFloatReceived?.call(jsonData['FLOAT']);
        for (var listener in _floatListeners) {
          listener(jsonData['FLOAT']);
        }
      }
    } catch (e) {
      print("Error parsing JSON: $e");
    }
  }

  // void _processReceivedData(String data) {
  //   print("-------json Data---->" + data);
  //   try {
  //     final jsonData = json.decode(data);
  //     if (jsonData['TEMP'] != null) {
  //       print(
  //         "--------------TEmp---Receiving--------->" +
  //             jsonData['TEMP'].toString(),
  //       );
  //       onTempReceived?.call(jsonData['TEMP']);
  //       for (var listener in _tempListeners) {
  //         listener(jsonData['TEMP']);
  //       }
  //     }
  //     if (jsonData['FLOAT'] != null) {
  //       onFloatReceived?.call(jsonData['FLOAT']);
  //       for (var listener in _floatListeners) {
  //         listener(jsonData['FLOAT']);
  //       }
  //     }
  //   } catch (e) {
  //     print("Error parsing JSON: $e");
  //   }
  // }

  Future<void> sendData(String data) async {
    if (_socket == null) {
      print("Port not connected");
      return;
    }

    try {
      String message = data + '\n';
      _socket!.write(message);
      print("Sent: $message");
    } catch (e) {
      print("Error sending data: $e");
      isConnected = false;
      onConnectionChanged?.call(false);
    }
  }

  Future<void> sendJsonData(Map<String, dynamic> data) async {
    if (_socket == null) {
      print("Port not connected");
      return;
    }

    try {
      String jsonString = json.encode(data);
      jsonString += '\n';
      _socket!.write(jsonString);
      print("Sent: $jsonString");
    } catch (e) {
      print("Error sending data: $e");
      isConnected = false;
      onConnectionChanged?.call(false);
    }
  }

  Future<bool> checkConnection() async {
    try {
      if (_socket == null) {
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
      _socket?.destroy();
      _socket = null;
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

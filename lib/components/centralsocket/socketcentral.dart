/*import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  late io.Socket socket;

  void connectToServer(String apiUrl) {
    socket = io.io(apiUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnect': true,
      'reconnectionAttempts': 10,
      'reconnectionDelay': 500,
      'reconnectionDelayMax': 2000,
    });

    socket.connect();

    socket.onConnect((_) {
      // Conexión establecida
    });

    socket.onDisconnect((_) {
      // Conexión desconectada
    });

    socket.onConnectError((error) {
      // Manejar error de conexión
    });

    socket.onError((error) {
      // Manejar otros errores
    });
  }

  void listenToEvent(String eventName, Function(dynamic) callback) {
    socket.on(eventName, callback);
  }

  void emitEvent(String eventName, dynamic data) {
    socket.emit(eventName, data);
  }

  void dispose() {
    socket.dispose();
  }
}
*/
/////////////////////////
/*
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  static final SocketService _singleton = SocketService._internal();
  late io.Socket socket;

  factory SocketService() {
    return _singleton;
  }

  SocketService._internal();

  void connectToServer(String apiUrl) {
    socket = io.io(apiUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnect': true,
      'reconnectionAttempts': 10,
      'reconnectionDelay': 500,
      'reconnectionDelayMax': 2000,
    });

    socket.connect();

    socket.onConnect((_) {
      print('Conectado al servidor');
    });

    socket.onDisconnect((_) {
      print('Desconectado del servidor');
    });

    socket.onConnectError((error) {
      print('Error de conexión: $error');
    });

    socket.onError((error) {
      print('Error: $error');
    });
  }

  void listenToEvent(String eventName, Function(dynamic) callback) {
    socket.on(eventName, callback);
  }

  void emitEvent(String eventName, dynamic data) {
    socket.emit(eventName, data);
  }

  void dispose() {
    socket.dispose();
  }
}
*/
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  late io.Socket socket;
  final Set<String> _registeredEvents = {};

  factory SocketService() {
    return _instance;
  }

  SocketService._internal() {
    // Initialization logic
    connectToServer();
  }

  void connectToServer() {
    final apiUrl = "http://147.182.251.164"; // Pon aquí tu URL de API

    socket = io.io(apiUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnect': true,
      'reconnectionAttempts': 10,
      'reconnectionDelay': 500,
      'reconnectionDelayMax': 2000,
    });

    socket.connect();

    socket.onConnect((_) {
      print('Conexión establecida');
    });

    socket.onDisconnect((_) {
      print('Conexión desconectada');
    });

    socket.onConnectError((error) {
      print('Error de conexión: $error');
    });

    socket.onError((error) {
      print('Otro error: $error');
    });
  }

  void listenToEvent(String eventName, Function(dynamic) callback) {
    if (_registeredEvents.contains(eventName)) {
      // Si el evento ya está registrado, no lo registres de nuevo
      return;
    }

    socket.on(eventName, callback);
    _registeredEvents.add(eventName); // Marca el evento como registrado
  }

  void emitEvent(String eventName, dynamic data) {
    socket.emit(eventName, data);
  }

  void dispose() {
    socket.dispose();
  }
}

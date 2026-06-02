import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taxímetro Papá',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const TaximetroHome(),
    );
  }
}

class TaximetroHome extends StatefulWidget {
  const TaximetroHome({super.key});

  @override
  State<TaximetroHome> createState() => _TaximetroHomeState();
}

class _TaximetroHomeState extends State<TaximetroHome> {
  bool _enViaje = false;
  double _distanciaKm = 0.0;
  double _montoDinero = 0.0;
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _lastPosition;

  // Configuración de tarifas (Para cambiar los precios)
  final double _tarifaBase = 3.0; // Lo mínimo que cobras por arrancar
  final double _precioPorKm = 2.4;  // Cuánto cobras por cada kilómetro recorrido

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
  }

  void _iniciarViaje() {
    setState(() {
      _enViaje = true;
      _distanciaKm = 0.0;
      _montoDinero = _tarifaBase;
      _lastPosition = null;
    });

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Se actualiza cada 5 metros
      ),
    ).listen((Position position) {
      if (_lastPosition != null) {
        double distanceInMeters = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        setState(() {
          _distanciaKm += distanceInMeters / 1000;
          _montoDinero = _tarifaBase + (_distanciaKm * _precioPorKm);
        });
      }
      _lastPosition = position;
    });
  }

  Future<void> _terminarViaje() async {
    if (_positionStreamSubscription != null) {
      await _positionStreamSubscription!.cancel();
    }

    // --- GUARDAR AUTOMÁTICAMENTE EN EL HISTORIAL ---
    final prefs = await SharedPreferences.getInstance();
    List<String> historial = prefs.getStringList('viajes_taximetro') ?? [];
    
    // Formateamos la fecha actual y los datos del viaje
    DateTime ahora = DateTime.now();
    String fechaFormateada = "${ahora.day}/${ahora.month}/${ahora.year} ${ahora.hour}:${ahora.minute.toString().padLeft(2, '0')}";
    String datosViaje = "$fechaFormateada|${_distanciaKm.toStringAsFixed(2)}|${_montoDinero.toStringAsFixed(2)}";
    
    // Lo metemos de primero en la lista para que salga arriba el más reciente
    historial.insert(0, datosViaje);
    await prefs.setStringList('viajes_taximetro', historial);

    // Mostramos un aviso de guardado
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡Viaje guardado en el historial!')),
    );

    setState(() {
      _enViaje = false;
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Taxímetro Papá', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.amber,
        // BOTÓN ARRIBA A LA IZQUIERDA PARA EL HISTORIAL
        leading: IconButton(
          icon: const Icon(Icons.history, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistorialScreen()),
            );
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Cuadro de Distancia
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.amber, width: 2),
                ),
                child: Column(
                  children: [
                    const Text('DISTANCIA RECORRIDA', style: TextStyle(color: Colors.amber, fontSize: 14)),
                    const SizedBox(height: 10),
                    Text('${_distanciaKm.toStringAsFixed(2)} km', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Cuadro de Dinero
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Column(
                  children: [
                    const Text('TOTAL A PAGAR', style: TextStyle(color: Colors.green, fontSize: 14)),
                    const SizedBox(height: 10),
                    Text('\$${_montoDinero.toStringAsFixed(2)}', style: const TextStyle(fontSize: 54, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              // Botón de Acción Principal
              SizedBox(
                width: double.infinity,
                height: 70,
                child: ElevatedButton(
                  onPressed: _enViaje ? _terminarViaje : _iniciarViaje,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _enViaje ? Colors.red : Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
                  ),
                  child: Text(
                    _enViaje ? 'TERMINAR VIAJE' : 'INICIAR VIAJE',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- NUEVA PANTALLA DEL HISTORIAL ---
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  List<String> _viajes = [];

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _viajes = prefs.getStringList('viajes_taximetro') ?? [];
    });
  }

  Future<void> _borrarHistorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('viajes_taximetro');
    setState(() {
      _viajes = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Viajes', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.amber,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (_viajes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('¿Borrar todo?'),
                    content: const Text('Se eliminarán todos los viajes registrados.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                      TextButton(
                        onPressed: () {
                          _borrarHistorial();
                          Navigator.pop(context);
                        },
                        child: const Text('Borrar', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            )
        ],
      ),
      body: _viajes.isEmpty
          ? const Center(child: Text('No hay viajes registrados aún.', style: TextStyle(color: Colors.grey, fontSize: 18)))
          : ListView.builder(
              itemCount: _viajes.length,
              itemBuilder: (context, index) {
                // Dividimos el String guardado por el separador '|'
                List<String> partes = _viajes[index].split('|');
                String fecha = partes[0];
                String km = partes[1];
                String dinero = partes[2];

                return Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: const Icon(Icons.local_taxi, color: Colors.amber, size: 30),
                    title: Text('Viaje #\${_viajes.length - index}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                    subtitle: Text(fecha, style: const TextStyle(color: Colors.grey)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('\$$dinero', style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('$km km', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

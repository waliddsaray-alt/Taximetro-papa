import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() => runApp(const TaximetroApp());

class TaximetroApp extends StatelessWidget {
  const TaximetroApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const TaximetroScreen(),
    );
  }
}

class TaximetroScreen extends StatefulWidget {
  const TaximetroScreen({Key? key}) : super(key: key);

  @override
  _TaximetroScreenState createState() => _TaximetroScreenState();
}

class _TaximetroScreenState extends State<TaximetroScreen> {
  final double tarifaBase = 1.50;
  final double tarifaPorKm = 2.50;

  double totalPagar = 0.0;
  double distanciaKm = 0.0;
  bool viajeActivo = false;
  
  Position? ultimaCoordenada;

  void iniciarSeguimientoGPS() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (!viajeActivo) return;

      setState(() {
        if (ultimaCoordenada != null) {
          double metros = Geolocator.distanceBetween(
            ultimaCoordenada!.latitude, ultimaCoordenada!.longitude,
            position.latitude, position.longitude
          );
          
          distanciaKm += metros / 1000;
          totalPagar = tarifaBase + (distanciaKm * tarifaPorKm);
        }
        ultimaCoordenada = position;
      });
    });
  }

  void iniciarViaje() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

    setState(() {
      viajeActivo = true;
      totalPagar = tarifaBase;
      distanciaKm = 0.0;
      ultimaCoordenada = null;
    });
    iniciarSeguimientoGPS();
  }

  void terminarViaje() {
    setState(() {
      viajeActivo = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'TAXÍMETRO GPS',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 2),
            ),
            const SizedBox(height: 40),
            Text(
              '\$${totalPagar.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 20),
            Text(
              'Distancia: ${distanciaKm.toStringAsFixed(3)} km',
              style: const TextStyle(fontSize: 18, color: Colors.white54),
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              onPressed: viajeActivo ? null : iniciarViaje,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              ),
              child: const Text('INICIAR VIAJE', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: viajeActivo ? terminarViaje : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                padding: const EdgeInsets.symmetric(horizontal: 43, vertical: 20),
              ),
              child: const Text('TERMINAR VIAJE', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
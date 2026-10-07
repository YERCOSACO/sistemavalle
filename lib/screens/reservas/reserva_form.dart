import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/viaje.dart';
import '../../providers/reserva_provider.dart';
import '../../providers/auth_provider.dart';

class ReservaForm extends StatefulWidget {
  final Viaje viaje;
  final List<String> selectedSeats;

  const ReservaForm({super.key, required this.viaje, required this.selectedSeats});

  @override
  State<ReservaForm> createState() => _ReservaFormState();
}

class _ReservaFormState extends State<ReservaForm> {
  final List<TextEditingController> _nameControllers = [];
  final List<TextEditingController> _ciControllers = [];
  final List<TextEditingController> _phoneControllers = [];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.selectedSeats.length; i++) {
      _nameControllers.add(TextEditingController());
      _ciControllers.add(TextEditingController());
      _phoneControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (var c in _nameControllers) c.dispose();
    for (var c in _ciControllers) c.dispose();
    for (var c in _phoneControllers) c.dispose();
    super.dispose();
  }

  Future<void> _submitReserva() async {
    final auth = context.read<AuthProvider>();
    final reservaProvider = context.read<ReservaProvider>();

    List<Map<String, dynamic>> boletos = [];
    double total = 0;

    for (var i = 0; i < widget.selectedSeats.length; i++) {
      if (_nameControllers[i].text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ingrese nombre para el asiento ${widget.selectedSeats[i]}')));
        return;
      }
      
      final precio = widget.viaje.ruta?.precioBase ?? 0.0;
      total += precio;
      
      boletos.add({
        'viaje_id': widget.viaje.id,
        'numero_asiento': widget.selectedSeats[i],
        'nombre_pasajero': _nameControllers[i].text,
        'ci_pasajero': _ciControllers[i].text,
        'telefono_pasajero': _phoneControllers[i].text,
        'precio': precio,
      });
    }

    final success = await reservaProvider.crearReserva({
      'cliente_id': auth.user?['id'],
      'viaje_id': widget.viaje.id,
      'cantidad': widget.selectedSeats.length,
      'total_pagar': total,
      'boletos': boletos,
    });

    if (success && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reserva realizada con éxito')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Completar Reserva')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...List.generate(widget.selectedSeats.length, (index) => Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Asiento ${widget.selectedSeats[index]}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextField(controller: _nameControllers[index], decoration: const InputDecoration(labelText: 'Nombre Pasajero')),
                  TextField(controller: _ciControllers[index], decoration: const InputDecoration(labelText: 'CI')),
                  TextField(controller: _phoneControllers[index], decoration: const InputDecoration(labelText: 'Teléfono')),
                ],
              ),
            ),
          )),
          const SizedBox(height: 20),
          FilledButton(onPressed: _submitReserva, child: const Text('Confirmar Reserva')),
        ],
      ),
    );
  }
}

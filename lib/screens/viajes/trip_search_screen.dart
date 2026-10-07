import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/viaje_provider.dart';
import '../../models/viaje.dart';
import 'trip_detail_screen.dart';

class TripSearchScreen extends StatefulWidget {
  const TripSearchScreen({super.key});

  @override
  State<TripSearchScreen> createState() => _TripSearchScreenState();
}

class _TripSearchScreenState extends State<TripSearchScreen> {
  final _origenController = TextEditingController();
  final _destinoController = TextEditingController();
  DateTime? _selectedDate;

  void _search() {
    final viajeProvider = Provider.of<ViajeProvider>(context, listen: false);
    viajeProvider.searchViajes(
      origen: _origenController.text.isEmpty ? null : _origenController.text,
      destino: _destinoController.text.isEmpty ? null : _destinoController.text,
      fecha: _selectedDate?.toIso8601String().split('T')[0],
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Viajes'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _origenController,
                      decoration: const InputDecoration(
                        labelText: 'Origen',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _destinoController,
                      decoration: const InputDecoration(
                        labelText: 'Destino',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      title: Text(_selectedDate == null 
                        ? 'Seleccionar Fecha' 
                        : 'Fecha: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _selectDate,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _search,
                        child: const Text('Buscar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Consumer<ViajeProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.errorMessage != null) {
                  return Center(child: Text(provider.errorMessage!));
                }
                if (provider.viajes.isEmpty) {
                  return const Center(child: Text('No se encontraron viajes.'));
                }
                return ListView.builder(
                  itemCount: provider.viajes.length,
                  itemBuilder: (context, index) {
                    final viaje = provider.viajes[index];
                    return _TripCard(viaje: viaje);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Viaje viaje;
  const _TripCard({required this.viaje});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text('${viaje.ruta?.origen ?? 'N/A'} -> ${viaje.ruta?.destino ?? 'N/A'}'),
        subtitle: Text('Fecha: ${viaje.fechaViaje.day}/${viaje.fechaViaje.month} - Hora: ${viaje.horaSalida}\nBus: ${viaje.bus?.placa ?? 'N/A'} (${viaje.bus?.tipoBus ?? ''})'),
        trailing: Text(
          'Bs. ${viaje.ruta?.precioBase ?? 0}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TripDetailScreen(viaje: viaje)),
          );
        },
      ),
    );
  }
}

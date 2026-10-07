import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/viaje.dart';
import '../../providers/viaje_provider.dart';
import '../reservas/reserva_form.dart';

class TripDetailScreen extends StatefulWidget {
  final Viaje viaje;
  const TripDetailScreen({super.key, required this.viaje});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  List<Map<String, dynamic>> _asientos = [];
  Set<String> _selectedSeats = {};
  bool _loadingAsientos = true;

  @override
  void initState() {
    super.initState();
    _loadAsientos();
  }

  Future<void> _loadAsientos() async {
    final provider = Provider.of<ViajeProvider>(context, listen: false);
    final data = await provider.fetchAsientos(widget.viaje.id!);
    setState(() {
      _asientos = data;
      _loadingAsientos = false;
    });
  }

  void _toggleSeat(String numero) {
    setState(() {
      if (_selectedSeats.contains(numero)) {
        _selectedSeats.remove(numero);
      } else {
        _selectedSeats.add(numero);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Viaje'),
      ),
      bottomNavigationBar: _selectedSeats.isEmpty
          ? null
          : BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Seleccionados: ${_selectedSeats.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    FilledButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReservaForm(
                              viaje: widget.viaje,
                              selectedSeats: _selectedSeats.toList(),
                            ),
                          ),
                        );
                      },
                      child: const Text('Continuar'),
                    ),
                  ],
                ),
              ),
            ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTripInfo(),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Seleccione sus asientos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            if (_loadingAsientos)
              const Center(child: CircularProgressIndicator())
            else
              _buildSeatGrid(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTripInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      color: Colors.blue.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.viaje.ruta?.origen} a ${widget.viaje.ruta?.destino}', 
               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Fecha: ${widget.viaje.fechaViaje.day}/${widget.viaje.fechaViaje.month}/${widget.viaje.fechaViaje.year}'),
          Text('Hora de Salida: ${widget.viaje.horaSalida}'),
          Text('Tipo de Bus: ${widget.viaje.bus?.tipoBus ?? 'Estándar'}'),
          Text('Precio por asiento: Bs. ${widget.viaje.ruta?.precioBase}'),
        ],
      ),
    );
  }

  Widget _buildSeatGrid() {
    // Agrupar asientos por fila (1A, 1B, 1C, 1D -> Fila 1)
    // Para simplificar, los mostraremos en un grid de 4 columnas
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _asientos.length,
      itemBuilder: (context, index) {
        final asiento = _asientos[index];
        final numero = asiento['numero_asiento'].toString();
        final estado = asiento['estado'].toString();
        final isAvailable = estado == 'disponible';
        final isSelected = _selectedSeats.contains(numero);

        return GestureDetector(
          onTap: isAvailable ? () => _toggleSeat(numero) : null,
          child: Container(
            decoration: BoxDecoration(
              color: !isAvailable 
                  ? Colors.grey.shade300 
                  : (isSelected ? Colors.blue : Colors.white),
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_seat,
                    color: !isAvailable ? Colors.grey : (isSelected ? Colors.white : Colors.blue),
                  ),
                  Text(
                    numero,
                    style: TextStyle(
                      fontSize: 12,
                      color: !isAvailable ? Colors.grey : (isSelected ? Colors.white : Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

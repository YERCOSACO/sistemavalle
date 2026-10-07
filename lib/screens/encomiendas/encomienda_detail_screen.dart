import 'package:flutter/material.dart';
import '../../models/encomienda.dart';

class EncomiendaDetailScreen extends StatelessWidget {
  final Encomienda encomienda;
  const EncomiendaDetailScreen({super.key, required this.encomienda});

  Color get _estadoColor {
    switch (encomienda.estado) {
      case 'entregado':
        return Colors.green;
      case 'en transito':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Encomienda')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: _estadoColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory_2, color: _estadoColor, size: 28),
                    const SizedBox(width: 10),
                    Text(encomienda.estado.toUpperCase(),
                        style: TextStyle(color: _estadoColor, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Total a pagar: Bs. ${encomienda.totalPagar}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Destinatario'),
          _infoTile(Icons.person_outline, 'Nombre', encomienda.destinatarioNombre),
          if (encomienda.destinatarioCi != null) _infoTile(Icons.badge_outlined, 'CI', encomienda.destinatarioCi!),
          if (encomienda.destinatarioTelefono != null) _infoTile(Icons.phone_outlined, 'Teléfono', encomienda.destinatarioTelefono!),

          const SizedBox(height: 16),
          _sectionTitle('Remitente'),
          if (encomienda.remitenteNombre != null) _infoTile(Icons.person_outline, 'Nombre', encomienda.remitenteNombre!),
          if (encomienda.remitenteCi != null) _infoTile(Icons.badge_outlined, 'CI', encomienda.remitenteCi!),
          if (encomienda.remitenteTelefono != null) _infoTile(Icons.phone_outlined, 'Teléfono', encomienda.remitenteTelefono!),

          const SizedBox(height: 16),
          _sectionTitle('Envío'),
          _infoTile(Icons.category_outlined, 'Tipo de encomienda', encomienda.tipoEncomienda?.nombre ?? 'ID ${encomienda.tipoEncomiendaId}'),
          _infoTile(Icons.numbers, 'Cantidad', encomienda.cantidad.toString()),
          if (encomienda.viaje != null)
            _infoTile(Icons.directions_bus_outlined, 'Viaje',
                '${encomienda.viaje!.ruta?.origen ?? ''} - ${encomienda.viaje!.ruta?.destino ?? ''}'),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue.shade700, letterSpacing: 1)),
      );

  Widget _infoTile(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueGrey),
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      ),
    );
  }
}

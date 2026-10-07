import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/reserva_provider.dart';

class MisReservasScreen extends StatefulWidget {
  const MisReservasScreen({super.key});

  @override
  State<MisReservasScreen> createState() => _MisReservasScreenState();
}

class _MisReservasScreenState extends State<MisReservasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservaProvider>().fetchMisReservas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Pasajes')),
      body: Consumer<ReservaProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          if (provider.reservas.isEmpty) {
            return const Center(child: Text('No tienes pasajes registrados.'));
          }
          
          return RefreshIndicator(
            onRefresh: () => provider.fetchMisReservas(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.reservas.length,
              itemBuilder: (context, index) {
                final reserva = provider.reservas[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 3,
                  child: ExpansionTile(
                    title: Text(
                      'Reserva #${reserva.id} - ${reserva.estado.toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Fecha: ${reserva.fechaReserva.toLocal().toString().split(' ')[0]}'),
                    trailing: Text(
                      'Bs. ${reserva.totalPagar}',
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    children: [
                      if (reserva.boletos != null)
                        ...reserva.boletos!.map((b) => ListTile(
                          leading: const Icon(Icons.airplane_ticket_outlined, color: Colors.blue),
                          title: Text('Pasajero: ${b.nombrePasajero}'),
                          subtitle: Text('Asiento: ${b.numeroAsiento} | Estado: ${b.estado}'),
                          trailing: b.estado == 'pendiente' 
                            ? const Icon(Icons.qr_code_2, color: Colors.grey)
                            : const Icon(Icons.check_circle, color: Colors.green),
                        )),
                      const SizedBox(height: 10),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

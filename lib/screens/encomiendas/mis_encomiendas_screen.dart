import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/encomienda_provider.dart';
import 'encomienda_form.dart';
import 'encomienda_detail_screen.dart';

class MisEncomiendasScreen extends StatefulWidget {
  const MisEncomiendasScreen({super.key});

  @override
  State<MisEncomiendasScreen> createState() => _MisEncomiendasScreenState();
}

class _MisEncomiendasScreenState extends State<MisEncomiendasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EncomiendaProvider>(context, listen: false).fetchMisEncomiendas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Encomiendas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EncomiendaForm()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Consumer<EncomiendaProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.encomiendas.isEmpty) {
            return const Center(child: Text('No has enviado paquetes aún.'));
          }
          return RefreshIndicator(
            onRefresh: () => provider.fetchMisEncomiendas(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.encomiendas.length,
              itemBuilder: (context, index) {
                final enc = provider.encomiendas[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.inventory_2, color: Colors.orange),
                    title: Text('Para: ${enc.destinatarioNombre}'),
                    subtitle: Text('Estado: ${enc.estado} - Total: Bs. ${enc.totalPagar}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EncomiendaDetailScreen(encomienda: enc)),
                      );
                    },
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

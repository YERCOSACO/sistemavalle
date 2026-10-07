import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/encomienda_provider.dart';

class EncomiendasAdminScreen extends StatefulWidget {
  const EncomiendasAdminScreen({super.key});

  @override
  State<EncomiendasAdminScreen> createState() => _EncomiendasAdminScreenState();
}

class _EncomiendasAdminScreenState extends State<EncomiendasAdminScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EncomiendaProvider>().fetchTodas();
    });
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Encomiendas')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por destinatario o estado...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.close), onPressed: () => _searchController.clear())
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    return Consumer<EncomiendaProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());

        final encomiendas = provider.encomiendas.where((e) {
          if (_query.isEmpty) return true;
          return e.destinatarioNombre.toLowerCase().contains(_query) || e.estado.toLowerCase().contains(_query);
        }).toList();

        if (encomiendas.isEmpty) {
          return Center(child: Text(_query.isEmpty ? 'No hay encomiendas registradas.' : 'Sin resultados para "$_query".'));
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchTodas(),
          child: ListView.builder(
            itemCount: encomiendas.length,
            itemBuilder: (context, index) {
              final e = encomiendas[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.inventory_2, color: Colors.blue),
                  title: Text('Para: ${e.destinatarioNombre}'),
                  subtitle: Text('Estado actual: ${e.estado}\nTotal: Bs. ${e.totalPagar}'),
                  trailing: DropdownButton<String>(
                    value: e.estado,
                    items: ['recibido', 'en transito', 'entregado']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) async {
                      if (val != null) {
                        final success = await provider.updateEstado(e.id!, val);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Estado de encomienda actualizado'))
                          );
                        }
                      }
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

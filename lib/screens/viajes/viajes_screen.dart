import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/viaje_provider.dart';
import 'viaje_form.dart';
import 'asignacion_conductor_form.dart';
import 'trip_detail_screen.dart';
import '../incidencias/incidencia_viaje_form.dart';

class ViajesScreen extends StatefulWidget {
  const ViajesScreen({super.key});
  @override
  State<ViajesScreen> createState() => _ViajesScreenState();
}

class _ViajesScreenState extends State<ViajesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ViajeProvider>().searchViajes();
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
    final p = context.watch<ViajeProvider>();
    final viajes = p.viajes.where((v) {
      if (_query.isEmpty) return true;
      final origen = v.ruta?.origen.toLowerCase() ?? '';
      final destino = v.ruta?.destino.toLowerCase() ?? '';
      return origen.contains(_query) || destino.contains(_query) || v.horaSalida.toLowerCase().contains(_query) || v.estado.toLowerCase().contains(_query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Viajes')),
      floatingActionButton: FloatingActionButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ViajeForm())), child: const Icon(Icons.add)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por origen, destino, hora o estado...',
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
          Expanded(
            child: p.isLoading
                ? const Center(child: CircularProgressIndicator())
                : viajes.isEmpty
                    ? Center(child: Text(_query.isEmpty ? 'No hay viajes registrados.' : 'Sin resultados para "$_query".'))
                    : ListView.builder(
                        itemCount: viajes.length,
                        itemBuilder: (context, i) => ListTile(
                          title: Text('${viajes[i].ruta?.origen ?? ''} → ${viajes[i].ruta?.destino ?? 'Viaje'} - ${viajes[i].horaSalida}'),
                          subtitle: Text('Estado: ${viajes[i].estado}'),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TripDetailScreen(viaje: viajes[i]))),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.visibility_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TripDetailScreen(viaje: viajes[i])))),
                              IconButton(icon: const Icon(Icons.person_add), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AsignacionConductorForm(viaje: viajes[i])))),
                              IconButton(icon: const Icon(Icons.edit), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ViajeForm(viaje: viajes[i])))),
                              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _confirmDelete(context, viajes[i].id!)),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Viaje'),
        content: const Text('¿Está seguro de que desea eliminar este viaje?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              context.read<ViajeProvider>().deleteViaje(id);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

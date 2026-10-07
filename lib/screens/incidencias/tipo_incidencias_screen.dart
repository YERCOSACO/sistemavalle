import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tipo_incidencia_provider.dart';
import 'tipo_incidencia_form.dart';

class TipoIncidenciasScreen extends StatefulWidget {
  const TipoIncidenciasScreen({super.key});

  @override
  State<TipoIncidenciasScreen> createState() => _TipoIncidenciasScreenState();
}

class _TipoIncidenciasScreenState extends State<TipoIncidenciasScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TipoIncidenciaProvider>().fetchTipos();
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
      appBar: AppBar(title: const Text('Tipos de Incidencias')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TipoIncidenciaForm()),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar tipo de incidencia...',
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
    return Consumer<TipoIncidenciaProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());

        final tipos = provider.tipos.where((t) {
          if (_query.isEmpty) return true;
          return t.nombre.toLowerCase().contains(_query) || t.nivelGravedad.toLowerCase().contains(_query);
        }).toList();

        if (tipos.isEmpty) {
          return Center(child: Text(_query.isEmpty ? 'No hay tipos registrados.' : 'Sin resultados para "$_query".'));
        }

        return ListView.builder(
          itemCount: tipos.length,
          itemBuilder: (context, index) {
            final t = tipos[index];
            return ListTile(
              leading: const Icon(Icons.warning_amber),
              title: Text(t.nombre),
              subtitle: Text('Gravedad: ${t.nivelGravedad} - ${t.descripcion ?? ''}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TipoIncidenciaForm(tipo: t)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Eliminar Tipo de Incidencia'),
                        content: Text('¿Eliminar "${t.nombre}"?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                          TextButton(
                            onPressed: () {
                              context.read<TipoIncidenciaProvider>().deleteTipo(t.id!);
                              Navigator.pop(ctx);
                            },
                            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

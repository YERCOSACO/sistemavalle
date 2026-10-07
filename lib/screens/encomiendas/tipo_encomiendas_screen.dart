import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tipo_encomienda_provider.dart';
import 'tipo_encomienda_form.dart';

class TipoEncomiendasScreen extends StatefulWidget {
  const TipoEncomiendasScreen({super.key});
  @override
  State<TipoEncomiendasScreen> createState() => _TipoEncomiendasScreenState();
}

class _TipoEncomiendasScreenState extends State<TipoEncomiendasScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TipoEncomiendaProvider>().fetchTipos();
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
    final p = context.watch<TipoEncomiendaProvider>();
    final tipos = p.tipos.where((t) {
      if (_query.isEmpty) return true;
      return t.nombre.toLowerCase().contains(_query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Tipos Encomienda')),
      floatingActionButton: FloatingActionButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TipoEncomiendaForm())), child: const Icon(Icons.add)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar tipo de encomienda...',
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
                : tipos.isEmpty
                    ? Center(child: Text(_query.isEmpty ? 'No hay tipos registrados.' : 'Sin resultados para "$_query".'))
                    : ListView.builder(
                        itemCount: tipos.length,
                        itemBuilder: (context, i) => ListTile(
                          title: Text(tipos[i].nombre),
                          subtitle: Text('Precio: Bs. ${tipos[i].precio}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.edit), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TipoEncomiendaForm(tipo: tipos[i])))),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Eliminar Tipo'),
                                    content: Text('¿Eliminar "${tipos[i].nombre}"?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                                      TextButton(
                                        onPressed: () {
                                          context.read<TipoEncomiendaProvider>().deleteTipo(tipos[i].id!);
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
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

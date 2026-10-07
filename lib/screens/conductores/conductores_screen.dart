import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/conductor_provider.dart';
import 'conductor_form.dart';

class ConductoresScreen extends StatefulWidget {
  const ConductoresScreen({super.key});

  @override
  State<ConductoresScreen> createState() => _ConductoresScreenState();
}

class _ConductoresScreenState extends State<ConductoresScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ConductorProvider>().fetchConductores());
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Gestión de Conductores')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConductorForm())),
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar conductor...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _query.isNotEmpty
              ? IconButton(icon: const Icon(Icons.close), onPressed: () => _searchController.clear())
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildList() {
    return Consumer<ConductorProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());

        final conductores = provider.conductores.where((c) {
          if (_query.isEmpty) return true;
          return c.nombreCompleto.toLowerCase().contains(_query) || c.licencia.toLowerCase().contains(_query);
        }).toList();

        if (conductores.isEmpty) {
          return Center(child: Text(_query.isEmpty ? 'No hay conductores registrados.' : 'Sin resultados para "$_query".'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: conductores.length,
          itemBuilder: (context, index) {
            final c = conductores[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(c.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Licencia: ${c.licencia}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ConductorForm(conductor: c)))),
                    IconButton(icon: const Icon(Icons.block, color: Colors.red), onPressed: () => _confirmDeactivate(context, c.id!, c.nombreCompleto)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeactivate(BuildContext context, int id, String nombre) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dar de baja al Conductor'),
        content: Text('¿Está seguro de que desea dar de baja a "$nombre"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              context.read<ConductorProvider>().deactivateConductor(id);
              Navigator.pop(ctx);
            },
            child: const Text('Dar de baja', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

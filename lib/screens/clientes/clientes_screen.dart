import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cliente_provider.dart';
import 'cliente_form.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClienteProvider>().fetchClientes();
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Clientes', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Administra la información de contacto de cada cliente.', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildTopActions(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildTopActions() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, cédula o email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.close), onPressed: () => _searchController.clear())
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 15),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClienteForm())),
            icon: const Icon(Icons.add),
            label: const Text('Agregar cliente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade900,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return Consumer<ClienteProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());

        final clientes = provider.clientes.where((c) {
          if (_query.isEmpty) return true;
          return c.nombre.toLowerCase().contains(_query) ||
              c.apellido.toLowerCase().contains(_query) ||
              c.ci.toLowerCase().contains(_query) ||
              (c.email ?? '').toLowerCase().contains(_query);
        }).toList();

        if (clientes.isEmpty) {
          return Center(child: Text(_query.isEmpty ? 'No se encontraron registros.' : 'Sin resultados para "$_query".'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: clientes.length,
          itemBuilder: (context, index) {
            final c = clientes[index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text('${c.nombre} ${c.apellido}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('CI: ${c.ci}  |  ${c.email ?? ''}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClienteForm(cliente: c))),
                      style: TextButton.styleFrom(backgroundColor: Colors.orange.shade50, foregroundColor: Colors.orange.shade800),
                      child: const Text('Modificar'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _confirmDelete(c.id!),
                      style: TextButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red.shade800),
                      child: const Text('Eliminar'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cliente'),
        content: const Text('¿Está seguro de que desea eliminar este registro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(onPressed: () {
            context.read<ClienteProvider>().deleteCliente(id);
            Navigator.pop(context);
          }, child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

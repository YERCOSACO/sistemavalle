import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/boleto_provider.dart';
import '../../models/boleto.dart';

class BoletosScreen extends StatefulWidget {
  const BoletosScreen({super.key});

  @override
  State<BoletosScreen> createState() => _BoletosScreenState();
}

class _BoletosScreenState extends State<BoletosScreen> {
  String _filtro = 'todos';
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BoletoProvider>().fetchBoletos();
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

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'pagado':
      case 'confirmado':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'cancelado':
      case 'expirado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Boletos / Ventas'),
        actions: [
          IconButton(onPressed: () => context.read<BoletoProvider>().fetchBoletos(), icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterBar(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por pasajero o asiento...',
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

  Widget _buildFilterBar() {
    final opciones = {
      'todos': 'Todos',
      'pendiente': 'Pendientes',
      'pagado': 'Pagados',
      'cancelado': 'Cancelados',
    };
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: opciones.entries.map((e) {
            final selected = _filtro == e.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(e.value),
                selected: selected,
                onSelected: (_) => setState(() => _filtro = e.key),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildList() {
    return Consumer<BoletoProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());

        List<Boleto> boletos = _filtro == 'todos'
            ? provider.boletos
            : provider.boletos.where((b) => b.estado == _filtro).toList();

        if (_query.isNotEmpty) {
          boletos = boletos.where((b) =>
              b.nombrePasajero.toLowerCase().contains(_query) ||
              b.numeroAsiento.toString().toLowerCase().contains(_query)).toList();
        }

        if (boletos.isEmpty) {
          return Center(child: Text(_query.isEmpty ? 'No hay boletos registrados.' : 'Sin resultados para "$_query".'));
        }

        final totalVentas = boletos.fold<double>(0, (sum, b) => sum + b.precio);

        return Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${boletos.length} boleto(s)', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Total: Bs. ${totalVentas.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: boletos.length,
                itemBuilder: (context, index) {
                  final b = boletos[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _estadoColor(b.estado).withOpacity(0.15),
                        child: Icon(Icons.confirmation_number, color: _estadoColor(b.estado)),
                      ),
                      title: Text(b.nombrePasajero, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Asiento: ${b.numeroAsiento}  |  Pago: ${b.metodoPago}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Bs. ${b.precio.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(b.estado, style: TextStyle(fontSize: 11, color: _estadoColor(b.estado), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/viaje.dart';
import '../../models/conductor.dart';
import '../../models/asignacion_conductor.dart';
import '../../providers/conductor_provider.dart';
import '../../providers/asignacion_conductor_provider.dart';

class AsignacionConductorForm extends StatefulWidget {
  final Viaje viaje;
  const AsignacionConductorForm({super.key, required this.viaje});

  @override
  State<AsignacionConductorForm> createState() => _AsignacionConductorFormState();
}

class _AsignacionConductorFormState extends State<AsignacionConductorForm> {
  Conductor? _selectedConductor;
  String _tipoAsignacion = 'Principal';
  List<AsignacionConductor> _asignacionesActuales = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() async {
    if (!mounted) return;
    final ap = context.read<AsignacionConductorProvider>();
    final cp = context.read<ConductorProvider>();
    cp.fetchConductores();
    final data = await ap.fetchAsignaciones(widget.viaje.id!);
    setState(() {
      _asignacionesActuales = data;
    });
  }

  void _submit() async {
    if (_selectedConductor == null) return;
    
    final asignacion = AsignacionConductor(
      viajeId: widget.viaje.id!,
      conductorId: _selectedConductor!.id!,
      tipoAsignacion: _tipoAsignacion,
    );
    
    final success = await context.read<AsignacionConductorProvider>().asignarConductor(asignacion);
    if (success && mounted) {
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conductor asignado correctamente')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ConductorProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Asignar Personal')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VIAJE: ${widget.viaje.ruta?.origen ?? '...'} -> ${widget.viaje.ruta?.destino ?? '...'}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<Conductor>(
                      value: _selectedConductor,
                      decoration: const InputDecoration(labelText: 'Seleccionar Conductor'),
                      items: cp.conductores.map((c) => DropdownMenuItem(
                        value: c, 
                        child: Text(c.nombreCompleto)
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedConductor = v),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _tipoAsignacion,
                      decoration: const InputDecoration(labelText: 'Rol en el Viaje'),
                      items: ['Principal', 'Relevo'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _tipoAsignacion = v!),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _submit, 
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('VINCULAR CONDUCTOR'),
                      style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text('CONDUCTORES ASIGNADOS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _asignacionesActuales.length,
                itemBuilder: (context, index) {
                  final asig = _asignacionesActuales[index];
                  // Buscar nombre del conductor en la lista cargada
                  final cond = cp.conductores.cast<Conductor?>().firstWhere(
                    (c) => c?.id == asig.conductorId, 
                    orElse: () => null
                  );
                  
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(cond?.nombreCompleto ?? 'ID Conductor: ${asig.conductorId}'),
                    subtitle: Text('Rol: ${asig.tipoAsignacion}'),
                    trailing: const Icon(Icons.check_circle, color: Colors.green),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

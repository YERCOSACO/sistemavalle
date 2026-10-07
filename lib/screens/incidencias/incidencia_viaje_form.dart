import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/viaje.dart';
import '../../models/tipo_incidencia.dart';
import '../../models/incidencia_viaje.dart';
import '../../providers/tipo_incidencia_provider.dart';
import '../../providers/incidencia_viaje_provider.dart';

class IncidenciaViajeForm extends StatefulWidget {
  final Viaje viaje;
  const IncidenciaViajeForm({super.key, required this.viaje});

  @override
  State<IncidenciaViajeForm> createState() => _IncidenciaViajeFormState();
}

class _IncidenciaViajeFormState extends State<IncidenciaViajeForm> {
  final _formKey = GlobalKey<FormState>();
  TipoIncidencia? _selectedTipo;
  final _detalleController = TextEditingController();
  final DateTime _fechaInicio = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TipoIncidenciaProvider>().fetchTipos();
    });
  }

  @override
  void dispose() {
    _detalleController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_selectedTipo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione el tipo de incidencia'))
      );
      return;
    }
    
    if (!_formKey.currentState!.validate()) return;

    final incidencia = IncidenciaViaje(
      viajeId: widget.viaje.id!,
      tipoIncidenciaId: _selectedTipo!.id!,
      fechaInicio: _fechaInicio,
      descripcionDetalle: _detalleController.text.trim(),
    );
    
    final success = await context.read<IncidenciaViajeProvider>().saveIncidencia(incidencia);
    
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incidencia reportada con éxito'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tip = context.watch<TipoIncidenciaProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Reportar Incidencia')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('INFORMACIÓN DEL VIAJE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 8),
                  Text('Destino: ${widget.viaje.ruta?.destino ?? 'N/A'}'),
                  Text('Fecha: ${widget.viaje.fechaViaje.toLocal().toString().split(' ')[0]}'),
                ],
              ),
            ),
            const SizedBox(height: 25),
            DropdownButtonFormField<TipoIncidencia>(
              value: _selectedTipo,
              decoration: const InputDecoration(labelText: 'Categoría de Incidencia'),
              items: tip.tipos.map((t) => DropdownMenuItem(
                value: t, 
                child: Text('${t.nombre} (${t.nivelGravedad})')
              )).toList(),
              onChanged: (v) => setState(() => _selectedTipo = v),
              validator: (v) => v == null ? 'Seleccione una opción' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _detalleController,
              decoration: const InputDecoration(
                labelText: 'Descripción detallada',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (v) => v!.isEmpty ? 'Por favor describa lo ocurrido' : null,
            ),
            const SizedBox(height: 30),
            FilledButton.icon(
              onPressed: _submit, 
              icon: const Icon(Icons.report_problem),
              label: const Text('REGISTRAR INCIDENCIA'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                minimumSize: const Size(double.infinity, 54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

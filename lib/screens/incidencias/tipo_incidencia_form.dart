import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tipo_incidencia.dart';
import '../../providers/tipo_incidencia_provider.dart';

class TipoIncidenciaForm extends StatefulWidget {
  final TipoIncidencia? tipo;

  const TipoIncidenciaForm({super.key, this.tipo});

  @override
  State<TipoIncidenciaForm> createState() => _TipoIncidenciaFormState();
}

class _TipoIncidenciaFormState extends State<TipoIncidenciaForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  String _nivelGravedad = 'Leve';

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.tipo?.nombre);
    _descripcionController = TextEditingController(text: widget.tipo?.descripcion);
    _nivelGravedad = widget.tipo?.nivelGravedad ?? 'Leve';
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final t = TipoIncidencia(
        id: widget.tipo?.id,
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        nivelGravedad: _nivelGravedad,
      );
      final success = await context.read<TipoIncidenciaProvider>().saveTipo(t);
      if (success && mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.tipo == null ? 'Nuevo Tipo Incidencia' : 'Editar Tipo')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _nivelGravedad,
              decoration: const InputDecoration(labelText: 'Nivel de Gravedad'),
              items: ['Leve', 'Moderado', 'Grave', 'Crítico']
                  .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                  .toList(),
              onChanged: (v) => setState(() => _nivelGravedad = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 3,
            ),
            const SizedBox(height: 30),
            FilledButton(onPressed: _submit, child: const Text('Guardar')),
          ],
        ),
      ),
    );
  }
}

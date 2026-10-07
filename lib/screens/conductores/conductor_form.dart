import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/conductor.dart';
import '../../providers/conductor_provider.dart';

class ConductorForm extends StatefulWidget {
  final Conductor? conductor;
  const ConductorForm({super.key, this.conductor});

  @override
  State<ConductorForm> createState() => _ConductorFormState();
}

class _ConductorFormState extends State<ConductorForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _licenciaController;
  late TextEditingController _telefonoController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.conductor?.nombre);
    _apellidoController = TextEditingController(text: widget.conductor?.apellido);
    _licenciaController = TextEditingController(text: widget.conductor?.licencia);
    _telefonoController = TextEditingController(text: widget.conductor?.telefono);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _licenciaController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final c = Conductor(
      id: widget.conductor?.id,
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      licencia: _licenciaController.text.trim(),
      telefono: _telefonoController.text.trim(),
    );

    final provider = context.read<ConductorProvider>();
    final success = await provider.saveConductor(c);
    
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conductor guardado correctamente'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.conductor == null ? 'Nuevo Conductor' : 'Editar Conductor')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nombreController, 
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apellidoController, 
              decoration: const InputDecoration(labelText: 'Apellido'),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _licenciaController, 
              decoration: const InputDecoration(labelText: 'Nº Licencia'),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telefonoController, 
              decoration: const InputDecoration(labelText: 'Teléfono'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 30),
            FilledButton(
              onPressed: _submit, 
              child: const Text('GUARDAR'),
            ),
          ],
        ),
      ),
    );
  }
}

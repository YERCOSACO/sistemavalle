import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/bus.dart';
import '../../providers/bus_provider.dart';

class BusForm extends StatefulWidget {
  final Bus? bus;
  const BusForm({super.key, this.bus});

  @override
  State<BusForm> createState() => _BusFormState();
}

class _BusFormState extends State<BusForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _placaController;
  late TextEditingController _capacidadController;
  late TextEditingController _modeloController;
  String? _tipoBus;

  @override
  void initState() {
    super.initState();
    _placaController = TextEditingController(text: widget.bus?.placa);
    _capacidadController = TextEditingController(text: widget.bus?.capacidad.toString());
    _modeloController = TextEditingController(text: widget.bus?.modelo);
    _tipoBus = widget.bus?.tipoBus ?? 'Semi-cama';
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final bus = Bus(
      id: widget.bus?.id,
      placa: _placaController.text,
      capacidad: int.parse(_capacidadController.text),
      modelo: _modeloController.text,
      tipoBus: _tipoBus,
    );
    final success = await context.read<BusProvider>().saveBus(bus);
    if (success && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.bus == null ? 'Nuevo Bus' : 'Editar Bus')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(controller: _placaController, decoration: const InputDecoration(labelText: 'Placa')),
            TextFormField(controller: _capacidadController, decoration: const InputDecoration(labelText: 'Capacidad'), keyboardType: TextInputType.number),
            TextFormField(controller: _modeloController, decoration: const InputDecoration(labelText: 'Modelo')),
            DropdownButtonFormField<String>(
              value: _tipoBus,
              items: ['Cama', 'Semi-cama', 'Normal'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _tipoBus = v),
              decoration: const InputDecoration(labelText: 'Tipo de Bus'),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _submit, child: const Text('Guardar')),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ruta.dart';
import '../../providers/ruta_provider.dart';

class RutaForm extends StatefulWidget {
  final Ruta? ruta;

  const RutaForm({super.key, this.ruta});

  @override
  State<RutaForm> createState() => _RutaFormState();
}

class _RutaFormState extends State<RutaForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _origenController;
  late TextEditingController _destinoController;
  late TextEditingController _precioController;
  late TextEditingController _distanciaController;

  @override
  void initState() {
    super.initState();
    _origenController = TextEditingController(text: widget.ruta?.origen);
    _destinoController = TextEditingController(text: widget.ruta?.destino);
    _precioController = TextEditingController(text: widget.ruta?.precioBase.toString());
    _distanciaController = TextEditingController(text: widget.ruta?.distanciaKm?.toString());
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final r = Ruta(
        id: widget.ruta?.id,
        origen: _origenController.text,
        destino: _destinoController.text,
        precioBase: double.parse(_precioController.text),
        distanciaKm: double.tryParse(_distanciaController.text),
      );
      final success = await context.read<RutaProvider>().saveRuta(r);
      if (success && mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.ruta == null ? 'Nueva Ruta' : 'Editar Ruta')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(controller: _origenController, decoration: const InputDecoration(labelText: 'Origen')),
            TextFormField(controller: _destinoController, decoration: const InputDecoration(labelText: 'Destino')),
            TextFormField(controller: _precioController, decoration: const InputDecoration(labelText: 'Precio Base'), keyboardType: TextInputType.number),
            TextFormField(controller: _distanciaController, decoration: const InputDecoration(labelText: 'Distancia (Km)'), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            FilledButton(onPressed: _submit, child: const Text('Guardar')),
          ],
        ),
      ),
    );
  }
}

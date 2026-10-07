import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tipo_encomienda.dart';
import '../../providers/tipo_encomienda_provider.dart';

class TipoEncomiendaForm extends StatefulWidget {
  final TipoEncomienda? tipo;
  const TipoEncomiendaForm({super.key, this.tipo});

  @override
  State<TipoEncomiendaForm> createState() => _TipoEncomiendaFormState();
}

class _TipoEncomiendaFormState extends State<TipoEncomiendaForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _precioController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.tipo?.nombre);
    _precioController = TextEditingController(text: widget.tipo?.precio.toString());
    _descController = TextEditingController(text: widget.tipo?.descripcion);
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final t = TipoEncomienda(
      id: widget.tipo?.id,
      nombre: _nombreController.text,
      precio: double.parse(_precioController.text),
      descripcion: _descController.text,
    );
    final success = await context.read<TipoEncomiendaProvider>().saveTipo(t);
    if (success && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.tipo == null ? 'Nuevo Tipo' : 'Editar Tipo')),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          TextFormField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Nombre')),
          TextFormField(controller: _precioController, decoration: const InputDecoration(labelText: 'Precio'), keyboardType: TextInputType.number),
          TextFormField(controller: _descController, decoration: const InputDecoration(labelText: 'Descripción')),
          const SizedBox(height: 20),
          FilledButton(onPressed: _submit, child: const Text('Guardar')),
        ]),
      ),
    );
  }
}

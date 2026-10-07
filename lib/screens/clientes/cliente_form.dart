import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cliente.dart';
import '../../providers/cliente_provider.dart';

class ClienteForm extends StatefulWidget {
  final Cliente? cliente;
  const ClienteForm({super.key, this.cliente});

  @override
  State<ClienteForm> createState() => _ClienteFormState();
}

class _ClienteFormState extends State<ClienteForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  late TextEditingController _ciController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.cliente?.nombre);
    _apellidoController = TextEditingController(text: widget.cliente?.apellido);
    _emailController = TextEditingController(text: widget.cliente?.email);
    _telefonoController = TextEditingController(text: widget.cliente?.telefono);
    _ciController = TextEditingController(text: widget.cliente?.ci);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _ciController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final cliente = Cliente(
      id: widget.cliente?.id,
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      email: _emailController.text.trim(),
      telefono: _telefonoController.text.trim(),
      ci: _ciController.text.trim(),
      estado: widget.cliente?.estado ?? true,
    );

    final provider = context.read<ClienteProvider>();
    final success = widget.cliente == null 
        ? await provider.createCliente(cliente)
        : await provider.updateCliente(cliente);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.cliente == null ? 'Nuevo Cliente' : 'Editar Cliente')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Nombre'), validator: (v) => v!.isEmpty ? 'Requerido' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _apellidoController, decoration: const InputDecoration(labelText: 'Apellido'), validator: (v) => v!.isEmpty ? 'Requerido' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            TextFormField(controller: _ciController, decoration: const InputDecoration(labelText: 'CI / Cédula'), validator: (v) => v!.isEmpty ? 'Requerido' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _telefonoController, decoration: const InputDecoration(labelText: 'Teléfono'), keyboardType: TextInputType.phone),
            const SizedBox(height: 30),
            FilledButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('GUARDAR CLIENTE'),
            ),
          ],
        ),
      ),
    );
  }
}

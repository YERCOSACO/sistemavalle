import 'package:flutter/material.dart';

import '../../models/cliente.dart';
import '../../providers/cliente_provider.dart';

class ClienteFormScreen extends StatefulWidget {
  const ClienteFormScreen({
    super.key,
    required this.clienteProvider,
    this.cliente,
  });

  final ClienteProvider clienteProvider;
  final Cliente? cliente;

  bool get isEdit => cliente != null;

  @override
  State<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends State<ClienteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _apellidoController;
  late final TextEditingController _emailController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _ciController;
  late final TextEditingController _passwordController;
  late final TextEditingController _passwordConfirmationController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final cliente = widget.cliente;
    _nombreController = TextEditingController(text: cliente?.nombre ?? '');
    _apellidoController = TextEditingController(text: cliente?.apellido ?? '');
    _emailController = TextEditingController(text: cliente?.email ?? '');
    _telefonoController = TextEditingController(text: cliente?.telefono ?? '');
    _ciController = TextEditingController(text: cliente?.ci ?? '');
    _passwordController = TextEditingController();
    _passwordConfirmationController = TextEditingController();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _ciController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final cliente = Cliente(
      id: widget.cliente?.id,
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      email: _emailController.text.trim(),
      telefono:
          _telefonoController.text.trim().isEmpty
              ? null
              : _telefonoController.text.trim(),
      ci: _ciController.text.trim(),
      password:
          _passwordController.text.trim().isEmpty
              ? null
              : _passwordController.text.trim(),
      passwordConfirmation:
          _passwordConfirmationController.text.trim().isEmpty
              ? null
              : _passwordConfirmationController.text.trim(),
      estado: widget.cliente?.estado ?? true,
    );

    final success =
        widget.isEdit
            ? await widget.clienteProvider.updateCliente(cliente)
            : await widget.clienteProvider.createCliente(cliente);

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.clienteProvider.errorMessage ??
              'No se pudo guardar el cliente',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEdit ? 'Editar cliente' : 'Nuevo cliente';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          fillColor: Colors.blue,
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es obligatorio';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _apellidoController,
                        decoration: const InputDecoration(
                          labelText: 'Apellido',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El email es obligatorio';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _telefonoController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Telefono',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _telefonoController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Telefono',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _ciController,
                        decoration: const InputDecoration(
                          labelText: 'CI',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El CI es obligatorio';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText:
                              widget.isEdit ? 'Nueva contraseña' : 'Contraseña',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (!widget.isEdit && trimmed.isEmpty) {
                            return 'La contraseña es obligatoria';
                          }
                          if (trimmed.isNotEmpty && trimmed.length < 8) {
                            return 'La contraseña debe tener al menos 8 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordConfirmationController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar contraseña',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final password = _passwordController.text.trim();
                          final confirmation = value?.trim() ?? '';
                          if (password.isEmpty && widget.isEdit) {
                            return null;
                          }
                          if (confirmation.isEmpty) {
                            return 'Confirma la contraseña';
                          }
                          if (password != confirmation) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _isSaving ? null : _submit,
                        child: Text(widget.isEdit ? 'Guardar' : 'Crear'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

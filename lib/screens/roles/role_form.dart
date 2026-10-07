import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/role.dart';
import '../../providers/role_provider.dart';

class RoleForm extends StatefulWidget {
  final Role? role;
  const RoleForm({super.key, this.role});

  @override
  State<RoleForm> createState() => _RoleFormState();
}

class _RoleFormState extends State<RoleForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.role?.name);
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final role = Role(
      id: widget.role?.id,
      name: _nameController.text.trim(),
      guardName: widget.role?.guardName ?? 'web',
    );
    final success = await context.read<RoleProvider>().saveRole(role);
    if (success && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.role == null ? 'Nuevo Rol' : 'Editar Rol')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre del rol', prefixIcon: Icon(Icons.security)),
              validator: (v) => (v == null || v.isEmpty) ? 'Ingrese el nombre del rol' : null,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _submit, child: const Text('Guardar')),
          ],
        ),
      ),
    );
  }
}

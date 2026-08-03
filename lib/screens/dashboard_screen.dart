import 'package:flutter/material.dart';

import '../models/cliente.dart';
import '../providers/auth_provider.dart';
import '../providers/cliente_provider.dart';
import 'clientes/cliente_form_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.authProvider,
    required this.clienteProvider,
  });

  final AuthProvider authProvider;
  final ClienteProvider clienteProvider;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<void> _openClienteForm({Cliente? cliente}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => ClienteFormScreen(
              clienteProvider: widget.clienteProvider,
              cliente: cliente,
            ),
      ),
    );
  }

  Future<void> _deleteCliente(int id, String nombreCompleto) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Desactivar cliente'),
            content: Text(
              'Se desactivará a $nombreCompleto. Deseas continuar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Desactivar'),
              ),
            ],
          ),
    );

    if (confirmed != true) {
      return;
    }

    final success = await widget.clienteProvider.deleteCliente(id);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Cliente desactivado correctamente'
              : (widget.clienteProvider.errorMessage ??
                  'No se pudo desactivar el cliente'),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.clienteProvider.fetchClientes();
    });
  }

  Future<void> _logout() async {
    await widget.authProvider.logout();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder:
            (_) => LoginScreen(
              authProvider: widget.authProvider,
              clienteProvider: widget.clienteProvider,
            ),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.authProvider,
        widget.clienteProvider,
      ]),
      builder: (context, _) {
        final user = widget.authProvider.user;
        final clienteProvider = widget.clienteProvider;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
            actions: [
              IconButton(
                tooltip: 'Recargar',
                onPressed:
                    clienteProvider.isLoading
                        ? null
                        : () => widget.clienteProvider.fetchClientes(),
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: 'Cerrar sesión',
                onPressed: _logout,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => widget.clienteProvider.fetchClientes(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    title: Text(
                      user?['name']?.toString() ?? 'Usuario autenticado',
                    ),
                    subtitle: Text(user?['email']?.toString() ?? 'Sin correo'),
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Clientes',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _openClienteForm(),
                      label: const Text('AgregarCliente'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (clienteProvider.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(clienteProvider.errorMessage!),
                      ),
                    ),
                  ),
                if (clienteProvider.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (clienteProvider.clientes.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No hay clientes para mostrar.'),
                    ),
                  )
                else
                  ...clienteProvider.clientes.map(
                    (cliente) => Card(
                      child: ListTile(
                        title: Text('${cliente.nombre} ${cliente.apellido}'),
                        subtitle: Text(
                          [
                            if ((cliente.email ?? '').isNotEmpty)
                              cliente.email!,
                            'CI: ${cliente.ci}',
                            'Estado: ${cliente.estado ? 'Activo' : 'Inactivo'}',
                          ].join(' | '),
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(cliente.telefono ?? '-'),
                            OutlinedButton(
                              onPressed:
                                  () => _openClienteForm(cliente: cliente),
                              child: const Text('ModificarCliente'),
                            ),
                            FilledButton.tonal(
                              onPressed:
                                  cliente.id == null
                                      ? null
                                      : () => _deleteCliente(
                                        cliente.id!,
                                        '${cliente.nombre} ${cliente.apellido}',
                                      ),
                              child: const Text('EliminarCliente'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

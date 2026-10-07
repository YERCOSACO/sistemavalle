import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notificacion_provider.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificacionProvider>(context, listen: false).fetchMisNotificaciones();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: Consumer<NotificacionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          if (provider.notificaciones.isEmpty) {
            return const Center(child: Text('No tienes notificaciones.'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchMisNotificaciones(),
            child: ListView.builder(
              itemCount: provider.notificaciones.length,
              itemBuilder: (context, index) {
                final notif = provider.notificaciones[index];
                final isRead = notif.estado == 'leida';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isRead ? Colors.grey.shade200 : Colors.blue.shade100,
                    child: Icon(
                      notif.tipo == 'urgente' ? Icons.warning : Icons.notifications,
                      color: isRead ? Colors.grey : Colors.blue,
                    ),
                  ),
                  title: Text(
                    notif.titulo,
                    style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notif.mensaje),
                      Text(
                        '${notif.fechaEnvio?.day}/${notif.fechaEnvio?.month} ${notif.fechaEnvio?.hour}:${notif.fechaEnvio?.minute}',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                  onTap: () {
                    if (!isRead) {
                      provider.marcarLeida(notif.id!);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'edit_profile_screen.dart';
import 'reservas/mis_reservas_screen.dart';
import 'encomiendas/mis_encomiendas_screen.dart';
import 'notificaciones/notificaciones_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(Icons.person, size: 70, color: Colors.blue.shade700),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.blue.shade700,
                      radius: 18,
                      child: const Icon(Icons.edit, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              user?['name'] ?? 'Usuario',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              user?['email'] ?? '',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 30),
            
            _buildProfileSection(context, [
              _ProfileItem(Icons.person_outline, 'Datos Personales', 'Nombre, CI, Teléfono',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()))),
              _ProfileItem(Icons.history, 'Mis Viajes', 'Historial de boletos comprados',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MisReservasScreen()))),
              _ProfileItem(Icons.local_shipping_outlined, 'Mis Encomiendas', 'Seguimiento de envíos',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MisEncomiendasScreen()))),
            ], 'Cuenta'),
            
            _buildProfileSection(context, [
              _ProfileItem(Icons.notifications_outlined, 'Notificaciones', 'Configurar alertas',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificacionesScreen()))),
              _ProfileItem(Icons.lock_outline, 'Seguridad', 'Cambiar mi contraseña',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()))),
            ], 'Preferencias'),
            
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: OutlinedButton.icon(
                onPressed: () => auth.logout(),
                icon: const Icon(Icons.logout),
                label: const Text('CERRAR SESIÓN'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, List<_ProfileItem> items, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 20, bottom: 10),
          child: Text(
            title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue.shade700, letterSpacing: 1),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Column(
            children: items.map((item) => _buildListTile(item)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildListTile(_ProfileItem item) {
    return ListTile(
      leading: Icon(item.icon, color: Colors.blue.shade700),
      title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(item.subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: item.onTap,
    );
  }
}

class _ProfileItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _ProfileItem(this.icon, this.title, this.subtitle, this.onTap);
}

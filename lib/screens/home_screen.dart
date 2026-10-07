import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'viajes/trip_search_screen.dart';
import 'reservas/mis_reservas_screen.dart';
import 'encomiendas/mis_encomiendas_screen.dart';
import 'profile_screen.dart';
import 'notificaciones/notificaciones_screen.dart';
import 'encomiendas/encomienda_form.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lista de pantallas para cada pestaña
    final List<Widget> screens = [
      _HomeView(onNavigateToSearch: () => _onTabTapped(1)),
      const TripSearchScreen(),
      const MisReservasScreen(),
      const MisEncomiendasScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Viajes'),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_number), label: 'Pasajes'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Encomiendas'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

class _HomeView extends StatelessWidget {
  final VoidCallback onNavigateToSearch;
  const _HomeView({required this.onNavigateToSearch});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Valle', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificacionesScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '¡Hola, ${user?['name'] ?? 'Usuario'}!',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('¿A dónde quieres viajar hoy?', style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 25),
          
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.search,
                  label: 'Buscar Viaje',
                  color: Colors.blue,
                  onTap: onNavigateToSearch,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ActionCard(
                  icon: Icons.local_shipping,
                  label: 'Enviar Paquete',
                  color: Colors.orange,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EncomiendaForm()),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 35),
          const Text(
            'Servicios Destacados',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          
          _buildInfoTile(
            Icons.qr_code_scanner, 
            'Pago Fácil con QR', 
            'Reserva y paga tus pasajes de forma rápida.'
          ),
          _buildInfoTile(
            Icons.support_agent, 
            'Atención al Cliente', 
            'Estamos disponibles para ayudarte en tu viaje.'
          ),
          _buildInfoTile(
            Icons.history, 
            'Historial de Viajes', 
            'Revisa tus viajes pasados y encomiendas.'
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              label, 
              style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/viaje_provider.dart';
import '../providers/cliente_provider.dart';
import '../providers/encomienda_provider.dart';

// Importación de pantallas
import 'clientes/clientes_screen.dart';
import 'buses/buses_screen.dart';
import 'conductores/conductores_screen.dart';
import 'rutas/rutas_screen.dart';
import 'viajes/viajes_screen.dart';
import 'encomiendas/encomiendas_admin_screen.dart';
import 'encomiendas/tipo_encomiendas_screen.dart';
import 'incidencias/tipo_incidencias_screen.dart';
import 'viajes/viaje_form.dart';
import 'encomiendas/encomienda_form.dart';
import 'usuarios/usuarios_screen.dart';
import 'roles/roles_screen.dart';
import 'boletos/boletos_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _refreshData());
  }

  void _refreshData() {
    context.read<ViajeProvider>().searchViajes();
    context.read<ClienteProvider>().fetchClientes();
    context.read<EncomiendaProvider>().fetchTodas();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('CENTRO DE CONTROL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(onPressed: _refreshData, icon: const Icon(Icons.sync)),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildHamburgerMenu(context, auth),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bienvenido, ${auth.user?['name'] ?? 'Admin'}', 
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            const Text('Gestiona la flota y servicios desde aquí.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 25),
            
            _buildStatsCards(context),
            const SizedBox(height: 30),
            
            const Text('ACCIONES DE GESTIÓN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey, letterSpacing: 1.2)),
            const SizedBox(height: 15),
            
            // Botones grandes como los del cliente pero para Admin
            _buildQuickActionGrid(context),
            
            const SizedBox(height: 30),
            const Text('ESTADO DEL SISTEMA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
            const SizedBox(height: 15),
            _buildSystemStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildHamburgerMenu(BuildContext context, AuthProvider auth) {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(auth),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _menuCat('SEGURIDAD'),
                _menuItem(Icons.person_outline, 'Usuarios', () => _nav(context, const UsuariosScreen())),
                _menuItem(Icons.security, 'Roles', () => _nav(context, const RolesScreen())),
                
                _menuCat('PARAMETRIZACIÓN'),
                _menuItem(Icons.people_alt_outlined, 'Clientes', () => _nav(context, const ClientesScreen())),
                _menuItem(Icons.directions_bus_outlined, 'Buses', () => _nav(context, const BusesScreen())),
                _menuItem(Icons.drive_eta_outlined, 'Conductores', () => _nav(context, const ConductoresScreen())),
                _menuItem(Icons.map_outlined, 'Rutas', () => _nav(context, const RutasScreen())),
                _menuItem(Icons.category_outlined, 'Tipos Encomienda', () => _nav(context, const TipoEncomiendasScreen())),
                _menuItem(Icons.report_gmailerrorred_outlined, 'Tipos Incidencia', () => _nav(context, const TipoIncidenciasScreen())),

                _menuCat('TRANSACCIONAL'),
                _menuItem(Icons.schedule, 'Viajes', () => _nav(context, const ViajesScreen())),
                _menuItem(Icons.local_shipping_outlined, 'Encomiendas', () => _nav(context, const EncomiendasAdminScreen())),
                _menuItem(Icons.confirmation_number_outlined, 'Boletos / Ventas', () => _nav(context, const BoletosScreen())),
              ],
            ),
          ),
          const Divider(),
          _menuItem(Icons.logout, 'Cerrar Sesión', () => auth.logout(), color: Colors.red),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(AuthProvider auth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 25, left: 20),
      color: const Color(0xFF0F172A),
      child: Row(
        children: [
          CircleAvatar(radius: 25, backgroundColor: Colors.blue.shade700, child: const Icon(Icons.admin_panel_settings, color: Colors.white)),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(auth.user?['name'] ?? 'Admin', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(auth.user?['email'] ?? '', style: const TextStyle(color: Colors.white60, fontSize: 11)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context) {
    final v = context.watch<ViajeProvider>().viajes.length;
    final c = context.watch<ClienteProvider>().clientes.length;
    final e = context.watch<EncomiendaProvider>().encomiendas.length;

    return Row(
      children: [
        Expanded(child: _statTile('Clientes', '$c', Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _statTile('Viajes', '$v', Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _statTile('Cargas', '$e', Colors.orange)),
      ],
    );
  }

  Widget _statTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildQuickActionGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.1,
      children: [
        _actionCard('Programar Viaje', Icons.add_location_alt, Colors.blue, () => _nav(context, const ViajeForm())),
        _actionCard('Nueva Encomienda', Icons.local_shipping, Colors.orange, () => _nav(context, const EncomiendaForm())),
        _actionCard('Ver Flota', Icons.directions_bus, Colors.purple, () => _nav(context, const BusesScreen())),
        _actionCard('Rutas y Precios', Icons.map, Colors.teal, () => _nav(context, const RutasScreen())),
      ],
    );
  }

  Widget _actionCard(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.1), radius: 25, child: Icon(icon, color: color)),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade100)),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 15),
          Text('Conexión con Servidor Activa', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _menuCat(String t) => Padding(padding: const EdgeInsets.only(left: 20, top: 20, bottom: 8), child: Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5)));
  Widget _menuItem(IconData i, String t, VoidCallback onTap, {Color? color}) => ListTile(leading: Icon(i, size: 20, color: color ?? Colors.blueGrey), title: Text(t, style: TextStyle(fontSize: 14, color: color ?? Colors.black87)), onTap: onTap, dense: true);

  void _nav(BuildContext context, Widget s) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => s));
  }
}

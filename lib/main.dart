import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/cliente_provider.dart';
import 'providers/viaje_provider.dart';
import 'providers/reserva_provider.dart';
import 'providers/encomienda_provider.dart';
import 'providers/bus_provider.dart';
import 'providers/conductor_provider.dart';
import 'providers/ruta_provider.dart';
import 'providers/tipo_encomienda_provider.dart';
import 'providers/tipo_incidencia_provider.dart';
import 'providers/incidencia_viaje_provider.dart';
import 'providers/asignacion_conductor_provider.dart';
import 'providers/notificacion_provider.dart';
import 'providers/user_provider.dart';
import 'providers/role_provider.dart';
import 'providers/boleto_provider.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ClienteProvider()),
        ChangeNotifierProvider(create: (_) => ViajeProvider()),
        ChangeNotifierProvider(create: (_) => ReservaProvider()),
        ChangeNotifierProvider(create: (_) => EncomiendaProvider()),
        ChangeNotifierProvider(create: (_) => BusProvider()),
        ChangeNotifierProvider(create: (_) => ConductorProvider()),
        ChangeNotifierProvider(create: (_) => RutaProvider()),
        ChangeNotifierProvider(create: (_) => TipoEncomiendaProvider()),
        ChangeNotifierProvider(create: (_) => TipoIncidenciaProvider()),
        ChangeNotifierProvider(create: (_) => IncidenciaViajeProvider()),
        ChangeNotifierProvider(create: (_) => AsignacionConductorProvider()),
        ChangeNotifierProvider(create: (_) => NotificacionProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => RoleProvider()),
        ChangeNotifierProvider(create: (_) => BoletoProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema Valle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A)),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await context.read<AuthProvider>().checkAuthStatus();
    if (mounted) setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final auth = context.watch<AuthProvider>();
    
    if (!auth.isAuthenticated) return const LoginScreen();

    // Verificación crítica: Solo si es Staff va al Dashboard
    if (auth.isStaff) {
      return const DashboardScreen();
    }

    // De lo contrario, cliente normal
    return const HomeScreen();
  }
}

import 'package:flutter/material.dart';

import 'providers/auth_provider.dart';
import 'providers/cliente_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema Valle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
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
  final AuthProvider _authProvider = AuthProvider();
  final ClienteProvider _clienteProvider = ClienteProvider();
  late Future<void> _authCheck;

  @override
  void initState() {
    super.initState();
    _authCheck = _authProvider.checkAuthStatus();
  }

  @override
  void dispose() {
    _authProvider.dispose();
    _clienteProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _authCheck,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return AnimatedBuilder(
          animation: _authProvider,
          builder: (context, _) {
            if (_authProvider.isAuthenticated) {
              return DashboardScreen(
                authProvider: _authProvider,
                clienteProvider: _clienteProvider,
              );
            }

            return LoginScreen(
              authProvider: _authProvider,
              clienteProvider: _clienteProvider,
            );
          },
        );
      },
    );
  }
}

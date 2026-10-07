import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/encomienda.dart';
import '../../models/viaje.dart';
import '../../models/tipo_encomienda.dart';
import '../../providers/encomienda_provider.dart';
import '../../providers/viaje_provider.dart';
import '../../providers/auth_provider.dart';

class EncomiendaForm extends StatefulWidget {
  const EncomiendaForm({super.key});

  @override
  State<EncomiendaForm> createState() => _EncomiendaFormState();
}

class _EncomiendaFormState extends State<EncomiendaForm> {
  final _formKey = GlobalKey<FormState>();
  final _destinatarioController = TextEditingController();
  final _ciController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _cantidadController = TextEditingController(text: '1');

  Viaje? _selectedViaje;
  TipoEncomienda? _selectedTipo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EncomiendaProvider>().fetchTipos();
      context.read<ViajeProvider>().searchViajes();
    });
  }

  @override
  void dispose() {
    _destinatarioController.dispose();
    _ciController.dispose();
    _telefonoController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  double get _total {
    if (_selectedTipo == null) return 0;
    int cant = int.tryParse(_cantidadController.text) ?? 1;
    return _selectedTipo!.precio * cant;
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedViaje == null || _selectedTipo == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleccione viaje y tipo de encomienda')));
      return;
    }

    final auth = context.read<AuthProvider>();
    final provider = context.read<EncomiendaProvider>();

    final encomienda = Encomienda(
      clienteId: auth.user?['id'],
      destinatarioNombre: _destinatarioController.text.trim(),
      destinatarioCi: _ciController.text.trim(),
      destinatarioTelefono: _telefonoController.text.trim(),
      viajeId: _selectedViaje!.id!,
      tipoEncomiendaId: _selectedTipo!.id!,
      cantidad: int.parse(_cantidadController.text),
      totalPagar: _total,
    );

    final success = await provider.registrarEncomienda(encomienda);
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Encomienda registrada con éxito')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ep = context.watch<EncomiendaProvider>();
    final vp = context.watch<ViajeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Encomienda')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('DATOS DEL DESTINATARIO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
            const Divider(),
            const SizedBox(height: 10),
            TextFormField(
              controller: _destinatarioController, 
              decoration: const InputDecoration(labelText: 'Nombre Completo'),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _ciController, decoration: const InputDecoration(labelText: 'Cédula (CI)'))),
                const SizedBox(width: 10),
                Expanded(child: TextFormField(controller: _telefonoController, decoration: const InputDecoration(labelText: 'Teléfono'), keyboardType: TextInputType.phone)),
              ],
            ),
            const SizedBox(height: 30),
            const Text('DETALLES DEL ENVÍO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
            const Divider(),
            const SizedBox(height: 10),
            DropdownButtonFormField<Viaje>(
              value: _selectedViaje,
              items: vp.viajes.map((v) => DropdownMenuItem(value: v, child: Text('${v.ruta?.destino ?? 'Sin destino'} - ${v.horaSalida}'))).toList(),
              onChanged: (val) => setState(() => _selectedViaje = val),
              decoration: const InputDecoration(labelText: 'Seleccionar Viaje'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TipoEncomienda>(
              value: _selectedTipo,
              items: ep.tipos.map((t) => DropdownMenuItem(value: t, child: Text('${t.nombre} (Bs. ${t.precio})'))).toList(),
              onChanged: (val) => setState(() => _selectedTipo = val),
              decoration: const InputDecoration(labelText: 'Tipo de Paquete'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cantidadController, 
              decoration: const InputDecoration(labelText: 'Cantidad / Unidades'), 
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL A PAGAR:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Bs. $_total', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            FilledButton(
              onPressed: _submit, 
              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 54)),
              child: const Text('CONFIRMAR ENVÍO'),
            ),
          ],
        ),
      ),
    );
  }
}

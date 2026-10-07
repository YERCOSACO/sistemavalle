import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/viaje.dart';
import '../../models/bus.dart';
import '../../providers/viaje_provider.dart';
import '../../providers/bus_provider.dart';
import '../../providers/ruta_provider.dart';

class ViajeForm extends StatefulWidget {
  final Viaje? viaje;
  const ViajeForm({super.key, this.viaje});

  @override
  State<ViajeForm> createState() => _ViajeFormState();
}

class _ViajeFormState extends State<ViajeForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  Bus? _selectedBus;
  int? _selectedRutaId;

  @override
  void initState() {
    super.initState();
    if (widget.viaje != null) {
      _selectedDate = widget.viaje!.fechaViaje;
      final parts = widget.viaje!.horaSalida.split(':');
      _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      _selectedRutaId = widget.viaje!.rutaId;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BusProvider>().fetchBuses();
      context.read<RutaProvider>().fetchRutas();
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null || _selectedBus == null || _selectedRutaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor complete todos los campos')));
      return;
    }

    final viaje = Viaje(
      id: widget.viaje?.id,
      rutaId: _selectedRutaId!,
      busId: _selectedBus!.id!,
      fechaViaje: _selectedDate!,
      horaSalida: '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00',
      estado: widget.viaje?.estado ?? 'programado',
    );
    
    final success = await context.read<ViajeProvider>().saveViaje(viaje);
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Viaje guardado correctamente')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final busProvider = context.watch<BusProvider>();
    final rutaProvider = context.watch<RutaProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.viaje == null ? 'Programar Viaje' : 'Editar Viaje')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField<int>(
              value: _selectedRutaId,
              items: rutaProvider.rutas.map((r) => DropdownMenuItem(value: r.id, child: Text('${r.origen} - ${r.destino}'))).toList(),
              onChanged: (v) => setState(() => _selectedRutaId = v),
              decoration: const InputDecoration(labelText: 'Ruta Destino'),
              validator: (v) => v == null ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade300)),
              title: Text(_selectedDate == null ? 'Seleccionar Fecha' : 'Fecha: ${_selectedDate!.toLocal().toString().split(' ')[0]}'),
              trailing: const Icon(Icons.calendar_today, color: Colors.blue),
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: _selectedDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                if (d != null) setState(() => _selectedDate = d);
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade300)),
              title: Text(_selectedTime == null ? 'Seleccionar Hora' : 'Hora: ${_selectedTime!.format(context)}'),
              trailing: const Icon(Icons.access_time, color: Colors.blue),
              onTap: () async {
                final t = await showTimePicker(context: context, initialTime: _selectedTime ?? TimeOfDay.now());
                if (t != null) setState(() => _selectedTime = t);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Bus>(
              value: _selectedBus,
              items: busProvider.buses.map((b) => DropdownMenuItem(value: b, child: Text('${b.placa} (${b.tipoBus})'))).toList(),
              onChanged: (v) => setState(() => _selectedBus = v),
              decoration: const InputDecoration(labelText: 'Bus Asignado'),
              validator: (v) => v == null ? 'Requerido' : null,
            ),
            const SizedBox(height: 40),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 54)),
              child: const Text('GUARDAR VIAJE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

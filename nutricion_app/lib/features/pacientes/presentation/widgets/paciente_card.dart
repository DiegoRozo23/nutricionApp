import 'package:flutter/material.dart';
import '../../domain/entities/paciente.dart';

/// Widget para mostrar un paciente en la lista
class PacienteCard extends StatelessWidget {
  final Paciente paciente;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const PacienteCard({
    super.key,
    required this.paciente,
    required this.onTap,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.primary,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            // Información (área táctil para ver detalles)
            Expanded(
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paciente.nombreCompleto,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (paciente.dni != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'DNI: ${paciente.dni}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      if (paciente.edad != null || paciente.sexo != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (paciente.edad != null) '${paciente.edad} años',
                            if (paciente.sexo != null) paciente.sexo!,
                          ].join(' • '),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Botones de acción (editar y eliminar)
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                color: Theme.of(context).colorScheme.primary,
                onPressed: () {
                  onEdit!();
                },
                tooltip: 'Editar paciente',
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red.shade400,
                onPressed: () {
                  onDelete!();
                },
                tooltip: 'Eliminar paciente',
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sunu_task/models/project.dart';

/// Widget ProjectCard
/// Affiche un projet sous forme de carte avec :
/// - Pastille de couleur
/// - Nom et description
/// - Nombre de taches
/// - Menu contextuel (modifier / supprimer)
/// - Callback pour navigation (onTap)
class ProjectCard extends StatelessWidget {
  final Project project;       // donnees du projet
  final int taskCount;         // nombre de taches du projet
  final VoidCallback? onTap;   // callback quand on clique sur la carte
  final VoidCallback? onEdit;  // callback pour modifier le projet
  final VoidCallback? onDelete;// callback pour supprimer le projet

  const ProjectCard({
    super.key,
    required this.project,
    required this.taskCount,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      // Carte material design avec effet d'elevation
      child: InkWell(
        onTap: onTap, // Navigation vers la page du projet
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pastille de couleur du projet
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Color(project.colorValue), // couleur du projet
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),

              // infos du projet (nom, description, nombre de taches)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom du projet
                    Text(
                      project.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    // Description du projet (si non vide)
                    if ((project.description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        project.description!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Nombre de taches
                    Text('$taskCount taches'),
                  ],
                ),
              ),

              // Menu contextuel pour modifier ou supprimer
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit?.call();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
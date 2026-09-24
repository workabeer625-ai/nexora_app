import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firestore_service.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../models/project_model.dart';

final class FirestoreProjectRepository implements ProjectRepository {
  FirestoreProjectRepository({required FirestoreService firestoreService})
    : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  @override
  Stream<List<Project>> watchProjects(String workspaceId) {
    return _firestoreService
        .collection(FirestorePaths.workspaceProjects(workspaceId))
        .where('is_archived', isEqualTo: false)
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(ProjectModel.fromSnapshot)
              .toList(growable: false),
        );
  }

  @override
  Stream<Project?> watchProject(String workspaceId, String projectId) {
    return _firestoreService
        .document(FirestorePaths.project(workspaceId, projectId))
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            return null;
          }

          return ProjectModel.fromSnapshot(snapshot);
        });
  }

  @override
  Future<String> createProject({
    required String workspaceId,
    required String name,
    required String description,
    required ProjectStatus status,
    required String createdBy,
  }) async {
    final projectsCollection = _firestoreService.collection(
      FirestorePaths.workspaceProjects(workspaceId),
    );
    final projectDoc = projectsCollection.doc();

    await projectDoc.set({
      'id': projectDoc.id,
      'workspace_id': workspaceId,
      'name': name,
      'description': description,
      'status': status.value,
      'created_by': createdBy,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'is_archived': false,
    });

    return projectDoc.id;
  }
}

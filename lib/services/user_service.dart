import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference<Map<String, dynamic>> _users = FirebaseFirestore
      .instance
      .collection('users');

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user!;
    try {
      await _users.doc(user.uid).set({
        'uid': user.uid,
        'displayName': name.trim(),
        'email': email.trim(),
        'photoURL': '',
      });
    } catch (_) {
      // Do not leave an authenticated account without its application profile.
      await user.delete();
      rethrow;
    }

    return credential;
  }

  Future<UserModel?> getUser() async {
    final user = _auth.currentUser;

    if (user == null) return null;

    try {
      final doc = await _users.doc(user.uid).get();

      if (!doc.exists) {
        debugPrint('Documento do usuário não encontrado: ${user.uid}');
        return null;
      }

      return UserModel.fromSnap(doc);
    } on FirebaseException catch (e) {
      debugPrint('Erro Firestore: ${e.code}');
      debugPrint('Mensagem: ${e.message}');
      rethrow;
    }
  }

  Future<UserCredential> signInWithGitHub() async {
    final githubProvider = GithubAuthProvider();
    githubProvider.addScope('user:email');

    final UserCredential userCredential;

    if (kIsWeb) {
      userCredential = await _auth.signInWithPopup(githubProvider);
    } else {
      userCredential = await _auth.signInWithProvider(githubProvider);
    }

    final user = userCredential.user;

    if (user != null) {
      await _users.doc(user.uid).set({
        'uid': user.uid,
        'displayName': user.displayName ?? '',
        'email': user.email ?? '',
        'photoURL': user.photoURL ?? '',
      }, SetOptions(merge: true));
    }

    return userCredential;
  }

  CollectionReference<Map<String, dynamic>> _savedCats(String uid) {
    return _users.doc(uid).collection('savedCats');
  }

  /// URL fixa de um gato específico da Cataas (ao contrário de /cat, que
  /// sorteia um gato diferente a cada requisição).
  static String catImageUrl(String catId) => 'https://cataas.com/cat/$catId';

  User _requireUser(String action) {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('É necessário estar autenticado para $action.');
    }
    return user;
  }

  /// Guarda o ID do gato e as tags usadas para encontrá-lo no Firestore; a
  /// imagem continua hospedada na Cataas. O ID é usado como id do documento,
  /// então guardar o mesmo gato duas vezes não cria duplicatas: se ele já
  /// estiver na biblioteca, as tags novas são apenas somadas às existentes
  /// (sem apagar edições feitas pelo usuário).
  Future<void> saveCat(String catId, {List<String> tags = const []}) async {
    final user = _requireUser('guardar um gato');
    final reference = _savedCats(user.uid).doc(catId);

    final existing = await reference.get();
    if (existing.exists) {
      if (tags.isNotEmpty) {
        await reference.update({'tags': FieldValue.arrayUnion(tags)});
      }
      return;
    }

    await reference.set({
      'catId': catId,
      'imageUrl': catImageUrl(catId),
      'tags': tags,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Adiciona uma tag ao gato (arrayUnion ignora tags repetidas).
  Future<void> addTag(String catId, String tag) async {
    final user = _requireUser('editar as tags');
    await _savedCats(user.uid).doc(catId).update({
      'tags': FieldValue.arrayUnion([tag]),
    });
  }

  /// Remove uma tag do gato.
  Future<void> removeTag(String catId, String tag) async {
    final user = _requireUser('editar as tags');
    await _savedCats(user.uid).doc(catId).update({
      'tags': FieldValue.arrayRemove([tag]),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> savedCatsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('É necessário estar autenticado para acessar a biblioteca.');
    }

    return _savedCats(user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Exclui o gato da biblioteca. Se ele for o gato favorito, a foto de perfil
  /// também é removida, na mesma operação, para nunca apontar para um gato
  /// que já não existe.
  Future<void> deleteCat(String catId) async {
    final user = _requireUser('excluir um gato');
    final userReference = _users.doc(user.uid);

    final userSnapshot = await userReference.get();
    final isFavorite = userSnapshot.data()?['favoriteCatId'] == catId;

    final batch = FirebaseFirestore.instance.batch();
    batch.delete(_savedCats(user.uid).doc(catId));
    if (isFavorite) {
      batch.set(
        userReference,
        {'favoriteCatId': FieldValue.delete()},
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  /// ID do gato favorito do usuário (null se não houver). A foto de perfil é
  /// a imagem desse gato; guardamos só o ID, em um campo próprio, para o
  /// login com GitHub (que atualiza o photoURL) nunca sobrescrevê-lo.
  Stream<String?> favoriteCatIdStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _users.doc(user.uid).snapshots().map((snapshot) {
      final id = snapshot.data()?['favoriteCatId'];
      return id is String && id.isNotEmpty ? id : null;
    });
  }

  /// Marca o gato como favorito, tornando-o a foto de perfil. Só existe um
  /// favorito por vez: marcar outro substitui o anterior.
  Future<void> setFavoriteCat(String catId) async {
    final user = _requireUser('escolher um gato favorito');
    await _users.doc(user.uid).set(
      {'favoriteCatId': catId},
      SetOptions(merge: true),
    );
  }

  /// Remove o gato favorito (o perfil volta a mostrar o ícone padrão).
  Future<void> clearFavoriteCat() async {
    final user = _requireUser('remover o gato favorito');
    await _users.doc(user.uid).set(
      {'favoriteCatId': FieldValue.delete()},
      SetOptions(merge: true),
    );
  }
}

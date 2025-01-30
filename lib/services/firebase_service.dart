import 'dart:typed_data';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart' as models;
import '../constants/constants.dart';

class FirebaseService {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Authentication Methods
  Future<models.User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return await _getUserData(userCredential.user!.uid);
    } catch (e) {
      print('SignInWithEmail Error: $e');
      rethrow;
    }
  }

  Future<models.User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return await _getUserData(userCredential.user!.uid);
    } catch (e) {
      print('SignInWithGoogle Error: $e');
      rethrow;
    }
  }

  Future<models.User?> signUp(String email, String password) async {
    try {
      print('Starting SignUp Process...');

      // Step 1: Create Authentication User
      print('Creating Auth User...');
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        print('Error: Firebase User is null after creation');
        throw Exception('Failed to create user');
      }
      print('Auth User Created Successfully: ${firebaseUser.uid}');

      // Step 2: Create User Model
      print('Creating User Model...');
      final user = models.User(
        id: firebaseUser.uid,
        email: email,
        displayName: null,
        photoUrl: null,
        preferredCurrency: models.Currency.usd,
        isDarkMode: false,
        enableNotifications: true,
        createdAt: DateTime.now(),
        updatedAt: null,
        preferences: null,
      );

      // Step 3: Prepare User Data
      print('Preparing User Data...');
      final userData = {
        'email': email,
        'displayName': null,
        'photoUrl': null,
        'preferredCurrency': models.Currency.usd.toString(),
        'isDarkMode': false,
        'enableNotifications': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
        'preferences': null,
      };
      print('User Data Prepared: $userData');

      // Step 4: Save to Firestore
      print('Saving User Data to Firestore...');
      await _firestore.collection('users').doc(firebaseUser.uid).set(userData);
      print('User Data Saved Successfully');

      return user;
    } on auth.FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      print('SignUp Error: $e');
      print('SignUp Error Stack Trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      print('SignOut Error: $e');
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('ResetPassword Error: $e');
      rethrow;
    }
  }

  // User Data Methods
  Future<models.User?> _getUserData(String userId) async {
    try {
      print('Getting User Data for ID: $userId');
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        print('No User Document Found for ID: $userId');
        return null;
      }
      final data = doc.data()!;
      data['id'] = doc.id;
      print('User Data Retrieved: $data');
      return models.User.fromMap(data);
    } catch (e, stackTrace) {
      print('GetUserData Error: $e');
      print('GetUserData Stack Trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> updateUserData(models.User user) async {
    try {
      final userData = user.toMap();
      print('Updating User Data: $userData');
      await _firestore.collection('users').doc(user.id).update(userData);
      print('User Data Updated Successfully');
    } catch (e) {
      print('UpdateUserData Error: $e');
      throw Exception(AppConstants.genericError);
    }
  }

  // Storage Methods
  Future<String> uploadFile(String path, List<int> bytes) async {
    try {
      print('Starting File Upload: $path');
      final ref = _storage.ref().child(path);
      await ref.putData(Uint8List.fromList(bytes));
      final url = await ref.getDownloadURL();
      print('File Uploaded Successfully: $url');
      return url;
    } catch (e) {
      print('UploadFile Error: $e');
      throw Exception(AppConstants.genericError);
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      print('Deleting File: $path');
      await _storage.ref().child(path).delete();
      print('File Deleted Successfully');
    } catch (e) {
      print('DeleteFile Error: $e');
      throw Exception(AppConstants.genericError);
    }
  }

  // Firestore Collection References
  CollectionReference<Map<String, dynamic>> get usersRef =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get transactionsRef =>
      _firestore.collection('transactions');

  CollectionReference<Map<String, dynamic>> get budgetsRef =>
      _firestore.collection('budgets');

  CollectionReference<Map<String, dynamic>> get savingsGoalsRef =>
      _firestore.collection('savings_goals');

  // Current User
  models.User? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return models.User(
      id: user.uid,
      email: user.email!,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  bool get isAuthenticated => _auth.currentUser != null;

  Stream<models.User?> get userStream {
    return _auth.authStateChanges().asyncMap((user) {
      if (user == null) return null;
      return _getUserData(user.uid);
    });
  }

  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update Firebase Auth profile
      if (displayName != null) {
        await _auth.currentUser?.updateDisplayName(displayName);
        updates['displayName'] = displayName;
      }
      if (photoUrl != null) {
        await _auth.currentUser?.updatePhotoURL(photoUrl);
        updates['photoUrl'] = photoUrl;
      }

      // Update Firestore user document
      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Failed to update profile');
    }
  }

  Future<models.User?> getCurrentUser() async {
    try {
      print('Getting current user data');
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('No user is currently signed in');
        return null;
      }

      print('Fetching user data for ID: ${currentUser.uid}');
      final doc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!doc.exists) {
        print('No user document found for ID: ${currentUser.uid}');
        return null;
      }

      final data = doc.data()!;
      data['id'] = doc.id;
      print('User data retrieved successfully');
      return models.User.fromMap(data);
    } catch (e) {
      print('Error getting current user: $e');
      throw Exception('Failed to get current user: $e');
    }
  }

  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      // Check if user is authenticated
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated to upload profile image');
      }

      // Ensure the user is uploading their own profile image
      if (currentUser.uid != userId) {
        throw Exception(
            'Unauthorized to upload profile image for another user');
      }

      // Create a reference to the image location in Firebase Storage
      final ref = _storage.ref().child('users/$userId/profile.jpg');

      // Create upload metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Upload the file with metadata
      await ref.putFile(imageFile, metadata);

      // Get the download URL
      final downloadUrl = await ref.getDownloadURL();

      // Update Firestore user document
      await _firestore.collection('users').doc(userId).update({
        'photoUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update Auth profile
      await currentUser.updatePhotoURL(downloadUrl);

      return downloadUrl;
    } on FirebaseException catch (e) {
      print('Firebase Error uploading profile image: ${e.code} - ${e.message}');
      if (e.code == 'unauthorized') {
        throw Exception(
            'You are not authorized to upload profile images. Please check your Firebase Storage rules.');
      }
      throw Exception('Failed to upload profile image: ${e.message}');
    } catch (e) {
      print('Error uploading profile image: $e');
      throw Exception('Failed to upload profile image. Please try again.');
    }
  }
}

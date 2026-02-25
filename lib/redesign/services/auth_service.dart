import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:politicsstatements/redesign/resources/models/user.dart';
import 'package:politicsstatements/redesign/resources/prefs.dart';
import 'package:politicsstatements/redesign/resources/repository.dart';
import 'package:politicsstatements/redesign/utils/utils.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;

  AuthService._internal();

  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  GoogleSignIn? _googleSignIn;
  bool _isInitialized = false;

  final _adminStatusController = StreamController<bool>.broadcast();
  Stream<bool> get adminStatusStream => _adminStatusController.stream;
  
  bool _currentAdminStatus = false;
  bool get currentAdminStatus => _currentAdminStatus;

  // Initialize the service
  void initialize() {
    if (_isInitialized) return; // Prevent multiple initializations

    if (kDebugMode) {
      print('AuthService: Initializing authentication service...');
    }

    if (!kIsWeb) {
      _googleSignIn = GoogleSignIn();
    }
    
    // Initialize current admin status from stored preferences
    _currentAdminStatus = isAdminUser;
    if (kDebugMode) {
      print('AuthService: Initialized currentAdminStatus from storage: $_currentAdminStatus');
    }
    
    // Set up the auth state listener
    _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);

    // Also check current user immediately if already signed in
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser != null) {
      if (kDebugMode) {
        print('AuthService: Found existing logged-in user: ${currentUser.email}');
      }
      _onAuthStateChanged(currentUser);
    } else {
      if (kDebugMode) {
        print('AuthService: No logged-in user found');
      }
    }

    _isInitialized = true;
  }

  // Handle auth state changes
  void _onAuthStateChanged(firebase_auth.User? firebaseUser) async {
    if (firebaseUser != null) {
      // User is signed in
      if (kDebugMode) {
        print('AuthService: Processing user authentication for: ${firebaseUser.email}');
      }
      try {
        // Try to get user from backend via repository
        try {
          user = await repository.getUserByFirebaseUid(firebaseUser.uid);
        } catch (e) {
          user = null;
        }
        if (user == null) {
          user = User.fromFirebaseUser(
            firebaseUser.uid,
            firebaseUser.displayName,
            firebaseUser.email,
            firebaseUser.photoURL,
          );
          user?.isAdmin = await _checkIfAdminUser(firebaseUser.email);
          user = await repository.createUser(user);
        }

        // Check if user is admin based on email
        bool isAdmin = await _checkIfAdminUser(firebaseUser.email);

        if (kDebugMode) {
          print('AuthService: Admin check complete for ${firebaseUser.email}: isAdmin=$isAdmin');
        }

        // Update admin status if needed
        if (user?.isAdmin != isAdmin) {
          user = user?.copyWith(isAdmin: isAdmin);
          // Optionally update in backend here if needed
        }

        // Update local preferences
        saveLoginState(true);
        saveAdminUser(isAdmin);
        saveCurrentUser(
          user?.id ?? firebaseUser.uid,
          user?.name ?? firebaseUser.displayName ?? 'User',
          user?.email ?? firebaseUser.email ?? '',
          user?.photoUrl ?? firebaseUser.photoURL ?? '',
        );
        _currentAdminStatus = isAdmin;
        _adminStatusController.add(isAdmin);
        
        if (kDebugMode) {
          print('AuthService: Admin mode ${isAdmin ? "ENABLED" : "DISABLED"}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('AuthService: Error processing user authentication: $e');
        }
      }
    } else {
      // User is signed out
      if (kDebugMode) {
        print('AuthService: User signed out, clearing admin mode');
      }
      clearUserData();
      _currentAdminStatus = false;
      _adminStatusController.add(false);
    }
  }

  // Check if user is admin based on email
  Future<bool> _checkIfAdminUser(String? email) async {
    if (email == null) {
      if (kDebugMode) {
        print('AuthService: _checkIfAdminUser - email is null');
      }
      return false;
    }

    try {
      if (kDebugMode) {
        print('AuthService: Fetching admin emails from Firestore for email: $email');
      }
      List<String> adminEmails = await repository.getAdminUsers();
      if (kDebugMode) {
        print('AuthService: Admin emails from Firestore: $adminEmails');
      }
      final normalizedEmail = email.toLowerCase().trim();
      final isAdmin = adminEmails.contains(normalizedEmail);
      if (kDebugMode) {
        print('AuthService: Checking if "$normalizedEmail" is in admin list: $isAdmin');
      }
      return isAdmin;
    } catch (e) {
      if (kDebugMode) {
        print('AuthService: Error checking admin status: $e');
      }
      // Fallback to hardcoded check if Firestore fails
      final fallbackCheck = email.toLowerCase() == 'superdevelopersuper@gmail.com';
      if (kDebugMode) {
        print('AuthService: Using fallback check for $email: $fallbackCheck');
      }
      return fallbackCheck;
    }
  }

  // Check what sign-in methods are available for an email
  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    try {
      return await _firebaseAuth.fetchSignInMethodsForEmail(email);
    } catch (e) {
      return [];
    }
  }

  // Check if an email has multiple sign-in methods available
  Future<Map<String, dynamic>> getEmailSignInStatus(String email) async {
    try {
      final methods = await fetchSignInMethodsForEmail(email);

      return {
        'hasAccount': methods.isNotEmpty,
        'methods': methods,
        'hasEmailPassword': methods.contains(firebase_auth.EmailAuthProvider.PROVIDER_ID),
        'hasGoogle': methods.contains(firebase_auth.GoogleAuthProvider.PROVIDER_ID),
        'canLinkGoogle':
            methods.contains(firebase_auth.EmailAuthProvider.PROVIDER_ID) && !methods.contains(firebase_auth.GoogleAuthProvider.PROVIDER_ID),
      };
    } catch (e) {
      return {
        'hasAccount': false,
        'methods': <String>[],
        'hasEmailPassword': false,
        'hasGoogle': false,
        'canLinkGoogle': false,
      };
    }
  }

  // Sign in with Google - Enhanced with account linking
  Future<bool> signInWithGoogle() async {
    try {
      final googleProvider = firebase_auth.GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      firebase_auth.UserCredential credential;

      if (kIsWeb) {
        // For web, use Firebase Auth popup
        credential = await _firebaseAuth.signInWithPopup(googleProvider);
      } else {
        // For mobile platforms (Android/iOS), use google_sign_in package
        final GoogleSignInAccount? googleUser = await _googleSignIn?.signIn();
        if (googleUser == null) {
          // User cancelled the sign-in
          throw firebase_auth.FirebaseAuthException(
            code: 'sign-in-cancelled',
            message: 'Google sign-in was cancelled.',
          );
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final firebase_auth.AuthCredential authCredential = firebase_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        credential = await _firebaseAuth.signInWithCredential(authCredential);
      }

      if (credential.user != null) {
        // Show success message
        showToast("Բարեհաջող մուտք!");
        return true;
      }
      throw firebase_auth.FirebaseAuthException(
        code: 'sign-in-failed',
        message: 'Google-ով մուտքը ձախողվեց: Խնդրում ենք նորից փորձել:',
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Handle specific error for account exists with different credential
      if (e.code == 'account-exists-with-different-credential') {
        // This means there's already an account with this email using a different sign-in method
        throw firebase_auth.FirebaseAuthException(
          code: 'account-exists-with-different-credential',
          message:
              'Այս էլ․ փոստով հաշիվ գոյություն ունի: Խնդրում ենք նախ մուտք գործել ձեր էլ․ փոստով և գաղտնաբառով, այնուհետև կապակցել ձեր Google հաշիվը կարգավորումներում:',
        );
      }
      throw e;
    } catch (e, stackTrace) {
      // Wrap other exceptions in FirebaseAuthException for consistent handling
      throw firebase_auth.FirebaseAuthException(
        code: 'unknown-error',
        message: 'Google-ով մուտքի ժամանակ անսպասելի սխալ տեղի ունեցավ: ${e.toString()}',
      );
    }
  }

  // Link Google account to existing email/password account
  Future<bool> linkGoogleAccount() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw firebase_auth.FirebaseAuthException(
          code: 'no-current-user',
          message: 'You must be signed in to link a Google account.',
        );
      }

      final googleProvider = firebase_auth.GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      firebase_auth.AuthCredential googleCredential;

      if (kIsWeb) {
        // For web, use Firebase Auth popup
        final result = await _firebaseAuth.signInWithPopup(googleProvider);
        if (result.credential == null) {
          throw firebase_auth.FirebaseAuthException(
            code: 'credential-not-found',
            message: 'Failed to get Google credentials.',
          );
        }
        googleCredential = result.credential!;
      } else {
        // For mobile platforms (Android/iOS), use google_sign_in package
        final GoogleSignInAccount? googleUser = await _googleSignIn?.signIn();
        if (googleUser == null) {
          // User cancelled the sign-in
          throw firebase_auth.FirebaseAuthException(
            code: 'sign-in-cancelled',
            message: 'Google sign-in was cancelled.',
          );
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        googleCredential = firebase_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
      }

      // Link the Google credential to the current user
      await currentUser.linkWithCredential(googleCredential);

      showToast("Google հաշիվը հաջողությամբ կապակցվեց!");
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked') {
        throw firebase_auth.FirebaseAuthException(
          code: 'provider-already-linked',
          message: 'Google account is already linked to this account.',
        );
      } else if (e.code == 'credential-already-in-use') {
        throw firebase_auth.FirebaseAuthException(
          code: 'credential-already-in-use',
          message: 'This Google account is already linked to another user account.',
        );
      }
      throw e;
    } catch (e) {
      throw firebase_auth.FirebaseAuthException(
        code: 'unknown-error',
        message: 'An unexpected error occurred while linking Google account: ${e.toString()}',
      );
    }
  }

  // Unlink Google account from current user
  Future<bool> unlinkGoogleAccount() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw firebase_auth.FirebaseAuthException(
          code: 'no-current-user',
          message: 'You must be signed in to unlink a Google account.',
        );
      }

      await currentUser.unlink(firebase_auth.GoogleAuthProvider.PROVIDER_ID);
      showToast("Google հաշիվը հաջողությամբ անջատվեց!");
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'no-such-provider') {
        throw firebase_auth.FirebaseAuthException(
          code: 'no-such-provider',
          message: 'Google account is not linked to this account.',
        );
      }
      throw e;
    } catch (e) {
      throw firebase_auth.FirebaseAuthException(
        code: 'unknown-error',
        message: 'An unexpected error occurred while unlinking Google account: ${e.toString()}',
      );
    }
  }

  // Get linked providers for current user
  List<String> getLinkedProviders() {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) return [];

    return currentUser.providerData.map((provider) => provider.providerId).toList();
  }

  // Check if Google is linked to current account
  bool isGoogleLinked() {
    return getLinkedProviders().contains(firebase_auth.GoogleAuthProvider.PROVIDER_ID);
  }

  // Check if email/password is linked to current account
  bool isEmailPasswordLinked() {
    return getLinkedProviders().contains(firebase_auth.EmailAuthProvider.PROVIDER_ID);
  }

  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Show success message
        showToast("Բարեհաջող մուտք!");
        return true;
      }
      throw firebase_auth.FirebaseAuthException(
        code: 'sign-in-failed',
        message: 'Failed to sign in. Please check your credentials.',
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Re-throw the exception so the UI can handle it properly
      throw e;
    } catch (e, stackTrace) {
      // Wrap other exceptions in FirebaseAuthException for consistent handling
      throw firebase_auth.FirebaseAuthException(
        code: 'unknown-error',
        message: 'An unexpected error occurred during sign-in: ${e.toString()}',
      );
    }
  }

  // Create account with email and password - Enhanced with conflict detection
  Future<bool> createAccountWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      // First check if an account already exists with this email
      final signInMethods = await fetchSignInMethodsForEmail(email);
      if (signInMethods.isNotEmpty) {
        // Account exists with different sign-in method
        String methodsText = signInMethods.join(', ');
        throw firebase_auth.FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'An account with this email already exists using: $methodsText. Please sign in with the existing method or use a different email.',
        );
      }

      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name
        try {
          await credential.user!.updateDisplayName(displayName);
        } catch (e) {
          // Handle error silently - not critical for account creation
        }

        // Show success message
        showToast("Հաշիվը հաջողությամբ ստեղծվեց!");
        return true;
      }
      throw firebase_auth.FirebaseAuthException(
        code: 'account-creation-failed',
        message: 'Failed to create account. Please try again.',
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Re-throw the exception so the UI can handle it properly
      throw e;
    } catch (e, stackTrace) {
      // Wrap other exceptions in FirebaseAuthException for consistent handling
      throw firebase_auth.FirebaseAuthException(
        code: 'unknown-error',
        message: 'An unexpected error occurred during account creation: ${e.toString()}',
      );
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      // First check if an account exists with this email
      final signInMethods = await fetchSignInMethodsForEmail(email);
      if (signInMethods.isEmpty) {
        throw firebase_auth.FirebaseAuthException(
          code: 'user-not-found',
          message: 'No account found with this email address. Please check your email or create a new account.',
        );
      }

      // Check if the account has email/password sign-in enabled
      if (!signInMethods.contains(firebase_auth.EmailAuthProvider.PROVIDER_ID)) {
        String availableMethods = signInMethods.join(', ');
        throw firebase_auth.FirebaseAuthException(
          code: 'invalid-sign-in-method',
          message: 'This email is registered with: $availableMethods. Password reset is only available for email/password accounts.',
        );
      }

      await _firebaseAuth.sendPasswordResetEmail(email: email);
      showToast("Գաղտնաբառի վերականգնման նամակը ուղարկվեց!");
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw firebase_auth.FirebaseAuthException(
        code: 'unknown-error',
        message: 'An unexpected error occurred while sending password reset email: ${e.toString()}',
      );
    }
  }

  // Change password for current user
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw firebase_auth.FirebaseAuthException(
          code: 'no-current-user',
          message: 'You must be signed in to change your password.',
        );
      }

      if (currentUser.email == null) {
        throw firebase_auth.FirebaseAuthException(
          code: 'no-email',
          message: 'No email associated with this account.',
        );
      }

      // Re-authenticate the user with current password
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: currentUser.email!,
        password: currentPassword,
      );

      await currentUser.reauthenticateWithCredential(credential);

      // Update password
      await currentUser.updatePassword(newPassword);

      showToast("Գաղտնաբառը հաջողությամբ փոխվեց!");
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw firebase_auth.FirebaseAuthException(
          code: 'wrong-password',
          message: 'Current password is incorrect.',
        );
      } else if (e.code == 'weak-password') {
        throw firebase_auth.FirebaseAuthException(
          code: 'weak-password',
          message: 'New password is too weak. Please use at least 6 characters with a mix of letters and numbers.',
        );
      } else if (e.code == 'requires-recent-login') {
        throw firebase_auth.FirebaseAuthException(
          code: 'requires-recent-login',
          message: 'Please sign out and sign in again before changing your password.',
        );
      }
      throw e;
    } catch (e) {
      throw firebase_auth.FirebaseAuthException(
        code: 'unknown-error',
        message: 'An unexpected error occurred while changing password: ${e.toString()}',
      );
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      // Also sign out from Google if signed in
      if (!kIsWeb) {
        await _googleSignIn?.signOut();
      }
      showToast("Բարեհաջող ելք!");
    } catch (e) {
      // Handle error silently
    }
  }

  // Update user in backend (delegates to repository)
  Future<User?> updateUserInBackend(User user) async {
    return await repository.updateUser(user);
  }

  // Get auth error message
  String getAuthErrorMessage(dynamic error) {
    if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        // Email/Password specific errors
        case 'user-not-found':
          return 'Այս էլ․ փոստի հասցեով հաշիվ չի գտնվել: Խնդրում ենք ստուգել ձեր էլ․ փոստը կամ ստեղծել նոր հաշիվ:';
        case 'wrong-password':
          return 'Սխալ գաղտնաբառ: Խնդրում ենք նորից փորձել կամ վերականգնել ձեր գաղտնաբառը:';
        case 'invalid-credential':
          return 'Սխալ էլ․ փոստ կամ գաղտնաբառ: Խնդրում ענք ստուգել ձեր տվյալները և նորից փորձել:';
        case 'invalid-email':
          return 'Խնդրում ենք մուտքագրել վավեր էլ․ փոստի հասցե:';
        case 'user-disabled':
          return 'Այս հաշիվը փակվել է: Խնդրում ենք դիմել աջակցման ծառայությանը:';

        // Account creation errors
        case 'email-already-in-use':
          return error.message ?? 'Այս էլ․ փոստով հաշիվ արդեն գոյություն ունի: Խնդրում ենք մուտք գործել կամ օգտագործել այլ էլ․ փոստ:';
        case 'weak-password':
          return 'Գաղտնաբառը չափազանց թույլ է: Խնդրում ենք օգտագործել առնվազն 6 նիշ՝ տառերի և թվերի համակցությամբ:';

        // Network and system errors
        case 'network-request-failed':
          return 'Ցանցային սխալ: Խնդրում ենք ստուգել ձեր ինտերնետ կապը և նորից փորձել:';
        case 'too-many-requests':
          return 'Չափազանց շատ ձախողված փորձեր: Խնդրում ենք սպասել մի քանի րոպե և նորից փորձել:';

        // Operation errors
        case 'operation-not-allowed':
          return 'Այս մուտքի եղանակը միացված չէ: Խնդրում ենք դիմել աջակցության:';
        case 'requires-recent-login':
          return 'Խնդրում ենք դուրս գալ և նորից մուտք գործել այս գործողությունը կատարելու համար:';

        // Google Sign-In specific errors
        case 'account-exists-with-different-credential':
          return error.message ??
              'Այս էլ․ փոստով հաշիվ գոյություն ունի այլ մուտքի եղանակով: Խնդրում ենք փորձել մուտք գործել էլ․ փոստ/գաղտնաբառով կամ բնօրինակ եղանակով:';
        case 'sign-in-cancelled':
          return 'Google մուտքը չեղարկվեց:';
        case 'popup-closed-by-user':
          return 'Մուտքը չեղարկվեց: Խնդրում ենք նորից փորձել:';
        case 'popup-blocked':
          return 'Popup-ը արգելափակվել է ձեր դիտարկիչի կողմից: Խնդրում ենք թույլատրել popup-ները այս կայքի համար և նորից փորձել:';
        case 'cancelled-popup-request':
          return 'Մուտքը չեղարկվեց: Խնդրում ենք նորից փորձել:';
        case 'unauthorized-domain':
          return 'Այս տիրույթը թույլատրված չէ մուտքի համար: Խնդրում ենք դիմել աջակցության:';

        // Account linking errors
        case 'provider-already-linked':
          return 'Google հաշիվը արդեն կապված է այս հաշվի հետ:';
        case 'credential-already-in-use':
          return 'Այս Google հաշիվը արդեն կապված է այլ օգտվողի հաշվի հետ:';
        case 'no-such-provider':
          return 'Google հաշիվը կապված չէ այս հաշվի հետ:';
        case 'credential-not-found':
          return 'Չհաջողվեց ստանալ իսկորոշման տվյալները: Խնդրում ենք նորից փորձել:';
        case 'no-current-user':
          return 'Դուք պետք է մուտք գործած լինեք այս գործողությունը կատարելու համար:';
        case 'no-email':
          return 'Էլ․ փոստ չի կապակցված այս հաշվի հետ:';
        case 'invalid-sign-in-method':
          return error.message ?? 'Սխալ մուտքի եղանակ այս գործողության համար:';

        // Token and session errors
        case 'invalid-user-token':
        case 'user-token-expired':
          return 'Ձեր նիստն ավարտվել է: Խնդրում ենք նորից մուտք գործել:';
        case 'invalid-api-key':
          return 'Կարգավորման սխալ: Խնդրում ենք դիմել աջակցության:';

        // Custom error codes from our service
        case 'sign-in-failed':
        case 'account-creation-failed':
        case 'unknown-error':
          return error.message ?? 'Սխալ տեղի ունեցավ իսկորոշման ժամանակ:';

        default:
          // Return the original Firebase error message if available, otherwise a generic message
          return error.message ?? 'Իսկորոշման սխալ տեղի ունեցավ: Խնդրում ենք նորից փորձել:';
      }
    }
    return 'Չսպասված սխալ տեղի ունեցավ իսկորոշման ժամանակ: Խնդրում ենք նորից փորձել:';
  }
}

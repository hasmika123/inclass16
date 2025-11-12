import 'dart:async';
import 'package:flutter/material.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import 'services/auth_service.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'firebase_options.dart'; 
 
 
void main() async { 
  WidgetsFlutterBinding.ensureInitialized(); 
  await Firebase.initializeApp( 
    options: DefaultFirebaseOptions.currentPlatform, 
  ); 
 
  runApp(MyApp()); 
} 
 
class MyApp extends StatelessWidget { 
  @override 
  Widget build(BuildContext context) { 
    return MaterialApp( 
      title: 'Firebase Auth Demo', 
      home: MyHomePage(title: 'Firebase Auth Demo'), 
    ); 
  } 
} 
 
class MyHomePage extends StatefulWidget { 
  MyHomePage({Key? key, required this.title}) : super(key: key); 
  final String title; 
 
  @override 
  _MyHomePageState createState() => _MyHomePageState(); 
} 
 
class _MyHomePageState extends State<MyHomePage> { 
  final AuthService _authService = AuthService();
  StreamSubscription<User?>? _authSub;
 
  void _signOut() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
  await _authService.signOut();
    // Trigger a rebuild so UI reflects auth change.
    if (mounted) setState(() {});
    // Navigate back to the login screen and clear navigation history so
    // the user can't press back to return to a protected screen.
    if (!mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MyHomePage(title: widget.title)),
      (route) => false,
    );
    messenger.showSnackBar(const SnackBar(
      content: Text('Signed out successfully'),
    ));
  }

  @override
  void initState() {
    super.initState();
    // Listen to auth state changes and rebuild when they occur so the UI
    // always reflects the current authentication state.
    _authSub = _authService.authStateChanges().listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
 
  @override 
  Widget build(BuildContext context) { 
    return Scaffold( 
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          if (_authService.currentUser != null) ...[
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: 'Profile',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ProfileScreen(authService: _authService)),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign Out',
              onPressed: _signOut,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: <Widget>[
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: RegisterEmailSection(authService: _authService),
              ),
            ),
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: EmailPasswordForm(authService: _authService),
              ),
            ),
          ],
        ),
      ),
    ); 
  } 
} 
 
class RegisterEmailSection extends StatefulWidget { 
  RegisterEmailSection({Key? key, required this.authService}) : super(key: key); 
  final AuthService authService; 
 
  @override 
  _RegisterEmailSectionState createState() => _RegisterEmailSectionState(); 
} 
 
class _RegisterEmailSectionState extends State<RegisterEmailSection> { 
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); 
  final TextEditingController _emailController = TextEditingController(); 
  final TextEditingController _passwordController = TextEditingController(); 
  bool _success = false; 
  bool _initialState = true; 
  String? _userEmail; 
  String? _statusMessage;
 
  void _register() async { 
    setState(() {
      _statusMessage = null;
    });
    try {
      await widget.authService.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      setState(() {
        _success = true;
        _userEmail = _emailController.text;
        _initialState = false;
        _statusMessage = 'Successfully registered ${_userEmail ?? ''}';
      });
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'That email is already in use.';
          break;
        case 'invalid-email':
          msg = 'That email address is invalid.';
          break;
        case 'weak-password':
          msg = 'The password is too weak.';
          break;
        default:
          msg = 'Registration failed: ${e.message ?? e.code}';
      }
      setState(() {
        _success = false;
        _initialState = false;
        _statusMessage = msg;
      });
    } catch (e) {
      setState(() {
        _success = false;
        _initialState = false;
        _statusMessage = 'Registration failed: ${e.toString()}';
      });
    }
  } 
 
  @override 
  Widget build(BuildContext context) { 
    return Form( 
      key: _formKey, 
      child: Column( 
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: <Widget>[ 
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (value) {
              final v = value ?? '';
              if (v.isEmpty) return 'Please enter an email';
              if (!v.contains('@')) return 'Please enter a valid email';
              return null;
            },
          ),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
            validator: (value) {
              final v = value ?? '';
              if (v.isEmpty) return 'Please enter a password';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          Container( 
            padding: const EdgeInsets.symmetric(vertical: 16.0), 
            alignment: Alignment.center, 
            child: ElevatedButton( 
              onPressed: () { 
                if (_formKey.currentState!.validate()) { 
                  _register(); 
                } 
              }, 
              child: Text('Submit'), 
            ), 
          ), 
          Container(
            alignment: Alignment.center,
            child: Text(
              _statusMessage ??
                  (_initialState
                      ? 'Please Register'
                      : _success
                          ? 'Successfully registered ${_userEmail ?? ''}'
                          : 'Registration failed'),
              style: TextStyle(color: (_statusMessage != null && _statusMessage!.toLowerCase().contains('success')) ? Colors.green : (_success ? Colors.green : Colors.red)),
            ),
          ),
        ], 
      ), 
    ); 
  } 
} 
 
class EmailPasswordForm extends StatefulWidget { 
  EmailPasswordForm({Key? key, required this.authService}) : super(key: key); 
  final AuthService authService; 
 
  @override 
  _EmailPasswordFormState createState() => _EmailPasswordFormState(); 
} 
 
class _EmailPasswordFormState extends State<EmailPasswordForm> { 
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); 
  final TextEditingController _emailController = TextEditingController(); 
  final TextEditingController _passwordController = TextEditingController(); 
  bool _success = false; 
  bool _initialState = true; 
  String _userEmail =''; 
  String? _statusMessage;
 
  void _signInWithEmailAndPassword() async { 
    setState(() {
      _statusMessage = null;
    });
    try {
      await widget.authService.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      setState(() {
        _success = true;
        _userEmail = _emailController.text;
        _initialState = false;
        _statusMessage = 'Successfully signed in $_userEmail';
      });
      // After a successful sign-in, push the ProfileScreen onto the stack.
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProfileScreen(authService: widget.authService)),
      );
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'wrong-password':
          msg = 'Incorrect password.';
          break;
        case 'user-not-found':
          msg = 'No user found for that email.';
          break;
        case 'invalid-email':
          msg = 'The email address is invalid.';
          break;
        default:
          msg = 'Sign in failed: ${e.message ?? e.code}';
      }
      setState(() {
        _success = false;
        _initialState = false;
        _statusMessage = msg;
      });
    } catch (e) {
      setState(() {
        _success = false;
        _initialState = false;
        _statusMessage = 'Sign in failed: ${e.toString()}';
      });
    }
  } 
 
  @override 
  Widget build(BuildContext context) { 
    return Form( 
      key: _formKey, 
      child: Column( 
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: <Widget>[ 
          Container( 
            child: Text('Test sign in with email and password'), 
            padding: const EdgeInsets.all(16), 
            alignment: Alignment.center, 
          ), 
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (value) {
              final v = value ?? '';
              if (v.isEmpty) return 'Please enter an email';
              if (!v.contains('@')) return 'Please enter a valid email';
              return null;
            },
          ),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
            validator: (value) {
              final v = value ?? '';
              if (v.isEmpty) return 'Please enter a password';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          Container( 
            padding: const EdgeInsets.symmetric(vertical: 16.0), 
            alignment: Alignment.center, 
            child: ElevatedButton( 
              onPressed: () { 
                if (_formKey.currentState!.validate()) { 
                  _signInWithEmailAndPassword(); 
                } 
              }, 
              child: Text('Submit'), 
            ), 
          ), 
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _statusMessage ??
                  (_initialState ? 'Please sign in' : _success ? 'Successfully signed in $_userEmail' : 'Sign in failed'),
              style: TextStyle(color: (_statusMessage != null && _statusMessage!.toLowerCase().contains('success')) ? Colors.green : (_success ? Colors.green : Colors.red)),
            ),
          ),
        ], 
      ), 
    ); 
  } 
}

class ProfileScreen extends StatefulWidget {
  ProfileScreen({Key? key, required this.authService}) : super(key: key);
  final AuthService authService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _currentUser;
  final TextEditingController _passwordController = TextEditingController();
  bool _updating = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.authService.currentUser;
  }

  Future<void> _updatePassword() async {
    final newPassword = _passwordController.text.trim();
    if (newPassword.length < 6) {
      setState(() => _statusMessage = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _updating = true;
      _statusMessage = null;
    });

    try {
      await widget.authService.updatePassword(newPassword);
      setState(() {
        _statusMessage = 'Password updated successfully.';
      });
    } catch (e) {
      if (e is FirebaseAuthException) {
        String msg;
        switch (e.code) {
          case 'weak-password':
            msg = 'The new password is too weak.';
            break;
          case 'requires-recent-login':
            msg = 'Please re-authenticate and try again.';
            break;
          default:
            msg = 'Failed to update password: ${e.message ?? e.code}';
        }
        setState(() {
          _statusMessage = msg;
        });
      } else {
        setState(() {
          _statusMessage = 'Failed to update password: ${e.toString()}';
        });
      }
    } finally {
      setState(() {
        _updating = false;
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              final navigator = Navigator.of(context);
              await widget.authService.signOut();
              if (!mounted) return;
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => MyHomePage(title: 'Firebase Auth Demo')),
                (route) => false,
              );
            },
          )
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          child: Text(
                            (_currentUser?.email?.isNotEmpty ?? false)
                                ? _currentUser!.email![0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(_currentUser?.email ?? '(not available)', style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                                    TextField(
                                      controller: _passwordController,
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                        labelText: 'New password',
                                        hintText: 'Enter new password (min 6 chars)',
                                      ),
                                    ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _updating ? null : _updatePassword,
                            child: _updating
                                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Update Password'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_statusMessage != null)
                          Text(
                            _statusMessage!,
                            style: TextStyle(color: _statusMessage!.contains('success') ? Colors.green : Colors.red),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
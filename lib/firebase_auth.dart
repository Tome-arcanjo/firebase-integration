import 'package:firebase_auth/firebase_auth.dart';

// Cadastro
Future<void> registrar(String email, String password) async {
  await FirebaseAuth.instance.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );
}

// Login
Future<void> logar(String email, String password) async {
  await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
}

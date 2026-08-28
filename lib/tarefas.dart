import 'package:cloud_firestore/cloud_firestore.dart';

final CollectionReference tarefas = FirebaseFirestore.instance.collection(
  'tarefas',
);

// CREATE: Adicionar documento
Future<void> adicionarTarefa(String titulo) async {
  await tarefas.add({
    'titulo': titulo,
    'concluida': false,
    'timestamp': FieldValue.serverTimestamp(),
  });
}

// READ: Consultar com Stream (Tempo Real)
Stream<QuerySnapshot> lerTarefasEmTempoReal() {
  return tarefas.orderBy('timestamp').snapshots();
}

// UPDATE: Editar campos de um documento
Future<void> atualizarTarefa(String id, bool status) async {
  await tarefas.doc(id).update({'concluida': status});
}

// DELETE: Remover documento
Future<void> deletarTarefa(String id) async {
  await tarefas.doc(id).delete();
}

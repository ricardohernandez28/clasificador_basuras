import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;

Future<List> getQuestions() async {
  List questions = [];
  await firestore.collection('canecas').get().then((querySnapshot) {
    for (var result in querySnapshot.docs) {
      questions.add(result.data());
    }
  });
  return questions;
}

import 'dart:async';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:clasificador_basuras/result_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

// ignore: must_be_immutable
class SpeechScreen extends StatefulWidget {
  const SpeechScreen({super.key});

  @override
  State<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  SpeechToText speechToText = SpeechToText();
  var text = 'Presione el boton para comenzar a hablar';
  var isListening = false;
  bool isLoading = false;

  // @override
  // void dispose() {
  //   speechToText.stop();
  //   timer?.cancel(); // Cancela el temporizador si aún está activo
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AvatarGlow(
        endRadius: 75.0,
        animate: isListening,
        duration: const Duration(milliseconds: 4000),
        repeat: true,
        repeatPauseDuration: const Duration(milliseconds: 50),
        showTwoGlows: true,
        glowColor: Colors.greenAccent[700]!,
        child: GestureDetector(
          onTapDown: (details) async {
            if (!isListening && !isLoading) {
              var available = await speechToText.initialize();
              if (available) {
                setState(() {
                  isListening = true;
                  isLoading = true;
                  speechToText.listen(onResult: (result) {
                    setState(() {
                      text = result.recognizedWords;
                    });
                  });
                });
                await Future.delayed(const Duration(seconds: 4));

                setState(() {
                  isListening = false;
                  isLoading = false;
                  speechToText.stop();
                });
                // });
                try {
                  final String result = await consulta();
                  setState(() {
                    text = "$text $result";
                  });
                  await Future.delayed(const Duration(seconds: 4));
                  setState(() {
                    text = 'Presione el boton para comenzar a hablar';
                  });
                } catch (e) {
                  print(e);
                  // No se necesita hacer nada aquí
                }
              }
            }
          },
          child: CircleAvatar(
            backgroundColor: isLoading ? Colors.grey : Colors.greenAccent[700],
            radius: 35,
            // ignore: dead_code
            child: Icon(isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white),
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.greenAccent[400],
        leading: const Icon(Icons.restore_from_trash_outlined),
        toolbarHeight: 80.0,
        title: const Text(
          "Clasificador de desechos",
          style: TextStyle(fontWeight: FontWeight.w300, color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(45.0),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w800,
                fontSize: 34.0),
          ),
        ),
      ),
    );
  }

  Future<String> consulta() async {
    final canecas = FirebaseFirestore.instance.collection('desechos');

    final query = canecas.where('nombre', isEqualTo: text);
    final snapshot = await query.get();
    String clasificacion = "";
    if (snapshot.docs.isEmpty) {
      clasificacion = "No se encontro el desecho";
    } else {
      for (var doc in snapshot.docs) {
        // ignore: prefer_interpolation_to_compose_strings
        clasificacion = "va en la caneca " + doc['caneca'];
      }
    }
    return clasificacion;
  }
}

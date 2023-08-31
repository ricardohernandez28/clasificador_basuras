import 'dart:async';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechScreen extends StatefulWidget {
  const SpeechScreen({Key? key}) : super(key: key);

  @override
  State<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  SpeechToText speechToText = SpeechToText();
  var text = 'Presione el boton para comenzar a hablar';
  var isListening = false;
  Timer? timer;

  Timer? agradecimiento;

  @override
  void dispose() {
    speechToText.stop();
    timer?.cancel(); // Cancela el temporizador si aún está activo
    super.dispose();
  }

  Future<String> _buscarDesecho(String nombre) async {
    final canecas = FirebaseFirestore.instance.collection('desechos');
    final query = canecas.where('nombre', isEqualTo: nombre);
    final snapshot = await query.get();
    if (snapshot.docs.isEmpty) {
      return "No se encontro el desecho";
    } else {
      final doc = snapshot.docs.first;
      return "va en la caneca ${doc['caneca']}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AvatarGlow(
        endRadius: 75.0,
        animate: isListening,
        duration: const Duration(milliseconds: 4000),
        repeat: true,
        repeatPauseDuration: const Duration(milliseconds: 100),
        showTwoGlows: true,
        glowColor: Colors.redAccent,
        child: GestureDetector(
          onTapDown: (details) async {
            if (!isListening) {
              var available = await speechToText.initialize();
              if (available) {
                setState(() {
                  isListening = true;
                  speechToText.listen(onResult: (result) {
                    setState(() {
                      text = result.recognizedWords;
                    });
                  });
                });

                timer = Timer(const Duration(seconds: 4), () async {
                  setState(() {
                    isListening = false;
                    speechToText.stop();
                  });

                  try {
                    final clasificacion = await _buscarDesecho(text);
                    setState(() {
                      text = "$text $clasificacion";
                    });
                  } catch (e) {
                    setState(() {
                      text = "No se encontro el desecho";
                    });
                  }

                  agradecimiento = Timer(const Duration(seconds: 4), () {
                    setState(() {
                      text = "Muchas gracias por clasificar los desechos";
                    });
                  });
                });
              }
            }
          },
          child: CircleAvatar(
            backgroundColor: Colors.redAccent,
            radius: 35,
            child: Icon(isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white),
          ),
        ),
      ),
      appBar: AppBar(
        leading: const Icon(Icons.restore_from_trash_outlined),
        toolbarHeight: 80.0,
        title: const Text(
          "Clasificador de desechos",
          style: TextStyle(fontWeight: FontWeight.w300),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(45.0),
        child: Center(
          child: StreamBuilder<String>(
            stream: null, // TODO: Replace with a stream that emits text
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(
                  snapshot.data!,
                  style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w800,
                      fontSize: 34.0),
                );
              } else {
                return const CircularProgressIndicator();
              }
            },
          ),
        ),
      ),
    );
  }
}

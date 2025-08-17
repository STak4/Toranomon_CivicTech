import 'package:flutter/material.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';

class UnityDemoScreen extends StatefulWidget {
  const UnityDemoScreen({super.key});

  @override
  State<UnityDemoScreen> createState() => _UnityDemoScreenState();
}

class _UnityDemoScreenState extends State<UnityDemoScreen> {
  UnityWidgetController? _unityWidgetController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unity Demo')),
      body: Container(
        color: Colors.yellow,
        child: UnityWidget(onUnityCreated: onUnityCreated),
      ),
    );
  }

  // Callback that connects the created controller to the unity controller
  void onUnityCreated(UnityWidgetController controller) {
    _unityWidgetController = controller;
  }

  @override
  void dispose() {
    _unityWidgetController?.dispose();
    super.dispose();
  }
}

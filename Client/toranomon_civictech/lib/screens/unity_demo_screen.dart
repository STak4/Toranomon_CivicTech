import 'package:flutter/material.dart';
import '../utils/app_logger.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import 'package:image_picker/image_picker.dart';

class UnityDemoScreen extends StatefulWidget {
  const UnityDemoScreen({super.key});

  @override
  State<UnityDemoScreen> createState() => _UnityDemoScreenState();
}

class _UnityDemoScreenState extends State<UnityDemoScreen> {
  UnityWidgetController? _unityWidgetController;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    // 画面表示時のログ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLogger.d('Screen - Unity demo screen displayed');
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unity Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: sendJsonToUnity,
            tooltip: 'Send JSON to Unity',
          ),
          IconButton(
            icon: const Icon(Icons.photo_album),
            onPressed: selectImageFromGallery,
            tooltip: 'Select Image from Gallery',
          ),
        ],
      ),
      body: Container(
        color: Colors.yellow,
        child: UnityWidget(
          onUnityCreated: onUnityCreated,
          onUnityMessage: onUnityMessage,
          onUnitySceneLoaded: onUnitySceneLoaded,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _unityWidgetController?.dispose();
    super.dispose();
  }

  // Communcation from Flutter to Unity
  void setRotationSpeed(String speed) {
    _unityWidgetController?.postMessage('Cube', 'SetRotationSpeed', speed);
  }

  // Send JSON message to Unity using postJsonMessage
  void sendJsonToUnity() {
    final message = {
      "type": "command",
      "data": {"name": "capture"},
    };

    _unityWidgetController?.postJsonMessage(
      'FlutterUnity',
      'onMessage',
      message,
    );

    AppLogger.d('[FlutterToUnity]Sent JSON message to Unity: $message');
  }

  // アルバムから写真を選択するメソッド
  Future<void> selectImageFromGallery() async {
    try {
      AppLogger.d('Starting image selection from gallery');

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        AppLogger.d('Image selected: ${image.path}');
        sendPathToUnity(image.path);
      } else {
        AppLogger.d('No image selected');
        _showSnackBar('写真が選択されませんでした');
      }
    } catch (e) {
      AppLogger.e('Error selecting image from gallery', e);
      _showSnackBar('写真の選択中にエラーが発生しました: $e');
    }
  }

  // スナックバーを表示するヘルパーメソッド
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
    }
  }

  // Send JSON message to Unity using postJsonMessage
  void sendPathToUnity(String path) {
    final message = {
      "type": "command",
      "data": {"name": "generated", "path": path},
    };

    _unityWidgetController?.postJsonMessage(
      'FlutterUnity',
      'onMessage',
      message,
    );

    AppLogger.d('[FlutterToUnity]Sent JSON message to Unity: $message');
    _showSnackBar('写真のパスをUnityに送信しました');
  }

  // Callback that connects the created controller to the unity controller
  void onUnityCreated(UnityWidgetController controller) {
    _unityWidgetController = controller;
  }

  // Communication from Unity to Flutter
  void onUnityMessage(dynamic message) {
    AppLogger.d(
      '[UnityToFlutter]Received message from unity: ${message.toString()}',
    );
  }

  // Communication from Unity when new scene is loaded to Flutter
  void onUnitySceneLoaded(SceneLoaded? sceneInfo) {
    AppLogger.d('onUnitySceneLoaded');
    if (sceneInfo != null) {
      AppLogger.d('Received scene loaded from unity: ${sceneInfo.name}');
      AppLogger.d(
        'Received scene loaded from unity buildIndex: ${sceneInfo.buildIndex}',
      );
    }
  }
}

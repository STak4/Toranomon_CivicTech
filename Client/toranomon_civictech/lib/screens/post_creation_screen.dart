import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../providers/post_provider.dart';
import '../providers/camera_provider.dart';
import '../utils/app_logger.dart';

/// 投稿作成画面
/// 
/// 地図タップ位置での投稿作成ダイアログとして使用
/// タイトル、説明文、Anchor ID入力とカメラ/ギャラリー選択機能を提供
class PostCreationScreen extends ConsumerStatefulWidget {
  const PostCreationScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    this.roomId = 'default',
  });

  final double latitude;
  final double longitude;
  final String roomId;

  @override
  ConsumerState<PostCreationScreen> createState() => _PostCreationScreenState();
}

class _PostCreationScreenState extends ConsumerState<PostCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _anchorIdController = TextEditingController();
  
  XFile? _selectedImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _anchorIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postState = ref.watch(postProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('新しい投稿'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitPost,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('投稿'),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 位置情報表示
                  _buildLocationInfo(),
                  const SizedBox(height: 16),
                  
                  // 画像選択セクション
                  _buildImageSection(),
                  const SizedBox(height: 16),
                  
                  // タイトル入力
                  _buildTitleField(),
                  const SizedBox(height: 16),
                  
                  // 説明文入力
                  _buildDescriptionField(),
                  const SizedBox(height: 16),
                  
                  // Anchor ID入力
                  _buildAnchorIdField(),
                  const SizedBox(height: 24),
                  
                  // 投稿ボタン
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
          
          // ローディングオーバーレイ
          if (postState.isLoading || _isSubmitting)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  /// 位置情報表示ウィジェット
  Widget _buildLocationInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '投稿位置',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '緯度: ${widget.latitude.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              '経度: ${widget.longitude.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'ルームID: ${widget.roomId}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  /// 画像選択セクション
  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '画像を追加',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // 選択された画像の表示
            if (_selectedImage != null) ...[
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_selectedImage!.path),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectImage,
                      icon: const Icon(Icons.edit),
                      label: const Text('画像を変更'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('削除'),
                  ),
                ],
              ),
            ] else ...[
              // 画像選択ボタン
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectImageFromCamera(),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('カメラで撮影'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectImageFromGallery(),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('ギャラリーから選択'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// タイトル入力フィールド
  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'タイトル *',
        hintText: '投稿のタイトルを入力してください',
        border: OutlineInputBorder(),
      ),
      maxLength: 100,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'タイトルを入力してください';
        }
        if (value.trim().length < 2) {
          return 'タイトルは2文字以上で入力してください';
        }
        return null;
      },
    );
  }

  /// 説明文入力フィールド
  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: '説明文 *',
        hintText: '投稿の詳細を入力してください',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 4,
      maxLength: 500,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '説明文を入力してください';
        }
        if (value.trim().length < 5) {
          return '説明文は5文字以上で入力してください';
        }
        return null;
      },
    );
  }

  /// Anchor ID入力フィールド
  Widget _buildAnchorIdField() {
    return TextFormField(
      controller: _anchorIdController,
      decoration: const InputDecoration(
        labelText: 'Anchor ID *',
        hintText: 'ARアンカーのIDを入力してください',
        border: OutlineInputBorder(),
        helperText: 'ARで使用するアンカーの識別子',
      ),
      maxLength: 50,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Anchor IDを入力してください';
        }
        if (value.trim().length < 3) {
          return 'Anchor IDは3文字以上で入力してください';
        }
        // 英数字とハイフン、アンダースコアのみ許可
        if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value.trim())) {
          return 'Anchor IDは英数字、ハイフン、アンダースコアのみ使用できます';
        }
        return null;
      },
    );
  }

  /// 投稿ボタン
  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitPost,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isSubmitting
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('投稿中...'),
              ],
            )
          : const Text(
              '投稿する',
              style: TextStyle(fontSize: 16),
            ),
    );
  }

  /// 画像選択（カメラまたはギャラリー）
  void _selectImage() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('カメラで撮影'),
              onTap: () {
                Navigator.pop(context);
                _selectImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('ギャラリーから選択'),
              onTap: () {
                Navigator.pop(context);
                _selectImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('キャンセル'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  /// カメラから画像を選択
  Future<void> _selectImageFromCamera() async {
    try {
      AppLogger.i('カメラから画像選択開始');
      
      final cameraNotifier = ref.read(cameraNotifierProvider.notifier);
      final image = await cameraNotifier.takePictureWithImagePicker();
      
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
        AppLogger.i('カメラから画像選択完了');
      }
    } catch (e, stackTrace) {
      AppLogger.e('カメラから画像選択に失敗', e, stackTrace);
      _showErrorSnackBar('カメラから画像を取得できませんでした');
    }
  }

  /// ギャラリーから画像を選択
  Future<void> _selectImageFromGallery() async {
    try {
      AppLogger.i('ギャラリーから画像選択開始');
      
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
        AppLogger.i('ギャラリーから画像選択完了');
      }
    } catch (e, stackTrace) {
      AppLogger.e('ギャラリーから画像選択に失敗', e, stackTrace);
      _showErrorSnackBar('ギャラリーから画像を取得できませんでした');
    }
  }

  /// 投稿を送信
  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isSubmitting = true;
      });

      AppLogger.i('投稿送信開始');

      final request = CreatePostRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        latitude: widget.latitude,
        longitude: widget.longitude,
        anchorId: _anchorIdController.text.trim(),
        roomId: widget.roomId,
        imageFile: _selectedImage,
      );

      final postNotifier = ref.read(postProvider.notifier);
      final post = await postNotifier.createPost(request);

      if (post != null) {
        AppLogger.i('投稿送信完了 - id: ${post.id}');
        
        // 成功メッセージを表示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('投稿が作成されました'),
              backgroundColor: Colors.green,
            ),
          );
          
          // 画面を閉じる
          Navigator.of(context).pop(post);
        }
      } else {
        _showErrorSnackBar('投稿の作成に失敗しました');
      }
    } catch (e, stackTrace) {
      AppLogger.e('投稿送信に失敗', e, stackTrace);
      _showErrorSnackBar('投稿の作成中にエラーが発生しました');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// エラーメッセージを表示
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// 投稿作成ダイアログ
/// 
/// 地図タップ時に表示される投稿作成ダイアログ
class PostCreationDialog extends ConsumerStatefulWidget {
  const PostCreationDialog({
    super.key,
    required this.latitude,
    required this.longitude,
    this.roomId = 'default',
  });

  final double latitude;
  final double longitude;
  final String roomId;

  @override
  ConsumerState<PostCreationDialog> createState() => _PostCreationDialogState();
}

class _PostCreationDialogState extends ConsumerState<PostCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _anchorIdController = TextEditingController();
  
  XFile? _selectedImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _anchorIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ヘッダー
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inversePrimary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '新しい投稿',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // コンテンツ
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 位置情報表示
                      _buildLocationInfo(),
                      const SizedBox(height: 16),
                      
                      // 画像選択
                      _buildImageSection(),
                      const SizedBox(height: 16),
                      
                      // タイトル入力
                      _buildTitleField(),
                      const SizedBox(height: 16),
                      
                      // 説明文入力
                      _buildDescriptionField(),
                      const SizedBox(height: 16),
                      
                      // Anchor ID入力
                      _buildAnchorIdField(),
                    ],
                  ),
                ),
              ),
            ),
            
            // フッター
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('キャンセル'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitPost,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('投稿'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 位置情報表示ウィジェット
  Widget _buildLocationInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '投稿位置',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '緯度: ${widget.latitude.toStringAsFixed(6)}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            '経度: ${widget.longitude.toStringAsFixed(6)}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// 画像選択セクション（簡易版）
  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '画像（オプション）',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        if (_selectedImage != null) ...[
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(_selectedImage!.path),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectImage,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('変更', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                  });
                },
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('削除', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ] else ...[
          OutlinedButton.icon(
            onPressed: _selectImage,
            icon: const Icon(Icons.add_a_photo),
            label: const Text('画像を追加'),
          ),
        ],
      ],
    );
  }

  /// タイトル入力フィールド（簡易版）
  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'タイトル *',
        hintText: '投稿のタイトル',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      maxLength: 100,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'タイトルを入力してください';
        }
        return null;
      },
    );
  }

  /// 説明文入力フィールド（簡易版）
  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: '説明文 *',
        hintText: '投稿の詳細',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      maxLines: 3,
      maxLength: 200,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '説明文を入力してください';
        }
        return null;
      },
    );
  }

  /// Anchor ID入力フィールド（簡易版）
  Widget _buildAnchorIdField() {
    return TextFormField(
      controller: _anchorIdController,
      decoration: const InputDecoration(
        labelText: 'Anchor ID *',
        hintText: 'ARアンカーID',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      maxLength: 50,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Anchor IDを入力してください';
        }
        if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value.trim())) {
          return '英数字、ハイフン、アンダースコアのみ';
        }
        return null;
      },
    );
  }

  /// 画像選択
  void _selectImage() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('カメラで撮影'),
              onTap: () {
                Navigator.pop(context);
                _selectImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('ギャラリーから選択'),
              onTap: () {
                Navigator.pop(context);
                _selectImageFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// カメラから画像を選択
  Future<void> _selectImageFromCamera() async {
    try {
      final cameraNotifier = ref.read(cameraNotifierProvider.notifier);
      final image = await cameraNotifier.takePictureWithImagePicker();
      
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e, stackTrace) {
      AppLogger.e('カメラから画像選択に失敗', e, stackTrace);
    }
  }

  /// ギャラリーから画像を選択
  Future<void> _selectImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e, stackTrace) {
      AppLogger.e('ギャラリーから画像選択に失敗', e, stackTrace);
    }
  }

  /// 投稿を送信
  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isSubmitting = true;
      });

      final request = CreatePostRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        latitude: widget.latitude,
        longitude: widget.longitude,
        anchorId: _anchorIdController.text.trim(),
        roomId: widget.roomId,
        imageFile: _selectedImage,
      );

      final postNotifier = ref.read(postProvider.notifier);
      final post = await postNotifier.createPost(request);

      if (post != null && mounted) {
        Navigator.of(context).pop(post);
      }
    } catch (e, stackTrace) {
      AppLogger.e('投稿送信に失敗', e, stackTrace);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
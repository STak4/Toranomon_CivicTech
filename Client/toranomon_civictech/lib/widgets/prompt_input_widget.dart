import 'package:flutter/material.dart';

/// プロンプト入力フィールドウィジェット
///
/// Leonard AI機能で使用する共通のプロンプト入力コンポーネント
/// 文字数制限、バリデーション、クリアボタンなどの機能を提供
class PromptInputWidget extends StatefulWidget {
  const PromptInputWidget({
    super.key,
    required this.onChanged,
    this.onSubmitted,
    this.hintText = 'プロンプトを入力してください...',
    this.maxLength = 500,
    this.minLines = 3,
    this.maxLines = 6,
    this.enabled = true,
    this.initialValue,
  });

  /// テキスト変更時のコールバック
  final ValueChanged<String> onChanged;

  /// 送信時のコールバック（Enterキー押下時など）
  final ValueChanged<String>? onSubmitted;

  /// ヒントテキスト
  final String hintText;

  /// 最大文字数
  final int maxLength;

  /// 最小行数
  final int minLines;

  /// 最大行数
  final int maxLines;

  /// 入力可能かどうか
  final bool enabled;

  /// 初期値
  final String? initialValue;

  @override
  State<PromptInputWidget> createState() => _PromptInputWidgetState();
}

class _PromptInputWidgetState extends State<PromptInputWidget> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();

    _controller.addListener(() {
      widget.onChanged(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.edit_note,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'プロンプト入力',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_controller.text.isNotEmpty && widget.enabled)
                  IconButton(
                    onPressed: () {
                      _controller.clear();
                      _focusNode.unfocus();
                    },
                    icon: const Icon(Icons.clear),
                    tooltip: 'クリア',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              minLines: widget.minLines,
              maxLines: widget.maxLines,
              maxLength: widget.maxLength,
              textInputAction: TextInputAction.done,
              onSubmitted: (value) {
                _focusNode.unfocus(); // キーボードを閉じる
                widget.onSubmitted?.call(value);
              },
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                filled: true,
                fillColor: widget.enabled ? Colors.grey[50] : Colors.grey[100],
                contentPadding: const EdgeInsets.all(16),
              ),
              style: const TextStyle(fontSize: 16),
            ),
            if (_controller.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${_controller.text.length}/${widget.maxLength}文字',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

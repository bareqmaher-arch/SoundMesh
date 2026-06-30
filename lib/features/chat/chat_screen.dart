import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_text.dart';
import '../../core/session_controller.dart';
import '../../core/settings_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/chat_message.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/glass.dart';
import '../../widgets/image_viewer.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    ref.read(sessionControllerProvider.notifier).sendText(text);
    _input.clear();
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 140,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(sessionControllerProvider).messages;
    final ctrl = ref.read(sessionControllerProvider.notifier);
    final t = ref.watch(appTextProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.messages)),
      body: AuroraBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: messages.isEmpty
                    ? _EmptyState(t: t)
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        itemCount: messages.length,
                        itemBuilder: (context, i) =>
                            _Bubble(message: messages[i]),
                      ),
              ),
              _Composer(
                controller: _input,
                hint: t.typeMessage,
                onSend: _send,
                onImage: () async {
                  await ctrl.sendImageFromGallery();
                  _scrollToEnd();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppText t;
  const _EmptyState({required this.t});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 86,
            height: 86,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                gradient: AppColors.brand,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.violet.withValues(alpha: 0.4),
                      blurRadius: 28)
                ]),
            child: const Icon(Icons.forum_rounded,
                color: Colors.white, size: 38),
          ),
          const SizedBox(height: 18),
          Text(t.noMessages,
              style:
                  TextStyle(fontWeight: FontWeight.w700, color: p.text)),
          const SizedBox(height: 6),
          Text(t.noMessagesBody,
              style: TextStyle(color: p.textDim, fontSize: 13)),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final mine = message.isMine;
    final textColor = mine ? Colors.white : p.text;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!mine)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 6, right: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppAvatar(name: message.senderName, size: 20),
                    const SizedBox(width: 6),
                    Text(message.senderName,
                        style: TextStyle(fontSize: 11, color: p.textDim)),
                  ],
                ),
              ),
            Container(
              padding: message.kind == MessageKind.image
                  ? const EdgeInsets.all(4)
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                gradient: mine ? AppColors.brand : null,
                color: mine ? null : p.glassStrong,
                border: mine ? null : Border.all(color: p.border),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(mine ? 18 : 4),
                  bottomRight: Radius.circular(mine ? 4 : 18),
                ),
              ),
              child: message.kind == MessageKind.image
                  ? GestureDetector(
                      onTap: message.imagePath != null
                          ? () => FullScreenImage.open(context,
                              message.imagePath!, 'img_${message.id}')
                          : null,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: message.imagePath != null
                            ? Hero(
                                tag: 'img_${message.id}',
                                child: Image.file(File(message.imagePath!),
                                    fit: BoxFit.cover),
                              )
                            : const SizedBox(width: 160, height: 120),
                      ),
                    )
                  : Text(message.text ?? '',
                      style: TextStyle(color: textColor, fontSize: 14.5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onSend;
  final VoidCallback onImage;

  const _Composer({
    required this.controller,
    required this.hint,
    required this.onSend,
    required this.onImage,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: p.bgElevated.withValues(alpha: p.isDark ? 0.7 : 0.95),
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: onImage,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.16),
                    shape: BoxShape.circle),
                child: const Icon(Icons.image_rounded, color: AppColors.cyan),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: hint,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onSend,
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                    gradient: AppColors.brand, shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

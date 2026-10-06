import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/env.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/database_helper.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/chat_message.dart';

/// "Ask Lung Tom": an assistant for growing, GAP and the kratom law, with
/// voice input and photo diagnosis on phones. History stays on the device.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _suggestions = [
    'ขั้นตอนขอ GAP มีอะไรบ้าง',
    'ใส่ปุ๋ยอะไรให้กระท่อมดี',
    'กระท่อมปลูกได้กี่ต้น ผิดกฎหมายไหม',
    'ใบมีจุดสีน้ำตาล รักษายังไง',
  ];

  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _chat = ChatService();
  final _voice = VoiceService();
  final List<ChatMessage> _messages = [];
  XFile? _image;
  bool _thinking = false;
  bool _listening = false;
  int _remaining = ChatService.dailyRequestLimit;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    try {
      final history = await DatabaseHelper.instance.getChatHistory();
      final usage = await _chat.getDailyUsage();
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(history.where((m) => !m.isLoading));
        _remaining = usage.remaining;
      });
      _toBottom(jump: true);
    } on Object catch (_) {}
  }

  void _toBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      jump ? _scroll.jumpTo(end) : _scroll.animateTo(end, duration: Motion.slow, curve: Motion.standard);
    });
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    final image = _image;
    if ((text.isEmpty && image == null) || _thinking) return;

    final question = ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      content: text.isEmpty ? 'ช่วยดูรูปนี้ให้หน่อย' : text,
      imagePath: image?.path,
      isUser: true,
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.add(question);
      _thinking = true;
      _image = null;
      _input.clear();
    });
    _toBottom();
    DatabaseHelper.instance.saveMessage(question);

    String answer;
    try {
      answer = await _chat.ask(
        question.content,
        imageBytes: image == null ? null : await image.readAsBytes(),
        imageName: image?.name,
      );
    } on Object catch (_) {
      answer = 'ตอนนี้ลุงต้อมตอบไม่ได้ ลองใหม่อีกครั้งในอีกสักครู่';
    }
    final reply = ChatMessage(
      id: 'ai_${DateTime.now().microsecondsSinceEpoch}',
      content: answer,
      isUser: false,
      timestamp: DateTime.now(),
    );
    DatabaseHelper.instance.saveMessage(reply);
    final usage = await _chat.getDailyUsage();
    if (!mounted) return;
    setState(() {
      _messages.add(reply);
      _thinking = false;
      _remaining = usage.remaining;
    });
    _toBottom();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1280, imageQuality: 85);
    if (picked != null && mounted) setState(() => _image = picked);
  }

  Future<void> _toggleVoice() async {
    if (_listening) {
      await _voice.stopListening();
      if (mounted) setState(() => _listening = false);
      return;
    }
    final ok = await _voice.initialize();
    if (!mounted) return;
    if (!ok) {
      AppToast.error(context, 'อุปกรณ์นี้ยังใช้การพูดแทนพิมพ์ไม่ได้');
      return;
    }
    await _voice.startListening(
      onListeningStarted: () => setState(() => _listening = true),
      onListeningStopped: () => setState(() => _listening = false),
      onResult: (text) {
        if (!mounted) return;
        _input.text = text;
        _input.selection = TextSelection.collapsed(offset: text.length);
      },
    );
  }

  Future<void> _clear() async {
    final ok = await AppDialogs.confirm(
      context,
      title: 'เริ่มบทสนทนาใหม่?',
      message: 'ประวัติการถามตอบในเครื่องนี้จะถูกลบ',
      confirmLabel: 'เริ่มใหม่',
    );
    if (!ok) return;
    await DatabaseHelper.instance.clearChatHistory();
    _chat.resetChat();
    if (mounted) setState(_messages.clear);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const mobile = !kIsWeb;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Row(
          children: [
            FarmerMascot(size: 40, mood: _thinking ? MascotMood.think : MascotMood.happy),
            const SizedBox(width: Space.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ถามลุงต้อม', style: context.text.titleMedium),
                Text(
                  _thinking
                      ? 'กำลังคิด'
                      : (ChatService.offline
                            ? (Env.demoMode
                                  ? 'โหมดสาธิต คำตอบตัวอย่าง'
                                  : 'คำตอบตัวอย่าง ผู้ช่วยยังไม่เปิดบนเซิร์ฟเวอร์')
                            : 'เหลือ $_remaining คำถามวันนี้'),
                  style: context.text.labelSmall,
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(tooltip: 'เริ่มบทสนทนาใหม่', onPressed: _clear, icon: const Icon(AppIcons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _Welcome(onPick: _send)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, Space.md),
                    itemCount: _messages.length + (_thinking ? 1 : 0),
                    itemBuilder: (context, i) =>
                        i == _messages.length ? const _Typing() : _Bubble(message: _messages[i]).entrance(context),
                  ),
          ),
          if (_image != null)
            Container(
              color: p.surface,
              padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, 0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.sm),
                    child: _localImage(_image!.path, width: 48, height: 48),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(child: Text('แนบรูป 1 รูป', style: context.text.bodySmall)),
                  IconButton(onPressed: () => setState(() => _image = null), icon: const Icon(AppIcons.close)),
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: p.surface,
              border: Border(top: BorderSide(color: p.line)),
            ),
            padding: EdgeInsets.fromLTRB(Space.sm, Space.sm, Space.sm, Space.sm + MediaQuery.paddingOf(context).bottom),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (mobile)
                  IconButton(
                    tooltip: 'แนบรูปพืช',
                    onPressed: _thinking ? null : _pickImage,
                    icon: const Icon(AppIcons.camera),
                  ),
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(hintText: _listening ? 'กำลังฟัง พูดได้เลย' : 'พิมพ์คำถาม'),
                  ),
                ),
                if (mobile)
                  IconButton(
                    tooltip: _listening ? 'หยุดฟัง' : 'พูดแทนพิมพ์',
                    onPressed: _thinking ? null : _toggleVoice,
                    icon: Icon(AppIcons.mic, color: _listening ? p.danger : null),
                  ),
                const SizedBox(width: Space.xs),
                AppIconButton(
                  icon: AppIcons.send,
                  tooltip: 'ส่ง',
                  background: p.brand,
                  foreground: p.onBrand,
                  onPressed: _thinking ? null : _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(Space.xl),
      children: [
        const SizedBox(height: Space.xl),
        const Center(child: FarmerMascot(size: 140, mood: MascotMood.wave)),
        const SizedBox(height: Space.lg),
        Text('สวัสดีครับ ลุงต้อมเอง', style: context.text.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: Space.sm),
        Text(
          'ถามเรื่องการปลูก ดูแล เก็บเกี่ยว มาตรฐาน GAP หรือส่งรูปใบที่ผิดปกติมาให้ดูได้',
          style: context.text.bodyMedium?.copyWith(color: context.palette.inkMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Space.xxl),
        for (final s in _ChatScreenState._suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
              onTap: () => onPick(s),
              child: Row(
                children: [
                  Expanded(child: Text(s, style: context.text.bodyMedium)),
                  const Icon(AppIcons.arrowUpRight, size: 18),
                ],
              ),
            ),
          ),
        const SizedBox(height: Space.lg),
        Text(
          'คำตอบเป็นข้อมูลทั่วไป ไม่ใช่คำวินิจฉัยของเจ้าหน้าที่',
          style: context.text.labelSmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final mine = message.isUser;
    final image = message.imagePath;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        child: Container(
          margin: const EdgeInsets.only(bottom: Space.md),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: mine ? p.brand : p.surface,
            border: mine ? null : Border.all(color: p.line),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(mine ? 18 : 6),
              bottomRight: Radius.circular(mine ? 6 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (image != null && !kIsWeb && File(image).existsSync())
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.sm),
                    child: _localImage(image, height: 160),
                  ),
                ),
              SelectableText(
                message.content.replaceAll('**', ''),
                style: context.text.bodyMedium?.copyWith(color: mine ? p.onBrand : p.ink, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: Space.md),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: p.surface,
          border: Border.all(color: p.line),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: p.inkSubtle, shape: BoxShape.circle),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .fadeIn(
                    delay: Duration(milliseconds: i * 160),
                    duration: Motion.base,
                  )
                  .then()
                  .fadeOut(duration: Motion.base),
          ],
        ),
      ),
    );
  }
}

/// A picked photo: a file on mobile, a blob URL on the web.
Widget _localImage(String path, {double? width, double? height}) => kIsWeb
    ? Image.network(path, width: width, height: height, fit: BoxFit.cover)
    : Image.file(File(path), width: width, height: height, fit: BoxFit.cover);

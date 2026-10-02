import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';

/// Enhanced input bar widget with glassmorphic design
class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode; // Added parameter
  final VoidCallback onSend;
  final VoidCallback onImagePick;
  final VoidCallback onVoiceStart;
  final VoidCallback onVoiceStop;
  final bool isRecording;
  final bool isLoading;
  final File? selectedImage;
  final VoidCallback? onClearImage;

  const ChatInputBar({
    super.key,
    required this.controller,
    this.focusNode,
    required this.onSend,
    required this.onImagePick,
    required this.onVoiceStart,
    required this.onVoiceStop,
    this.isRecording = false,
    this.isLoading = false,
    this.selectedImage,
    this.onClearImage,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image Preview
              if (widget.selectedImage != null) _buildImagePreview(),

              // Main Input Container
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.background,
                      AppColors.background.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 4),

                    // Image Picker Button
                    _buildCircleButton(
                      icon: PhosphorIconsRegular.image,
                      onPressed: widget.isLoading ? null : widget.onImagePick,
                      size: 36,
                    ),

                    // Voice Button
                    _buildVoiceButton(),

                    // Text Field
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          // Ensure focus is requested when container is tapped
                          if (widget.focusNode != null) {
                            if (!widget.focusNode!.hasFocus) {
                              widget.focusNode!.requestFocus();
                            }
                            // Force show keyboard leveraging system channel
                            // Adding a slight delay to bypass any ongoing animation cancellations
                            await Future.delayed(
                              const Duration(milliseconds: 100),
                            );
                            await SystemChannels.textInput.invokeMethod(
                              'TextInput.show',
                            );
                          }
                        },
                        child: TextField(
                          controller: widget.controller,
                          focusNode: widget.focusNode,
                          enabled: !widget.isLoading && !widget.isRecording,
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textMain,
                          ),
                          decoration: InputDecoration(
                            hintText: widget.isRecording
                                ? '🎤 กำลังฟัง...'
                                : 'พิมพ์ข้อความ...',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 14,
                            ),
                          ),
                          maxLines: 4,
                          minLines: 1,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _handleSend(),
                        ),
                      ),
                    ),

                    // Send Button
                    _buildSendButton(),
                    const SizedBox(width: 4),
                  ],
                ),
              ),

              // Powered by text
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Powered by Gemini AI ✨',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                widget.selectedImage!,
                width: 120,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: widget.onClearImage,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red, Colors.red[700]!],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(PhosphorIconsRegular.x, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback? onPressed,
    double size = 40,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Center(
            child: Icon(
              icon,
              color: onPressed == null ? Colors.grey[300] : AppColors.primary,
              size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceButton() {
    if (widget.isRecording) {
      return AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.withValues(alpha: 0.8 + (_pulseController.value * 0.2)),
                  Colors.red[700]!.withValues(alpha: 
                    0.8 + (_pulseController.value * 0.2),
                  ),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 
                    0.3 + (_pulseController.value * 0.2),
                  ),
                  blurRadius: 8 + (_pulseController.value * 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onVoiceStop,
                borderRadius: BorderRadius.circular(18),
                child: const Center(
                  child: Icon(
                    PhosphorIconsFill.microphone,
                    color: Colors.white,
                    size: 18),
                ),
              ),
            ),
          );
        },
      );
    }

    return _buildCircleButton(
      icon: PhosphorIconsRegular.microphone,
      onPressed: widget.isLoading ? null : widget.onVoiceStart,
      size: 36,
    );
  }

  Widget _buildSendButton() {
    final canSend =
        widget.controller.text.trim().isNotEmpty ||
        widget.selectedImage != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: canSend && !widget.isLoading
            ? const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: canSend && !widget.isLoading ? null : Colors.grey[200],
        shape: BoxShape.circle,
        boxShadow: canSend && !widget.isLoading
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canSend && !widget.isLoading ? _handleSend : null,
          borderRadius: BorderRadius.circular(22),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey[400],
                    ),
                  )
                : Transform.rotate(
                    angle: -0.4, // Slight rotation for style
                    child: Icon(
                      PhosphorIconsFill.paperPlaneTilt,
                      color: canSend ? Colors.white : Colors.grey[400],
                      size: 20),
                  ),
          ),
        ),
      ),
    );
  }

  void _handleSend() {
    if (widget.controller.text.trim().isNotEmpty ||
        widget.selectedImage != null) {
      widget.onSend();
    }
  }
}

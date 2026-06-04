import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import '../../../core/constants/app_colors.dart';

/// Search bar with debounce functionality
class DebounceSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final String hintText;
  final Duration debounceDuration;

  const DebounceSearchBar({
    super.key,
    required this.onSearch,
    this.hintText = 'ค้นหา...',
    this.debounceDuration = const Duration(milliseconds: 500),
  });

  @override
  State<DebounceSearchBar> createState() => _DebounceSearchBarState();
}

class _DebounceSearchBarState extends State<DebounceSearchBar> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.onSearch(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: _onSearchChanged,
        style: GoogleFonts.prompt(
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: GoogleFonts.prompt(
            color: AppColors.textTertiary,
            fontSize: 15,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: HeroIcon(
              HeroIcons.magnifyingGlass,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: HeroIcon(
                    HeroIcons.xMark,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () {
                    _controller.clear();
                    widget.onSearch('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

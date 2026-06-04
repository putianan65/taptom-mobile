import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class PinVerificationDialog extends StatefulWidget {
  final VoidCallback onSuccess;

  const PinVerificationDialog({super.key, required this.onSuccess});

  @override
  State<PinVerificationDialog> createState() => _PinVerificationDialogState();
}

class _PinVerificationDialogState extends State<PinVerificationDialog> {
  String _pin = '';

  void _onKeyPress(String value) {
    if (_pin.length < 6) {
      setState(() {
        _pin += value;
      });

      if (_pin.length == 6) {
        _verifyPin();
      }
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _verifyPin() {
    // Mock Validation
    if (_pin == '123456') {
      widget.onSuccess();
    } else {
      setState(() {
        _pin = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN ไม่ถูกต้อง (ลอง 123456)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ยืนยันรหัส PIN',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPinDots(),
            const SizedBox(height: 24),
            _buildNumberPad(),
          ],
        ),
      ),
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < _pin.length ? AppColors.primary : Colors.grey[300],
          ),
        );
      }),
    );
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        _buildRow(['1', '2', '3']),
        const SizedBox(height: 16),
        _buildRow(['4', '5', '6']),
        const SizedBox(height: 16),
        _buildRow(['7', '8', '9']),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 60), // Empty space
            _buildKey('0'),
            IconButton(
              onPressed: _onDelete,
              icon: const Icon(Icons.backspace_outlined),
              iconSize: 28,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((k) => _buildKey(k)).toList(),
    );
  }

  Widget _buildKey(String value) {
    return InkWell(
      onTap: () => _onKeyPress(value),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

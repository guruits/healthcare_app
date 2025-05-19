import 'package:flutter/material.dart';

class ReusableButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isOutlined;
  final bool isFullWidth;

  const ReusableButton({
    Key? key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.isOutlined = false,
    this.isFullWidth = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonStyle = isOutlined
        ? ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      side: BorderSide(color: Colors.black),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    )
        : ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    );

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon) : SizedBox.shrink(),
      label: Text(label),
      style: buttonStyle.copyWith(
        minimumSize: isFullWidth
            ? MaterialStateProperty.all(Size(double.infinity, 48))
            : null,
      ),
    );
  }
}

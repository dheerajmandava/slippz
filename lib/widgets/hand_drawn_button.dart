import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class HandDrawnButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isFloating;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;

  const HandDrawnButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isFloating = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? (isFloating ? Colors.black : Colors.white);
    final txtColor = textColor ?? (isFloating ? Colors.white : Colors.black);
    
    return GestureDetector(
      onTap: () {
        // Button tapped
        onPressed?.call();
      },
      child: Container(
        width: isFloating ? 12.w : null,
        height: isFloating ? 12.w : 5.2.h,
        padding: isFloating 
            ? EdgeInsets.all(1.w)
            : EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(isFloating ? 5.w : 2.h),
          border: Border.all(
            color: const Color.fromARGB(255, 48, 47, 47),
            width: 1.5,
          ),
        ),
        child: isFloating
            ? Center(
                child: Text(
                  '+',
                  style: GoogleFonts.inter(
                    fontSize: 5.w,
                    fontWeight: FontWeight.w300,
                    color: txtColor,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: txtColor,
                      size: 3.w,
                    ),
                    SizedBox(width: 1.w),
                  ],
                  Text(
                    text,
                    style: GoogleFonts.pacifico(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: txtColor,
                      // letterSpacing: 1.w
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}


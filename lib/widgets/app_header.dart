import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class AppHeader extends StatelessWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onNotificationTap;

  const AppHeader({
    super.key,
    this.onMenuTap,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red,
      padding:  EdgeInsets.fromLTRB(1, 1, 1, 1),
      child: Center(
        child:  Text(
          'Slippz',
          style: GoogleFonts.timmana(
            fontSize: 26.sp,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
            
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/currency_service.dart';

class CurrencyText extends StatelessWidget {
  final double amount;
  final bool noDecimals;
  final TextStyle? style;

  const CurrencyText({super.key, required this.amount, this.noDecimals = false, this.style});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: noDecimals
          ? CurrencyService.formatAmountNoDecimals(amount)
          : CurrencyService.formatAmount(amount),
      builder: (context, snapshot) {
        final text = snapshot.data ?? '${CurrencyService.getSelectedCode().toString()}${noDecimals ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2)}';
        return Text(text, style: style);
      },
    );
  }
}



import 'package:flutter/material.dart';
import '../services/currency_service.dart';

class CurrencyText extends StatelessWidget {
  final double amount;
  final bool noDecimals;
  final TextStyle? style;

  const CurrencyText({super.key, required this.amount, this.noDecimals = false, this.style});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: CurrencyService.currencyNotifier,
      builder: (context, currencyCode, child) {
        return FutureBuilder<String>(
          future: noDecimals
              ? CurrencyService.formatAmountNoDecimals(amount)
              : CurrencyService.formatAmount(amount),
          builder: (context, snapshot) {
            final text = snapshot.data ?? '$currencyCode${noDecimals ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2)}';
            return Text(text, style: style);
          },
        );
      },
    );
  }
}



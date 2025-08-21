import 'package:flutter/material.dart';
import 'dart:io';
import '../../models/receipt.dart';

class ReceiptCard extends StatelessWidget {
  final Receipt receipt;

  const ReceiptCard({required this.receipt, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Product: ${receipt.productName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Store: ${receipt.storeName}'),
            Text('Price: \$${receipt.price.toStringAsFixed(2)}'),
            Text('Category: ${receipt.category}'),
            const SizedBox(height: 8),
            Text(
              'Purchase Date: ${receipt.purchaseDate.toLocal().toString().split(' ')[0]}',
            ),
            Text(
              'Warranty End Date: ${receipt.warrantyEndDate.toLocal().toString().split(' ')[0]}',
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Image.file(
                File(receipt.receiptImagePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.error, size: 50, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

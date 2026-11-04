import 'package:flutter/material.dart';

import '../receipt_keys.dart';
import '../receipt_theme.dart';
import 'receipt_parts.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: ReceiptKeys.loading,
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Text(
            'PRINTING RECEIPT…',
            style: Receipt.text(weight: FontWeight.w700, spacing: 1.6),
          ),
          const SizedBox(height: 14),
          const LinearProgressIndicator(
            minHeight: 2,
            color: Receipt.ink,
            backgroundColor: Color(0x2226231F),
          ),
        ],
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: ReceiptKeys.empty,
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Text(
            'NO ITEMS ON THIS RECEIPT',
            textAlign: TextAlign.center,
            style: Receipt.text(weight: FontWeight.w700, spacing: 1.4),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your first item below.',
            textAlign: TextAlign.center,
            style: Receipt.text(color: Receipt.fadedInk),
          ),
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: ReceiptKeys.error,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            '*** PAPER JAM ***',
            style: Receipt.text(
              size: 15,
              color: Receipt.stamp,
              weight: FontWeight.w700,
              spacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Couldn't load your tasks.",
            textAlign: TextAlign.center,
            style: Receipt.text(),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Receipt.text(size: 12, color: Receipt.fadedInk),
          ),
          const SizedBox(height: 18),
          ReceiptButton(
            key: ReceiptKeys.retryButton,
            label: 'RETRY',
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

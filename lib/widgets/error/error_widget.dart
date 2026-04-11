import 'package:flutter/material.dart';

class MyErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryText;
  final IconData? icon;

  const MyErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.retryText,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon ?? Icons.shield_outlined,
                size: 124,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              Container(
                width: 400,
                height: 200,
                constraints: const BoxConstraints(maxWidth: 800),
                decoration: _scrollDecoration(context),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Alas! An Error Hath Occurred',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    // Error message
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            message,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    if (onRetry != null) ...[
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _scrollDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).appBarTheme.backgroundColor,
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).shadowColor,
          blurRadius: 8,
          offset: const Offset(2, 4),
        ),
      ],
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(4),
        topRight: Radius.circular(4),
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
    );
  }
}
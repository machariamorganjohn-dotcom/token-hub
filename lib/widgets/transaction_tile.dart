import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TransactionTile extends StatefulWidget {
  final String title;
  final String date;
  final String amount;
  final bool isSuccess;
  final String? token;
  final VoidCallback? onShare;

  const TransactionTile({
    super.key,
    required this.title,
    required this.date,
    required this.amount,
    this.isSuccess = true,
    this.token,
    this.onShare,
  });

  @override
  State<TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<TransactionTile> {
  bool _isRevealed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (widget.isSuccess ? Colors.green : Colors.red).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.isSuccess ? Icons.bolt : Icons.error_outline,
              color: widget.isSuccess ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  widget.date,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                if (widget.token != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.vpn_key_rounded, size: 12, color: Colors.green),
                        const SizedBox(width: 6),
                        Text(
                          _isRevealed ? widget.token! : "••••-••••-••••-••••",
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            setState(() => _isRevealed = !_isRevealed);
                            HapticFeedback.selectionClick();
                          },
                          child: Icon(
                            _isRevealed ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            size: 16,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                             Clipboard.setData(ClipboardData(text: widget.token!.replaceAll('-', '')));
                             HapticFeedback.lightImpact();
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text("Token copied!"), duration: Duration(seconds: 1)),
                             );
                          },
                          child: const Icon(Icons.copy_rounded, size: 16, color: Colors.green),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: widget.onShare,
                          child: const Icon(Icons.share_rounded, size: 16, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            widget.amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: widget.isSuccess ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }
}

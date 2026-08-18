import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'payment_cubit.dart';
import 'payment_state.dart';

class PaymentDetailsScreen extends StatelessWidget {
  final String userId;
  const PaymentDetailsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    const bankInfo = {
      'Bank Name': 'NBP : National Bank of Pakistan',
      'Account Name': 'Hostings Ware SMC Private Limited',
      'Account Number': '03154249365340',
      'IBAN': 'PK77NBPA0315004249365340',
      'Country': 'Pakistan',
    };

    final TextEditingController refCtrl = TextEditingController();

    return BlocProvider(
      create: (_) => PaymentCubit()..init(userId),
      child: Scaffold(
        backgroundColor: const Color(0xFF232323),
        appBar: AppBar(
          title: const Text('Upgrade to Pro'),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: BlocConsumer<PaymentCubit, PaymentState>(
          listenWhen: (p, c) => p.error != c.error || p.message != c.message,
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error!, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent),
              );
            } else if (state.message != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message!, style: const TextStyle(color: Colors.white))),
              );
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16).copyWith(bottom: 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: Colors.white.withOpacity(0.06),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bank Payment Details', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          ...bankInfo.entries.map((e) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(child: Text(e.key, style: const TextStyle(color: Colors.white70))),
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Flexible(
                                            child: SelectableText(
                                              e.value,
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            tooltip: 'Copy',
                                            onPressed: () => context.read<PaymentCubit>().copyToClipboard(e.value),
                                            icon: const Icon(Icons.copy, color: Colors.white70, size: 18),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Card(
                    color: Colors.white.withOpacity(0.06),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Select Plan', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          _TierTile(title: 'Monthly', value: 'monthly', price: state.pricesUSD['monthly'] ?? 0.0, group: state.selectedTier,
                              onChanged: (v) => context.read<PaymentCubit>().selectTier(v)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Card(
                    color: Colors.white.withOpacity(0.06),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('After sending payment, please share the payment screenshot on WhatsApp so our team can activate your Pro account. Thank you.',
                              style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.read<PaymentCubit>().openWhatsApp(phone: '+923215971854'),
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text('Message us on WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        minimumSize: const Size(0, 48),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TierTile extends StatelessWidget {
  final String title;
  final String value;
  final String group;
  final double price;
  final ValueChanged<String> onChanged;
  const _TierTile({required this.title, required this.value, required this.group, required this.price, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final selected = group == value;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Radio<String>(
        value: value,
        groupValue: group,
        onChanged: (v) => v != null ? onChanged(v) : null,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      trailing: Text(
        '\$${price % 1 == 0 ? price.toStringAsFixed(0) : price.toStringAsFixed(2)}',
        style: const TextStyle(
          color: Colors.amber,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }
}

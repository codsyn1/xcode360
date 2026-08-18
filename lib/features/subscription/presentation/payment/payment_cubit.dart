import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'payment_state.dart';

class PaymentCubit extends Cubit<PaymentState> {
  final FirebaseFirestore _db;

  PaymentCubit({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance,
        super(const PaymentState());

  void init(String userId) {
    emit(state.copyWith(userId: userId, loading: false));
  }

  void selectTier(String tier) {
    emit(state.copyWith(selectedTier: tier));
  }

  Future<void> copyWhatsAppMessageToClipboard({required String phone}) async {
    final price = state.pricesUSD[state.selectedTier] ?? 0.0;
    final msg =
        'Payment Request\nUser: ${state.userId}\nTier: ${state.selectedTier}\nAmount (USD): $price\nI am sending payment via bank transfer. Please upgrade my account to Pro. I will share the payment screenshot on WhatsApp.';
    await Clipboard.setData(ClipboardData(text: 'WhatsApp: $phone\n\n$msg'));
    emit(state.copyWith(message: 'Copied details to clipboard'));
  }

  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    emit(state.copyWith(message: 'Copied to clipboard')); 
  }

  Future<void> openWhatsApp({required String phone}) async {
    final price = state.pricesUSD[state.selectedTier] ?? 0.0;
    final rawMsg = 'Hello, I have sent the payment.\nUser: ${state.userId}\nPlan: ${state.selectedTier}\nAmount (USD): ${price.toStringAsFixed(2)}\nPlease upgrade my account to Pro. I am sharing the payment screenshot.';
    final msg = Uri.encodeComponent(rawMsg);
    final tel = phone.replaceAll('+', '').replaceAll(' ', '');

    // Try multiple deep link options in order of preference
    final candidates = <Uri>[
      // WhatsApp (consumer/business both respond to scheme)
      Uri.parse('whatsapp://send?phone=$tel&text=$msg'),
      // HTTPS fallbacks
      Uri.parse('https://wa.me/$tel?text=$msg'),
      Uri.parse('https://api.whatsapp.com/send?phone=$tel&text=$msg'),
      // Android intents (explicit packages)
      Uri.parse('intent://send?phone=$tel&text=$msg#Intent;scheme=whatsapp;package=com.whatsapp.w4b;end'),
      Uri.parse('intent://send?phone=$tel&text=$msg#Intent;scheme=whatsapp;package=com.whatsapp;end'),
      // Play Store fallbacks (if not installed)
      Uri.parse('market://details?id=com.whatsapp.w4b'),
      Uri.parse('market://details?id=com.whatsapp'),
      Uri.parse('https://play.google.com/store/apps/details?id=com.whatsapp.w4b'),
      Uri.parse('https://play.google.com/store/apps/details?id=com.whatsapp'),
    ];

    // Helper with 1s timeout per attempt
    Future<bool> tryLaunchUrl(Uri uri, LaunchMode mode) async {
      try {
        final can = await canLaunchUrl(uri);
        if (!can) return false;
        final launched = await launchUrl(uri, mode: mode)
            .timeout(const Duration(seconds: 1), onTimeout: () => false);
        return launched;
      } catch (_) {
        return false;
      }
    }

    for (final uri in candidates) {
      // Prefer non-browser applications (WhatsApp app) for faster handoff
      if (await tryLaunchUrl(uri, LaunchMode.externalNonBrowserApplication)) {
        emit(state.copyWith(message: 'Opening WhatsApp...'));
        return;
      }
      // Fallback to externalApplication (may open chooser/browser)
      if (await tryLaunchUrl(uri, LaunchMode.externalApplication)) {
        emit(state.copyWith(message: 'Opening WhatsApp...'));
        return;
      }
    }

    // Graceful fallback: copy message and instruct user
    await Clipboard.setData(ClipboardData(text: 'WhatsApp: $phone\n\n$rawMsg'));
    emit(state.copyWith(
      error: 'Could not open WhatsApp automatically. The message has been copied to clipboard. Open WhatsApp and paste to proceed.',
      message: null,
    ));
  }

  Future<void> submitPaymentRequest({required String bankRef}) async {
    if (state.userId == null) return;
    emit(state.copyWith(submitting: true, error: null, message: null));
    try {
      final amount = state.pricesUSD[state.selectedTier] ?? 0.0;
      await _db.collection('payments').add({
        'userId': state.userId,
        'tier': state.selectedTier, // monthly | quarterly | semiannual | yearly
        'amountUSD': amount,
        'bankReference': bankRef,
        'status': 'pending', // admin will verify and set Pro
        'createdAt': FieldValue.serverTimestamp(),
      });
      emit(state.copyWith(submitting: false, message: 'Payment request submitted'));
    } catch (e) {
      emit(state.copyWith(submitting: false, error: e.toString()));
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'ai_services_state.dart';

class AiServicesCubit extends Cubit<AiServicesState> {
  AiServicesCubit() : super(AiServicesInitial());

  void load() {
    // If you have categories in Firestore later, fetch and map them here.
    final categories = <AiServiceCategory>[
      const AiServiceCategory(
        title: 'Generative AI',
        description: 'Text, image and video generation',
        icon: Icons.auto_awesome,
        color: Colors.purple,
        image: 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?auto=format&fit=crop&w=800&q=80',
      ),
      const AiServiceCategory(
        title: 'LLM Apps',
        description: 'GPT-powered assistants and tools',
        icon: Icons.smart_toy,
        color: Colors.blue,
        image: 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=800&q=80',
      ),
      const AiServiceCategory(
        title: 'RAG Pipelines',
        description: 'Search + LLM with vector DBs',
        icon: Icons.find_in_page,
        color: Colors.indigo,
        image: 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=800&q=80',
      ),
      const AiServiceCategory(
        title: 'Chatbots',
        description: 'Customer and internal support bots',
        icon: Icons.chat_bubble_outline,
        color: Colors.teal,
        image: 'https://images.unsplash.com/photo-1554224155-6726b3ff858f?auto=format&fit=crop&w=800&q=80',
      ),
      const AiServiceCategory(
        title: 'Computer Vision',
        description: 'Detection, OCR, image analytics',
        icon: Icons.visibility,
        color: Colors.orange,
        image: 'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?auto=format&fit=crop&w=800&q=80',
      ),
      const AiServiceCategory(
        title: 'Speech AI',
        description: 'ASR, TTS, voicebots',
        icon: Icons.record_voice_over,
        color: Colors.redAccent,
        image: 'https://images.unsplash.com/photo-1521737852567-6949f3f9f2b5?auto=format&fit=crop&w=800&q=80',
      ),
      const AiServiceCategory(
        title: 'NLP',
        description: 'Classification, NER, summarization',
        icon: Icons.psychology,
        color: Colors.green,
        image: 'https://images.unsplash.com/photo-1620712943543-bcc4688e7485?auto=format&fit=crop&w=800&q=80',
      ),
      const AiServiceCategory(
        title: 'Recommendations',
        description: 'Personalization and ranking',
        icon: Icons.recommend,
        color: Colors.cyan,
        image: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80',
      ),
      const AiServiceCategory(
        title: 'Anomaly Detection',
        description: 'Fraud, risk, outlier detection',
        icon: Icons.warning_amber,
        color: Colors.deepOrange,
        image: 'https://images.unsplash.com/photo-1503676382389-4809596d5290?auto=format&fit=crop&w=800&q=80',
      ),
      const AiServiceCategory(
        title: 'Forecasting',
        description: 'Demand and time-series models',
        icon: Icons.trending_up,
        color: Colors.lightBlue,
        image: 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&w=800&q=80',
      ),
      const AiServiceCategory(
        title: 'MLOps',
        description: 'CI/CD, monitoring, governance',
        icon: Icons.settings_suggest,
        color: Colors.brown,
        image: 'https://images.unsplash.com/photo-1554224155-6726b3ff858f?auto=format&fit=crop&w=800&q=80',
      ),
      const AiServiceCategory(
        title: 'Model Hosting',
        description: 'Serving and scaling models',
        icon: Icons.cloud,
        color: Colors.blueGrey,
        image: 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?auto=format&fit=crop&w=800&q=80',
      ),
      const AiServiceCategory(
        title: 'Edge AI',
        description: 'On-device inference',
        icon: Icons.memory,
        color: Colors.deepPurple,
        image: 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=800&q=80',
      ),
      const AiServiceCategory(
        title: 'Document AI',
        description: 'Docs extraction, parsing, OCR',
        icon: Icons.description,
        color: Colors.amber,
        image: 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=800&q=80',
      ),
      const AiServiceCategory(
        title: 'Agent Workflows',
        description: 'Multi-agent automations',
        icon: Icons.hub,
        color: Colors.pink,
        image: 'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?auto=format&fit=crop&w=800&q=80',
      ),
      const AiServiceCategory(
        title: 'Code Assist',
        description: 'AI code review and generation',
        icon: Icons.code,
        color: Colors.greenAccent,
        image: 'https://images.unsplash.com/photo-1554224155-6726b3ff858f?auto=format&fit=crop&w=800&q=80',
      ),
      const AiServiceCategory(
        title: 'Fraud Detection',
        description: 'Payments, identity, risk',
        icon: Icons.verified_user,
        color: Colors.red,
        image: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80',
      ),
    ];

    emit(AiServicesLoaded(categories));
  }
}

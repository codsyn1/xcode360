import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'popup_admin_cubit.dart';
import 'popup_admin_state.dart';

class PopupAdminScreen extends StatelessWidget {
  const PopupAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PopupAdminCubit()..refreshOnce(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Admin • Popup Image')),
        body: BlocBuilder<PopupAdminCubit, PopupAdminState>(
          builder: (context, state) {
            final cubit = context.read<PopupAdminCubit>();
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => cubit.uploadPopupImage(),
                        icon: const Icon(Icons.upload),
                        label: const Text('Upload Popup Image'),
                      ),
                      const SizedBox(width: 12),
                      Row(children: [
                        const Text('Active'),
                        const SizedBox(width: 8),
                        Switch(
                          value: state.active,
                          onChanged: (v) => cubit.setActive(v),
                        ),
                      ]),
                      if (state.loading) ...[
                        const SizedBox(width: 12),
                        const CircularProgressIndicator(),
                      ],
                      if (state.error != null) ...[
                        const SizedBox(width: 12),
                        Expanded(child: Text(state.error!, style: const TextStyle(color: Colors.red))),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: state.imageUrl == null || state.imageUrl!.isEmpty
                          ? const Text('No popup image configured.')
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(state.imageUrl!, height: 300, fit: BoxFit.contain),
                                ),
                                const SizedBox(height: 12),
                                Text('Visible: ${state.active ? 'Yes' : 'No'}'),
                              ],
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

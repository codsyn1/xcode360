import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'slider_admin_cubit.dart';
import 'slider_admin_state.dart';

class SliderAdminScreen extends StatelessWidget {
  const SliderAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SliderAdminCubit()..refreshOnce(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Admin • Slider Images')),
        body: BlocBuilder<SliderAdminCubit, SliderAdminState>(
          builder: (context, state) {
            final cubit = context.read<SliderAdminCubit>();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => cubit.uploadNewImage(),
                        icon: const Icon(Icons.upload),
                        label: const Text('Upload Image'),
                      ),
                      const SizedBox(width: 12),
                      if (state.loading) const CircularProgressIndicator(),
                      if (state.error != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(state.error!, style: const TextStyle(color: Colors.red)),
                        ),
                      ]
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<SliderImageItem>>(
                    stream: context.read<SliderAdminCubit>().listenItems(),
                    builder: (context, snap) {
                      final items = snap.data ?? state.items;
                      if (snap.connectionState == ConnectionState.waiting && items.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (items.isEmpty) {
                        return const Center(child: Text('No slider images. Upload to add.'));
                      }
                      return ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final it = items[index];
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(it.url, width: 64, height: 64, fit: BoxFit.cover),
                            ),
                            title: Text('Order: ${it.order}'),
                            subtitle: Text(it.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: it.active,
                                  onChanged: (v) => context.read<SliderAdminCubit>().toggleActive(it.id, v),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => context.read<SliderAdminCubit>().deleteImage(it.id),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

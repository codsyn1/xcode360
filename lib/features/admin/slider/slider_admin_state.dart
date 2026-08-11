import 'package:equatable/equatable.dart';

class SliderImageItem extends Equatable {
  final String id;
  final String url;
  final int order;
  final bool active;

  const SliderImageItem({required this.id, required this.url, required this.order, required this.active});

  @override
  List<Object?> get props => [id, url, order, active];
}

class SliderAdminState extends Equatable {
  final bool loading;
  final List<SliderImageItem> items;
  final String? error;

  const SliderAdminState({this.loading = false, this.items = const [], this.error});

  SliderAdminState copyWith({bool? loading, List<SliderImageItem>? items, String? error}) {
    return SliderAdminState(
      loading: loading ?? this.loading,
      items: items ?? this.items,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, items, error];
}

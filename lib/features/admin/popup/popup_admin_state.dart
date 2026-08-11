import 'package:equatable/equatable.dart';

class PopupAdminState extends Equatable {
  final bool loading;
  final String? imageUrl;
  final bool active;
  final String? error;

  const PopupAdminState({this.loading = false, this.imageUrl, this.active = false, this.error});

  PopupAdminState copyWith({bool? loading, String? imageUrl, bool? active, String? error}) {
    return PopupAdminState(
      loading: loading ?? this.loading,
      imageUrl: imageUrl ?? this.imageUrl,
      active: active ?? this.active,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, imageUrl, active, error];
}

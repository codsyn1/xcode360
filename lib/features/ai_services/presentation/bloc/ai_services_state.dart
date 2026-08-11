import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class AiServiceCategory extends Equatable {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String image;

  const AiServiceCategory({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.image,
  });

  @override
  List<Object?> get props => [title, description, icon, color, image];

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'icon': icon,
        'color': color,
        'image': image,
      };
}

abstract class AiServicesState extends Equatable {
  const AiServicesState();
  @override
  List<Object?> get props => [];
}

class AiServicesInitial extends AiServicesState {}

class AiServicesLoaded extends AiServicesState {
  final List<AiServiceCategory> categories;
  const AiServicesLoaded(this.categories);
  @override
  List<Object?> get props => [categories];
}

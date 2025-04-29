import 'package:equatable/equatable.dart';

class SliderData extends Equatable {
  final String name;
  final double min;
  final double max;

  const SliderData({required this.name, this.min = 0.0, this.max = 1.0});

  @override
  List<Object> get props => [name, min, max];

  @override
  bool get stringify => true;

  SliderData copyWith({String? name, double? min, double? max}) {
    return SliderData(
      name: name ?? this.name,
      min: min ?? this.min,
      max: max ?? this.max,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'min': min,
      'max': max,
    };
  }

  factory SliderData.fromJson(Map<String, dynamic> json) {
    return SliderData(
      name: json['name'] as String,
      min: json['min']?.toDouble() ?? 0.0,
      max: json['max']?.toDouble() ?? 1.0,
    );
  }
}
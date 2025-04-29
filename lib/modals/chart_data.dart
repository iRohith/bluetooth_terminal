import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ChartVariable {
  final int id;
  final String name;
  final Color color;

  const ChartVariable(this.id, this.name, this.color);

  ChartVariable copyWith({int? id, Color? color, String? name}) {
    return ChartVariable(id ?? this.id, name ?? this.name, color ?? this.color);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'color': color.toARGB32()};
  }

  factory ChartVariable.fromJson(Map<String, dynamic> json) {
    return ChartVariable(
      json['id'] as int,
      json['name'] as String,
      Color(json['color'] as int),
    );
  }
}

class ChartData extends Equatable {
  final String name;
  final double minY;
  final double maxY;
  final double maxDuration;
  final double updateInterval;

  final List<ChartVariable> variables;

  const ChartData({
    required this.name,
    required this.variables,
    this.maxDuration = 10,
    this.updateInterval = 0.001,
    this.minY = 0.0,
    this.maxY = 1.0,
  });

  @override
  List<Object> get props => [name, minY, maxY, maxDuration, variables, updateInterval];

  @override
  bool get stringify => true;

  ChartData copyWith({
    String? name,
    List<ChartVariable>? variables,
    double? maxDuration,
    double? updateInterval,
    double? minY,
    double? maxY,
  }) {
    return ChartData(
      name: name ?? this.name,
      variables: variables ?? this.variables,
      maxDuration: maxDuration ?? this.maxDuration,
      updateInterval: updateInterval ?? this.updateInterval,
      minY: minY ?? this.minY,
      maxY: maxY ?? this.maxY,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'maxDuration': maxDuration,
      'updateInterval': updateInterval,
      'minY': minY,
      'maxY': maxY,
      'variables': variables.map((v) => v.toJson()).toList(),
    };
  }

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      name: json['name'] as String,
      maxDuration: json['maxDuration']?.toDouble() ?? 10.0,
      updateInterval: json['updateInterval']?.toDouble() ?? 0.01,
      minY: json['minY']?.toDouble() ?? 0.0,
      maxY: json['maxY']?.toDouble() ?? 1.0,
      variables: (json['variables'] as List).map((v) => ChartVariable.fromJson(v)).toList(),
    );
  }
}

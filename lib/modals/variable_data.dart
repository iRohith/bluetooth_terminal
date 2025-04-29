class VariableData {
  final int id;
  final String name;
  final double value;

  VariableData(this.id, this.name, {this.value = 0});

  VariableData copyWith({int? id, String? name, double? value}) {
    return VariableData(
      id ?? this.id,
      name ?? this.name,
      value: value ?? this.value,
    );
  }
}

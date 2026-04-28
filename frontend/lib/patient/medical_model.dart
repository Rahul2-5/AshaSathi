class MedicalCondition {
  final String id;
  final String label;
  bool selected;

  MedicalCondition({
    required this.id,
    required this.label,
    this.selected = false,
  });

  MedicalCondition copyWith({
    String? id,
    String? label,
    bool? selected,
  }) {
    return MedicalCondition(
      id: id ?? this.id,
      label: label ?? this.label,
      selected: selected ?? this.selected,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'selected': selected,
    };
  }

  factory MedicalCondition.fromJson(Map<String, dynamic> json) {
    return MedicalCondition(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      selected: json['selected'] ?? false,
    );
  }

  static List<MedicalCondition> getDefaultConditions() {
    return [
      MedicalCondition(id: 'bp', label: 'BP'),
      MedicalCondition(id: 'elephantiasis', label: 'Elephantiasis'),
      MedicalCondition(id: 'diabetes', label: 'Diabetes'),
      MedicalCondition(id: 'heart_disease', label: 'Heart Disease'),
      MedicalCondition(id: 'asthma', label: 'Asthma'),
      MedicalCondition(id: 'thyroid', label: 'Thyroid'),
      MedicalCondition(id: 'arthritis', label: 'Arthritis'),
      MedicalCondition(id: 'kidney_disease', label: 'Kidney Disease'),
      MedicalCondition(id: 'liver_disease', label: 'Liver Disease'),
      MedicalCondition(id: 'cancer', label: 'Cancer'),
    ];
  }
}

class PatientMedicalInfo {
  bool refusedToShare;
  List<MedicalCondition> conditions;
  String notes;

  PatientMedicalInfo({
    this.refusedToShare = false,
    List<MedicalCondition>? conditions,
    this.notes = '',
  }) : conditions = conditions ?? MedicalCondition.getDefaultConditions();

  PatientMedicalInfo copyWith({
    bool? refusedToShare,
    List<MedicalCondition>? conditions,
    String? notes,
  }) {
    return PatientMedicalInfo(
      refusedToShare: refusedToShare ?? this.refusedToShare,
      conditions: conditions ?? this.conditions,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'refusedToShare': refusedToShare,
      'conditions': conditions.where((c) => c.selected).map((c) => c.id).toList(),
      'notes': notes,
    };
  }

  factory PatientMedicalInfo.fromJson(Map<String, dynamic> json) {
    final conditions = MedicalCondition.getDefaultConditions();
    final selectedIds = List<String>.from(json['conditions'] ?? []);
    
    for (var condition in conditions) {
      condition.selected = selectedIds.contains(condition.id);
    }

    return PatientMedicalInfo(
      refusedToShare: json['refusedToShare'] ?? false,
      conditions: conditions,
      notes: json['notes'] ?? '',
    );
  }
}

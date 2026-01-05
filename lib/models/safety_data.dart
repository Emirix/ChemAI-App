class SafetyData {
  final String chemicalName;
  final String casNumber;
  final SupplierInformation supplierInformation;
  final String description;
  final List<Composition> composition;
  final List<Hazard> hazards;
  final ExposureControls exposureControls;
  final List<PPE> ppe;
  final List<Property> properties;
  final String handling;
  final String storage;
  final List<String> firstAid;
  final List<String> firefighting;
  final String accidentalRelease; // Section 6
  final String stabilityAndReactivity; // Section 10
  final String toxicologicalInformation; // Section 11
  final String ecologicalInformation; // Section 12
  final String disposalConsiderations; // Section 13
  final String transportInformation; // Section 14
  final String regulatoryInformation; // Section 15
  final RevisionInformation revisionInformation; // Section 16
  final RiskAlert riskAlert;

  SafetyData({
    required this.chemicalName,
    required this.casNumber,
    required this.supplierInformation,
    required this.description,
    required this.composition,
    required this.hazards,
    required this.exposureControls,
    required this.ppe,
    required this.properties,
    required this.handling,
    required this.storage,
    required this.firstAid,
    required this.firefighting,
    this.accidentalRelease = 'Mevcut veri yok',
    this.stabilityAndReactivity = 'Mevcut veri yok',
    this.toxicologicalInformation = 'Mevcut veri yok',
    this.ecologicalInformation = 'Mevcut veri yok',
    this.disposalConsiderations = 'Mevcut veri yok',
    this.transportInformation = 'Mevcut veri yok',
    this.regulatoryInformation = 'Mevcut veri yok',
    required this.revisionInformation,
    required this.riskAlert,
  });

  factory SafetyData.fromJson(Map<String, dynamic> json) {
    return SafetyData(
      chemicalName: json['chemicalName'] ?? '',
      casNumber: json['casNumber'] ?? '',
      supplierInformation: SupplierInformation.fromJson(
        json['supplierInformation'] ?? {},
      ),
      description: json['description'] ?? '',
      composition: (json['composition'] as List? ?? [])
          .map((item) => Composition.fromJson(item))
          .toList(),
      hazards: (json['hazards'] as List? ?? [])
          .map((item) => Hazard.fromJson(item))
          .toList(),
      exposureControls: ExposureControls.fromJson(
        json['exposureControls'] ?? {},
      ),
      ppe: (json['ppe'] as List? ?? [])
          .map((item) => PPE.fromJson(item))
          .toList(),
      properties: (json['properties'] as List? ?? [])
          .map((item) => Property.fromJson(item))
          .toList(),
      handling: json['handling'] ?? '',
      storage: json['storage'] ?? '',
      firstAid: List<String>.from(json['firstAid'] ?? []),
      firefighting: List<String>.from(json['firefighting'] ?? []),
      accidentalRelease:
          json['accidentalRelease'] ?? 'Uygulanamaz veya veri yok',
      stabilityAndReactivity:
          json['stabilityAndReactivity'] ?? 'Normal koşullarda kararlı.',
      toxicologicalInformation:
          json['toxicologicalInformation'] ?? 'Spesifik veri bulunamadı.',
      ecologicalInformation:
          json['ecologicalInformation'] ?? 'Çevreye kontrolsüz verilmemelidir.',
      disposalConsiderations:
          json['disposalConsiderations'] ??
          'Yerel yönetmeliklere göre bertaraf edin.',
      transportInformation:
          json['transportInformation'] ??
          'Tehlikeli madde taşımacılığı kurallarına bakın (ADR/RID).',
      regulatoryInformation:
          json['regulatoryInformation'] ??
          'KKDİK ve SEA yönetmeliklerine uygun etiketlenmelidir.',
      revisionInformation: RevisionInformation.fromJson(
        json['revisionInformation'] ?? {},
      ),
      riskAlert: RiskAlert.fromJson(json['riskAlert'] ?? {}),
    );
  }

  SafetyData copyWith({RevisionInformation? revisionInformation}) {
    return SafetyData(
      chemicalName: chemicalName,
      casNumber: casNumber,
      supplierInformation: supplierInformation,
      description: description,
      composition: composition,
      hazards: hazards,
      exposureControls: exposureControls,
      ppe: ppe,
      properties: properties,
      handling: handling,
      storage: storage,
      firstAid: firstAid,
      firefighting: firefighting,
      accidentalRelease: accidentalRelease,
      stabilityAndReactivity: stabilityAndReactivity,
      toxicologicalInformation: toxicologicalInformation,
      ecologicalInformation: ecologicalInformation,
      disposalConsiderations: disposalConsiderations,
      transportInformation: transportInformation,
      regulatoryInformation: regulatoryInformation,
      revisionInformation: revisionInformation ?? this.revisionInformation,
      riskAlert: riskAlert,
    );
  }
}

class SupplierInformation {
  final String companyName;
  final String address;
  final String phone;
  final String emergencyPhone;

  SupplierInformation({
    required this.companyName,
    required this.address,
    required this.phone,
    required this.emergencyPhone,
  });

  factory SupplierInformation.fromJson(Map<String, dynamic> json) {
    return SupplierInformation(
      companyName: json['companyName'] ?? 'Uygulanamaz',
      address: json['address'] ?? 'Mevcut veri yok',
      phone: json['phone'] ?? 'Mevcut veri yok',
      emergencyPhone: json['emergencyPhone'] ?? '112',
    );
  }
}

class Composition {
  final String componentName;
  final String casNumber;
  final String concentration;
  final String classification;

  Composition({
    required this.componentName,
    required this.casNumber,
    required this.concentration,
    required this.classification,
  });

  factory Composition.fromJson(Map<String, dynamic> json) {
    return Composition(
      componentName: json['componentName'] ?? '',
      casNumber: json['casNumber'] ?? '',
      concentration: json['concentration'] ?? 'Uygulanamaz',
      classification: json['classification'] ?? '',
    );
  }
}

class ExposureControls {
  final String occupationalExposureLimit;
  final String engineeringControls;
  final String ppeNotes;

  ExposureControls({
    required this.occupationalExposureLimit,
    required this.engineeringControls,
    required this.ppeNotes,
  });

  factory ExposureControls.fromJson(Map<String, dynamic> json) {
    return ExposureControls(
      occupationalExposureLimit:
          json['occupationalExposureLimit'] ?? 'Mevcut veri yok',
      engineeringControls: json['engineeringControls'] ?? 'Mevcut veri yok',
      ppeNotes: json['ppeNotes'] ?? 'Mevcut veri yok',
    );
  }
}

class RevisionInformation {
  final String sdsVersion;
  final String revisionDate;
  final String changes;

  RevisionInformation({
    required this.sdsVersion,
    required this.revisionDate,
    required this.changes,
  });

  factory RevisionInformation.fromJson(Map<String, dynamic> json) {
    return RevisionInformation(
      sdsVersion: json['sdsVersion'] ?? '1.0',
      revisionDate:
          json['revisionDate'] ?? DateTime.now().toString().substring(0, 10),
      changes: json['changes'] ?? 'İlk yayın',
    );
  }
}

class Hazard {
  final String type;
  final String label;
  final String signalWord;
  final List<String> pictograms;
  final String description;

  Hazard({
    required this.type,
    required this.label,
    required this.signalWord,
    required this.pictograms,
    required this.description,
  });

  factory Hazard.fromJson(Map<String, dynamic> json) {
    return Hazard(
      type: json['type'] ?? '',
      label: json['label'] ?? '',
      signalWord: json['signalWord'] ?? 'Dikkat',
      pictograms: List<String>.from(json['pictograms'] ?? []),
      description: json['description'] ?? '',
    );
  }
}

class PPE {
  final String type;
  final String label;

  PPE({required this.type, required this.label});

  factory PPE.fromJson(Map<String, dynamic> json) {
    return PPE(type: json['type'] ?? '', label: json['label'] ?? '');
  }
}

class Property {
  final String label;
  final String value;

  Property({required this.label, required this.value});

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(label: json['label'] ?? '', value: json['value'] ?? '');
  }
}

class RiskAlert {
  final bool hasAlert;
  final String title;
  final String description;

  RiskAlert({
    required this.hasAlert,
    required this.title,
    required this.description,
  });

  factory RiskAlert.fromJson(Map<String, dynamic> json) {
    return RiskAlert(
      hasAlert: json['hasAlert'] ?? false,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

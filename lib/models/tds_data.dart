class TdsData {
  final String productName;
  final String subtitle;
  final String category;
  final ProductIdentity identity;
  final List<PhysicalProperty> physicalProperties;
  final List<TechnicalSpec> technicalSpecs;
  final StorageInfo storageInfo;
  final SafetyWarnings safetyWarnings;
  final SupplierInformation supplierInformation;
  final DocumentInformation documentInformation;
  final RegulatoryCompliance regulatoryCompliance;
  final TransportInformation transportInformation;

  TdsData({
    required this.productName,
    required this.subtitle,
    required this.category,
    required this.identity,
    required this.physicalProperties,
    required this.technicalSpecs,
    required this.storageInfo,
    required this.safetyWarnings,
    required this.supplierInformation,
    required this.documentInformation,
    required this.regulatoryCompliance,
    required this.transportInformation,
  });

  factory TdsData.fromJson(Map<String, dynamic> json) {
    return TdsData(
      productName: json['productName'] ?? '',
      subtitle: json['subtitle'] ?? '',
      category: json['category'] ?? '',
      identity: ProductIdentity.fromJson(json['identity'] ?? {}),
      physicalProperties: (json['physicalProperties'] as List? ?? [])
          .map((item) => PhysicalProperty.fromJson(item))
          .toList(),
      technicalSpecs: (json['technicalSpecs'] as List? ?? [])
          .map((item) => TechnicalSpec.fromJson(item))
          .toList(),
      storageInfo: StorageInfo.fromJson(json['storageInfo'] ?? {}),
      safetyWarnings: SafetyWarnings.fromJson(json['safetyWarnings'] ?? {}),
      supplierInformation: SupplierInformation.fromJson(
        json['supplierInformation'] ?? {},
      ),
      documentInformation: DocumentInformation.fromJson(
        json['documentInformation'] ?? {},
      ),
      regulatoryCompliance: RegulatoryCompliance.fromJson(
        json['regulatoryCompliance'] ?? {},
      ),
      transportInformation: TransportInformation.fromJson(
        json['transportInformation'] ?? {},
      ),
    );
  }
}

class ProductIdentity {
  final String casNumber;
  final String ecNumber;
  final String formula;
  final String molecularWeight;

  ProductIdentity({
    required this.casNumber,
    required this.ecNumber,
    required this.formula,
    required this.molecularWeight,
  });

  factory ProductIdentity.fromJson(Map<String, dynamic> json) {
    return ProductIdentity(
      casNumber: json['casNumber'] ?? '-',
      ecNumber: json['ecNumber'] ?? '-',
      formula: json['formula'] ?? '-',
      molecularWeight: json['molecularWeight'] ?? '-',
    );
  }
}

class PhysicalProperty {
  final String label;
  final String value;

  PhysicalProperty({required this.label, required this.value});

  factory PhysicalProperty.fromJson(Map<String, dynamic> json) {
    return PhysicalProperty(
      label: json['label'] ?? '',
      value: json['value'] ?? '',
    );
  }
}

class TechnicalSpec {
  final String label;
  final String value;

  TechnicalSpec({required this.label, required this.value});

  factory TechnicalSpec.fromJson(Map<String, dynamic> json) {
    return TechnicalSpec(
      label: json['label'] ?? '',
      value: json['value'] ?? '',
    );
  }
}

class StorageInfo {
  final List<String> conditions;
  final String shelfLife;

  StorageInfo({required this.conditions, required this.shelfLife});

  factory StorageInfo.fromJson(Map<String, dynamic> json) {
    return StorageInfo(
      conditions: List<String>.from(json['conditions'] ?? []),
      shelfLife: json['shelfLife'] ?? '-',
    );
  }
}

class SafetyWarnings {
  final List<String> ghsLabels;
  final String hazardStatement;
  final String ghsTitle;

  SafetyWarnings({
    required this.ghsLabels,
    required this.hazardStatement,
    required this.ghsTitle,
  });

  factory SafetyWarnings.fromJson(Map<String, dynamic> json) {
    return SafetyWarnings(
      ghsLabels: List<String>.from(json['ghsLabels'] ?? []),
      hazardStatement: json['hazardStatement'] ?? '',
      ghsTitle: json['ghsTitle'] ?? 'GHS İşaretleri',
    );
  }
}

class SupplierInformation {
  final String companyName;
  final String address;
  final String phone;
  final String email;
  final String website;

  SupplierInformation({
    required this.companyName,
    required this.address,
    required this.phone,
    required this.email,
    required this.website,
  });

  factory SupplierInformation.fromJson(Map<String, dynamic> json) {
    return SupplierInformation(
      companyName: json['companyName'] ?? 'Mevcut veri yok',
      address: json['address'] ?? 'Mevcut veri yok',
      phone: json['phone'] ?? 'Mevcut veri yok',
      email: json['email'] ?? 'Mevcut veri yok',
      website: json['website'] ?? 'Mevcut veri yok',
    );
  }
}

class DocumentInformation {
  final String documentNumber;
  final String revisionNumber;
  final String issueDate;
  final String supersedes;

  DocumentInformation({
    required this.documentNumber,
    required this.revisionNumber,
    required this.issueDate,
    required this.supersedes,
  });

  factory DocumentInformation.fromJson(Map<String, dynamic> json) {
    return DocumentInformation(
      documentNumber: json['documentNumber'] ?? 'TDS-001',
      revisionNumber: json['revisionNumber'] ?? 'Rev. 1.0',
      issueDate: json['issueDate'] ?? DateTime.now().toString().split(' ')[0],
      supersedes: json['supersedes'] ?? 'İlk Yayın',
    );
  }
}

class RegulatoryCompliance {
  final String reach;
  final String kkdik;
  final List<String> standards;

  RegulatoryCompliance({
    required this.reach,
    required this.kkdik,
    required this.standards,
  });

  factory RegulatoryCompliance.fromJson(Map<String, dynamic> json) {
    return RegulatoryCompliance(
      reach: json['reach'] ?? 'Mevcut veri yok',
      kkdik: json['kkdik'] ?? 'Mevcut veri yok',
      standards: List<String>.from(json['standards'] ?? []),
    );
  }
}

class TransportInformation {
  final String unNumber;
  final String properShippingName;
  final String transportClass;
  final String packingGroup;

  TransportInformation({
    required this.unNumber,
    required this.properShippingName,
    required this.transportClass,
    required this.packingGroup,
  });

  factory TransportInformation.fromJson(Map<String, dynamic> json) {
    return TransportInformation(
      unNumber: json['unNumber'] ?? 'Uygulanamaz',
      properShippingName: json['properShippingName'] ?? 'Uygulanamaz',
      transportClass: json['transportClass'] ?? 'Uygulanamaz',
      packingGroup: json['packingGroup'] ?? 'Uygulanamaz',
    );
  }
}

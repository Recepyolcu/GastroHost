enum DocumentType {
  identity,
  hygieneCert,
  diploma,
  portfolio,
  other;

  String toDbString() {
    switch (this) {
      case DocumentType.identity:
        return 'identity';
      case DocumentType.hygieneCert:
        return 'hygiene_cert';
      case DocumentType.diploma:
        return 'diploma';
      case DocumentType.portfolio:
        return 'portfolio';
      case DocumentType.other:
        return 'other';
    }
  }

  static DocumentType fromString(String val) {
    switch (val) {
      case 'identity':
        return DocumentType.identity;
      case 'hygiene_cert':
        return DocumentType.hygieneCert;
      case 'diploma':
        return DocumentType.diploma;
      case 'portfolio':
        return DocumentType.portfolio;
      default:
        return DocumentType.other;
    }
  }
}

enum DocumentStatus {
  pending,
  approved,
  rejected;

  String toDbString() => name;

  static DocumentStatus fromString(String val) {
    switch (val) {
      case 'approved':
        return DocumentStatus.approved;
      case 'rejected':
        return DocumentStatus.rejected;
      default:
        return DocumentStatus.pending;
    }
  }
}

class ProviderDocument {
  final String id;
  final String providerId;
  final DocumentType documentType;
  final String fileUrl;
  final DocumentStatus status;
  final String? rejectionReason;
  final DateTime createdAt;

  ProviderDocument({
    required this.id,
    required this.providerId,
    required this.documentType,
    required this.fileUrl,
    this.status = DocumentStatus.pending,
    this.rejectionReason,
    required this.createdAt,
  });

  factory ProviderDocument.fromJson(Map<String, dynamic> json) {
    return ProviderDocument(
      id: json['id'] as String,
      providerId: json['provider_id'] as String,
      documentType: DocumentType.fromString(json['document_type'] as String),
      fileUrl: json['file_url'] as String,
      status: DocumentStatus.fromString(json['status'] as String? ?? 'pending'),
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider_id': providerId,
      'document_type': documentType.toDbString(),
      'file_url': fileUrl,
      'status': status.toDbString(),
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

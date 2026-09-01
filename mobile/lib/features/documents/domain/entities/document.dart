import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class DocumentType extends Equatable {
  const DocumentType._(this.apiValue, this.label, this.icon);

  final String apiValue;
  final String label;
  final IconData icon;

  static const DocumentType cnic = DocumentType._(
    'CNIC',
    'CNIC',
    Icons.badge_outlined,
  );
  static const DocumentType passport = DocumentType._(
    'PASSPORT',
    'Passport',
    Icons.menu_book_outlined,
  );
  static const DocumentType contract = DocumentType._(
    'CONTRACT',
    'Contract',
    Icons.article_outlined,
  );
  static const DocumentType offerLetter = DocumentType._(
    'OFFER_LETTER',
    'Offer letter',
    Icons.mail_outline,
  );
  static const DocumentType resume = DocumentType._(
    'RESUME',
    'Resume',
    Icons.description_outlined,
  );
  static const DocumentType educationCertificate = DocumentType._(
    'EDUCATION_CERTIFICATE',
    'Education certificate',
    Icons.school_outlined,
  );
  static const DocumentType education = DocumentType._(
    'EDUCATION',
    'Education',
    Icons.school_outlined,
  );
  static const DocumentType experienceLetter = DocumentType._(
    'EXPERIENCE_LETTER',
    'Experience letter',
    Icons.work_outline,
  );
  static const DocumentType experience = DocumentType._(
    'EXPERIENCE',
    'Experience',
    Icons.work_outline,
  );
  static const DocumentType certificate = DocumentType._(
    'CERTIFICATE',
    'Certificate',
    Icons.workspace_premium_outlined,
  );
  static const DocumentType salaryDocument = DocumentType._(
    'SALARY_DOCUMENT',
    'Salary document',
    Icons.payments_outlined,
  );
  static const DocumentType bankDocument = DocumentType._(
    'BANK_DOCUMENT',
    'Bank document',
    Icons.account_balance_outlined,
  );
  static const DocumentType taxDocument = DocumentType._(
    'TAX_DOCUMENT',
    'Tax document',
    Icons.receipt_long_outlined,
  );
  static const DocumentType medicalDocument = DocumentType._(
    'MEDICAL_DOCUMENT',
    'Medical document',
    Icons.medical_information_outlined,
  );
  static const DocumentType identityDocument = DocumentType._(
    'IDENTITY_DOCUMENT',
    'Identity document',
    Icons.badge_outlined,
  );
  static const DocumentType other = DocumentType._(
    'OTHER',
    'Other',
    Icons.insert_drive_file_outlined,
  );

  static const List<DocumentType> selectable = <DocumentType>[
    cnic,
    passport,
    contract,
    offerLetter,
    resume,
    certificate,
    education,
    educationCertificate,
    experience,
    experienceLetter,
    salaryDocument,
    bankDocument,
    taxDocument,
    medicalDocument,
    identityDocument,
    other,
  ];

  static DocumentType fromApi(String? raw) {
    final String value = (raw ?? '').trim().toUpperCase();
    if (value.isEmpty) {
      return other;
    }
    for (final DocumentType type in selectable) {
      if (type.apiValue == value) {
        return type;
      }
    }
    return DocumentType._(
      value,
      value.replaceAll('_', ' '),
      Icons.insert_drive_file_outlined,
    );
  }

  bool get isImage => false;

  @override
  List<Object?> get props => <Object?>[apiValue];
}

class DocumentUserRef extends Equatable {
  const DocumentUserRef({required this.id, required this.email});

  final int id;
  final String email;

  factory DocumentUserRef.fromJson(Map<String, dynamic> json) {
    return DocumentUserRef(
      id: _readInt(json['id']),
      email: _readString(json['email']),
    );
  }

  @override
  List<Object?> get props => <Object?>[id, email];
}

class EmployeeDocument extends Equatable {
  const EmployeeDocument({
    required this.id,
    required this.companyId,
    required this.employeeId,
    required this.documentType,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    this.title = '',
    this.description = '',
    this.status = 'ACTIVE',
    this.uploadedBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String companyId;
  final String employeeId;
  final DocumentType documentType;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final String title;
  final String description;
  final String status;
  final DocumentUserRef? uploadedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isImage =>
      mimeType.startsWith('image/') ||
      fileName.toLowerCase().endsWith('.png') ||
      fileName.toLowerCase().endsWith('.jpg') ||
      fileName.toLowerCase().endsWith('.jpeg') ||
      fileName.toLowerCase().endsWith('.webp');

  bool get isPdf =>
      mimeType.contains('pdf') || fileName.toLowerCase().endsWith('.pdf');

  String get displayName => title.isNotEmpty ? title : fileName;

  factory EmployeeDocument.fromJson(Map<String, dynamic> json) {
    final Object? employee = json['employee'];
    String employeeId = _readString(json['employee_id']);
    if (employeeId.isEmpty && employee is Map) {
      employeeId = _readString(employee['id']);
    }
    final Object? uploaded = json['uploaded_by'];
    return EmployeeDocument(
      id: _readString(json['id']),
      companyId: _readString(json['company_id']),
      employeeId: employeeId,
      documentType: DocumentType.fromApi(_readString(json['document_type'])),
      fileName: _readString(json['file_name']),
      fileSize: _readInt(json['file_size']),
      mimeType: _readString(json['mime_type']),
      title: _readString(json['title']),
      description: _readString(json['description']),
      status: _readString(json['status']).isEmpty
          ? 'ACTIVE'
          : _readString(json['status']),
      uploadedBy: uploaded is Map
          ? DocumentUserRef.fromJson(Map<String, dynamic>.from(uploaded))
          : null,
      createdAt: _readDate(json['created_at']),
      updatedAt: _readDate(json['updated_at']),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        companyId,
        employeeId,
        documentType,
        fileName,
        fileSize,
        mimeType,
        title,
        uploadedBy,
        createdAt,
      ];
}

class DocumentPage<T> extends Equatable {
  const DocumentPage({
    required this.results,
    this.count = 0,
    this.next,
    this.previous,
  });

  final List<T> results;
  final int count;
  final String? next;
  final String? previous;

  bool get hasMore => next != null && next!.isNotEmpty;

  @override
  List<Object?> get props => <Object?>[results, count, next, previous];
}

class DocumentFile extends Equatable {
  const DocumentFile({
    required this.path,
    required this.name,
    required this.size,
  });

  final String path;
  final String name;
  final int size;

  @override
  List<Object?> get props => <Object?>[path, name, size];
}

class DownloadedBytes extends Equatable {
  const DownloadedBytes({
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });

  final List<int> bytes;
  final String filename;
  final String mimeType;

  @override
  List<Object?> get props => <Object?>[bytes, filename, mimeType];
}

String _readString(Object? value) {
  if (value == null) {
    return '';
  }
  return value.toString();
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _readDate(Object? value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

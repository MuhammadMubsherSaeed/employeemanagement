import 'package:equatable/equatable.dart';
import 'package:flutter_base/core/constants/app_constants.dart';
import 'package:flutter_base/features/documents/domain/entities/document.dart';

class DocumentQuery extends Equatable {
  const DocumentQuery({
    this.search = '',
    this.documentType,
    this.uploadedBy,
    this.dateFrom,
    this.dateTo,
    this.ordering = '-created_at',
    this.page = 1,
    this.pageSize = AppConstants.defaultPageSize,
  });

  final String search;
  final DocumentType? documentType;
  final int? uploadedBy;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String ordering;
  final int page;
  final int pageSize;

  int get activeFilterCount {
    int count = 0;
    if (documentType != null) {
      count++;
    }
    if (uploadedBy != null) {
      count++;
    }
    if (dateFrom != null || dateTo != null) {
      count++;
    }
    return count;
  }

  DocumentQuery copyWith({
    String? search,
    DocumentType? documentType,
    int? uploadedBy,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? ordering,
    int? page,
    int? pageSize,
    bool clearType = false,
    bool clearUploadedBy = false,
    bool clearDates = false,
  }) {
    return DocumentQuery(
      search: search ?? this.search,
      documentType: clearType ? null : (documentType ?? this.documentType),
      uploadedBy: clearUploadedBy ? null : (uploadedBy ?? this.uploadedBy),
      dateFrom: clearDates ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDates ? null : (dateTo ?? this.dateTo),
      ordering: ordering ?? this.ordering,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  DocumentQuery clearedFilters() {
    return DocumentQuery(
      search: search,
      ordering: ordering,
      page: 1,
      pageSize: pageSize,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    final Map<String, dynamic> params = <String, dynamic>{
      'ordering': ordering,
      'page': page,
      'page_size': pageSize,
    };
    if (search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    if (documentType != null) {
      params['document_type'] = documentType!.apiValue;
    }
    if (uploadedBy != null) {
      params['uploaded_by'] = uploadedBy;
    }
    if (dateFrom != null) {
      params['date_from'] = _isoDate(dateFrom!);
    }
    if (dateTo != null) {
      params['date_to'] = _isoDate(dateTo!);
    }
    return params;
  }

  String _isoDate(DateTime value) {
    final DateTime day = DateTime(value.year, value.month, value.day);
    final String month = day.month.toString().padLeft(2, '0');
    final String dayNum = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-$dayNum';
  }

  @override
  List<Object?> get props => <Object?>[
        search,
        documentType,
        uploadedBy,
        dateFrom,
        dateTo,
        ordering,
        page,
        pageSize,
      ];
}

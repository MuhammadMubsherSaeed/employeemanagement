class DocumentEndpoints {
  DocumentEndpoints._();

  static String list(String employeeId) =>
      'employees/$employeeId/documents/';

  static String detail(String employeeId, String documentId) =>
      'employees/$employeeId/documents/$documentId/';

  static String download(String employeeId, String documentId) =>
      'employees/$employeeId/documents/$documentId/download/';
}

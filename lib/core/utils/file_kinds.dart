/// Familles de fichiers reconnues pour l'affichage des pièces jointes.
enum FileKind { pdf, image, document, spreadsheet, archive, other }

abstract final class FileKinds {
  static FileKind of(String path, [String? mimeType]) {
    final ext = path.contains('.') ? path.split('.').last.toLowerCase() : '';
    final mime = mimeType?.toLowerCase() ?? '';
    if (ext == 'pdf' || mime.contains('pdf')) return FileKind.pdf;
    if (const {'jpg', 'jpeg', 'png', 'gif', 'heic', 'webp'}.contains(ext) || mime.startsWith('image/')) return FileKind.image;
    if (const {'doc', 'docx', 'odt', 'rtf', 'txt', 'md', 'pages'}.contains(ext)) return FileKind.document;
    if (const {'xls', 'xlsx', 'ods', 'csv', 'numbers'}.contains(ext)) return FileKind.spreadsheet;
    if (const {'zip', 'rar', '7z', 'tar', 'gz'}.contains(ext)) return FileKind.archive;
    return FileKind.other;
  }

  static String emoji(FileKind kind) => switch (kind) {
        FileKind.pdf => '📕',
        FileKind.image => '🖼️',
        FileKind.document => '📄',
        FileKind.spreadsheet => '📊',
        FileKind.archive => '🗜️',
        FileKind.other => '📎',
      };

  /// « 1,2 Mo » — sans dépendre d'une locale pour un ordre de grandeur.
  static String size(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} Mo';
  }
}

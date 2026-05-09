import 'dart:html' as html;

void downloadFile(String filename, String content) {
  final blob = html.Blob([content], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';
  
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  
  html.Url.revokeObjectUrl(url);
}

void downloadBytes(String filename, List<int> bytes) {
  final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';
  
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  
  html.Url.revokeObjectUrl(url);
}

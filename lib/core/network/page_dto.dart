/// Envoltura genérica para respuestas paginadas estilo Spring `Page<T>`.
///
/// Facilita el parseo del envelope `{ content: [...], totalElements, ... }`
/// que devuelve el backend en endpoints paginados.
///
/// Uso:
/// ```dart
/// final page = PageDto.fromJson(data, ProductModel.fromJson);
/// final items = page.content; // List<ProductModel>
/// ```
class PageDto<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int size;
  final int number;
  final bool first;
  final bool last;
  final bool empty;

  PageDto({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.size,
    required this.number,
    required this.first,
    required this.last,
    required this.empty,
  });

  factory PageDto.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final contentList = (json['content'] as List<dynamic>)
        .map((e) => fromItem(e as Map<String, dynamic>))
        .toList();
    return PageDto(
      content: contentList,
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
      size: json['size'] as int,
      number: json['number'] as int,
      first: json['first'] as bool,
      last: json['last'] as bool,
      empty: json['empty'] as bool,
    );
  }
}

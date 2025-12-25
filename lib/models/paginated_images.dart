import 'plant_image.dart';

class PaginatedImages {
  final List<PlantImage> items;
  final String? nextKey;

  PaginatedImages({required this.items, this.nextKey});
}

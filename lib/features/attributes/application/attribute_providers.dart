import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/models/models.dart';

final plantAttributesProvider =
    StreamProvider.autoDispose.family<List<PlantAttribute>, String>((ref, plantId) => ref.watch(attributeRepositoryProvider).watchForPlant(plantId));

final attributeSchemasProvider = StreamProvider.autoDispose<List<AttributeSchema>>((ref) => ref.watch(attributeRepositoryProvider).watchSchemas());

final activeAttributeSchemasProvider =
    StreamProvider.autoDispose<List<AttributeSchema>>((ref) => ref.watch(attributeRepositoryProvider).watchSchemas(activeOnly: true));

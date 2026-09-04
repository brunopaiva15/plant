import 'dart:convert';

import '../../domain/models/models.dart';
import 'database.dart';

/// Conversions lignes drift ⇄ modèles de domaine.
extension PlantRowMapper on PlantRow {
  Plant toDomain() => Plant(
        id: id,
        gardenId: gardenId,
        name: name,
        speciesName: speciesName,
        locationId: locationId,
        primaryPhotoId: primaryPhotoId,
        status: PlantStatus.values.byName(status),
        health: PlantHealth.values.byName(health),
        isFavorite: isFavorite,
        acquiredAt: acquiredAt,
        source: source,
        price: price,
        potSize: potSize,
        notes: notes,
        parentPlantId: parentPlantId,
        archivedAt: archivedAt,
        archiveReason: archiveReason,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension LocationRowMapper on LocationRow {
  Location toDomain() => Location(
        id: id,
        gardenId: gardenId,
        parentId: parentId,
        name: name,
        icon: icon,
        light: light,
        orientation: orientation,
        isOutdoor: isOutdoor,
        sortOrder: sortOrder,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension PlantPhotoRowMapper on PlantPhotoRow {
  PlantPhoto toDomain() => PlantPhoto(
        id: id,
        plantId: plantId,
        filePath: filePath,
        thumbPath: thumbPath,
        width: width,
        height: height,
        takenAt: takenAt,
        createdAt: createdAt,
      );
}

extension ActionTypeRowMapper on ActionTypeRow {
  ActionType toDomain() => ActionType(
        key: key,
        emoji: emoji,
        label: label,
        isBuiltin: isBuiltin,
        sortOrder: sortOrder,
        schedulable: schedulable,
      );
}

extension PlantActionRowMapper on PlantActionRow {
  PlantAction toDomain() => PlantAction(
        id: id,
        plantId: plantId,
        typeKey: typeKey,
        occurredAt: occurredAt,
        notes: notes,
        metadata: (jsonDecode(metadata) as Map).cast<String, Object?>(),
        photoId: photoId,
        createdAt: createdAt,
      );
}

extension CareScheduleRowMapper on CareScheduleRow {
  CareSchedule toDomain() => CareSchedule(
        id: id,
        plantId: plantId,
        typeKey: typeKey,
        strategy: CareStrategy.values.byName(strategy),
        intervalDays: intervalDays,
        seasonalRules: seasonalRules == null
            ? null
            : (jsonDecode(seasonalRules!) as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble())),
        nextDueAt: nextDueAt,
        lastCompletedAt: lastCompletedAt,
        enabled: enabled,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension TagRowMapper on TagRow {
  Tag toDomain() => Tag(id: id, gardenId: gardenId, name: name, createdAt: createdAt);
}

extension MeasurementRowMapper on MeasurementRow {
  Measurement toDomain() => Measurement(
        id: id,
        plantId: plantId,
        actionId: actionId,
        kind: MeasurementKind.fromKey(kind),
        value: value,
        unit: unit,
        measuredAt: measuredAt,
      );
}

extension InventoryItemRowMapper on InventoryItemRow {
  InventoryItem toDomain() => InventoryItem(
        id: id,
        gardenId: gardenId,
        category: InventoryCategory.fromKey(categoryKey),
        name: name,
        quantity: quantity,
        unit: unit,
        lowThreshold: lowThreshold,
        locationId: locationId,
        notes: notes,
        photoPath: photoPath,
        thumbPath: thumbPath,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

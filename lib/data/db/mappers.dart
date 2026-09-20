import 'dart:convert';

import '../../domain/care/care_profile.dart';
import '../../domain/models/models.dart';
import '../../domain/room/room_scan.dart';
import '../../domain/room/scanned_room.dart';
import 'database.dart';

/// Conversions lignes drift ⇄ modèles de domaine.
extension PlantRowMapper on PlantRow {
  Plant toDomain() => Plant(
        id: id,
        gardenId: gardenId,
        number: number,
        name: name,
        speciesName: speciesName,
        locationId: locationId,
        primaryPhotoId: primaryPhotoId,
        status: PlantStatus.values.byName(status),
        health: PlantHealth.values.asNameMap()[health] ?? PlantHealth.healthy,
        healthIssue: HealthIssue.parse(healthIssue),
        isFavorite: isFavorite,
        light: light == null ? null : LightNeed.values.asNameMap()[light!],
        humidity: humidity == null ? null : HumidityNeed.values.asNameMap()[humidity!],
        lifespan: Lifespan.parse(lifespan),
        hardiness: Hardiness.parse(hardiness),
        cuttingMonth: cuttingMonth,
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
        notes: notes,
        photoPath: photoPath,
        thumbPath: thumbPath,
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
        userId: userId,
        filePath: filePath,
        thumbPath: thumbPath,
        width: width,
        height: height,
        takenAt: takenAt,
        createdAt: createdAt,
        label: label,
        remoteUrl: remoteUrl,
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
        userId: userId,
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
  InventoryItem toDomain({List<String> tags = const []}) => InventoryItem(
        id: id,
        gardenId: gardenId,
        groupId: groupId,
        tags: tags,
        category: InventoryCategory.fromKey(categoryKey),
        name: name,
        quantity: quantity,
        unit: unit,
        lowThreshold: lowThreshold,
        locationId: locationId,
        notes: notes,
        photoPath: photoPath,
        thumbPath: thumbPath,
        fertilizerForm: FertilizerForm.parse(fertilizerForm),
        fertilizerOrigin: FertilizerOrigin.parse(fertilizerOrigin),
        nitrogen: nitrogen,
        phosphorus: phosphorus,
        potassium: potassium,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension TaskRowMapper on TaskRow {
  FreeTask toDomain() => FreeTask(
        id: id,
        gardenId: gardenId,
        plantId: plantId,
        title: title,
        description: description,
        dueAt: dueAt,
        allDay: allDay,
        recurrence: recurrenceValue == null || recurrenceUnit == null ? null : TaskRecurrence(value: recurrenceValue!, unit: RecurrenceUnit.fromKey(recurrenceUnit) ?? RecurrenceUnit.days),
        done: done,
        doneAt: doneAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension PlantAttributeRowMapper on PlantAttributeRow {
  PlantAttribute toDomain() => PlantAttribute(
        id: id,
        gardenId: gardenId,
        plantId: plantId,
        label: label,
        type: AttributeType.fromKey(datatype),
        value: value,
        position: position,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension AttributeSchemaRowMapper on AttributeSchemaRow {
  AttributeSchema toDomain() => AttributeSchema(
        id: id,
        gardenId: gardenId,
        label: label,
        type: AttributeType.fromKey(datatype),
        active: active,
        position: position,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension PlantAttachmentRowMapper on PlantAttachmentRow {
  PlantAttachment toDomain() => PlantAttachment(
        id: id,
        gardenId: gardenId,
        plantId: plantId,
        userId: userId,
        label: label,
        filePath: filePath,
        mimeType: mimeType,
        sizeBytes: sizeBytes,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension LocationLogRowMapper on LocationLogRow {
  LocationLogEntry toDomain() => LocationLogEntry(
        id: id,
        gardenId: gardenId,
        locationId: locationId,
        userId: userId,
        content: content,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension InventoryGroupRowMapper on InventoryGroupRow {
  InventoryGroup toDomain() => InventoryGroup(
        id: id,
        gardenId: gardenId,
        label: label,
        emoji: emoji,
        position: position,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension EventCategoryRowMapper on EventCategoryRow {
  EventCategory toDomain() => EventCategory(
        id: id,
        gardenId: gardenId,
        label: label,
        emoji: emoji,
        colorKey: colorKey,
        position: position,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension CalendarEntryRowMapper on CalendarEntryRow {
  CalendarEntry toDomain() => CalendarEntry(
        id: id,
        gardenId: gardenId,
        plantId: plantId,
        categoryId: categoryId,
        title: title,
        notes: notes,
        startAt: startAt,
        endAt: endAt,
        allDay: allDay,
        reminderMinutes: reminderMinutes,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension RoomScanRowMapper on RoomScanRow {
  RoomScan toDomain() => RoomScan(
        id: id,
        gardenId: gardenId,
        locationId: locationId,
        name: name,
        capturedAt: capturedAt,
        northOffsetDeg: northOffsetDeg,
        filePath: filePath,
        floorAreaM2: floorAreaM2,
        section: RoomSectionLabel.decode(sectionLabel),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension RoomMarkerRowMapper on RoomMarkerRow {
  RoomMarker? toDomain() {
    final k = RoomMarkerKind.decode(kind);
    if (k == null) return null;
    return RoomMarker(
      id: id,
      scanId: scanId,
      kind: k,
      x: x,
      z: z,
      windowIndex: windowIndex,
      orientation: CardinalDirection.values.where((d) => d.name == orientation).firstOrNull,
      plantId: plantId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flora/data/db/database.dart';
import 'package:flora/data/repositories/attribute_repository_impl.dart';
import 'package:flora/data/repositories/plant_repository_impl.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flora/domain/repositories/repositories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FloraDatabase db;
  late AttributeRepository repo;
  late PlantRepository plants;
  const gardenId = 'garden-1';

  setUp(() async {
    db = FloraDatabase(NativeDatabase.memory());
    await db.into(db.gardens).insert(GardensCompanion.insert(id: gardenId, ownerId: 'u1', name: 'Jardin', createdAt: DateTime.now(), updatedAt: DateTime.now()));
    repo = DriftAttributeRepository(db, gardenId);
    plants = DriftPlantRepository(db, gardenId);
  });

  tearDown(() => db.close());

  Future<String> newPlant(String name) async => (await plants.create(NewPlant(name: name))).id;

  test('ajoute un champ typé et le relit', () async {
    final id = await newPlant('Monstera');
    final a = await repo.add(plantId: id, label: '  Provenance  ', type: AttributeType.text, value: ' Marché de Vevey ');
    expect(a.label, 'Provenance');
    expect(a.value, 'Marché de Vevey');
    expect(await repo.watchForPlant(id).first, hasLength(1));
  });

  test('les valeurs typées sont encodées et décodées', () async {
    final id = await newPlant('Basilic');
    final bool_ = await repo.add(plantId: id, label: 'Bio', type: AttributeType.boolean, value: PlantAttribute.encode(AttributeType.boolean, true));
    final int_ = await repo.add(plantId: id, label: 'Feuilles', type: AttributeType.integer, value: '42');
    final dec = await repo.add(plantId: id, label: 'Prix', type: AttributeType.decimal, value: '12,50');
    final date = await repo.add(plantId: id, label: 'Semé le', type: AttributeType.date, value: PlantAttribute.encode(AttributeType.date, DateTime(2026, 3, 1)));

    expect(bool_.asBool, isTrue);
    expect(int_.asInt, 42);
    expect(dec.asDouble, 12.5, reason: 'la virgule décimale est acceptée');
    expect(date.asDate, DateTime(2026, 3, 1));
  });

  test('une valeur vide est stockée comme absente', () async {
    final id = await newPlant('Pilea');
    final a = await repo.add(plantId: id, label: 'Note', type: AttributeType.text, value: '   ');
    expect(a.value, isNull);
    expect(a.isEmpty, isTrue);
  });

  test('supprimer masque le champ', () async {
    final id = await newPlant('Hoya');
    final a = await repo.add(plantId: id, label: 'Provenance', type: AttributeType.text, value: 'Bouture');
    await repo.delete(a.id);
    expect(await repo.watchForPlant(id).first, isEmpty);
  });

  test('appliquer en masse crée puis met à jour sans doublon', () async {
    final a = await newPlant('A');
    final b = await newPlant('B');
    await repo.applyToPlants([a, b], label: 'Exposition', type: AttributeType.text, value: 'Sud');
    expect((await repo.watchForPlant(a).first).single.value, 'Sud');

    await repo.applyToPlants([a, b], label: 'Exposition', type: AttributeType.text, value: 'Est');
    final again = await repo.watchForPlant(a).first;
    expect(again, hasLength(1), reason: 'le même libellé ne doit pas être dupliqué');
    expect(again.single.value, 'Est');
  });

  test('le bouturage recopie les champs de la plante mère', () async {
    final mother = await newPlant('Mère');
    final cutting = await newPlant('Bouture');
    await repo.add(plantId: mother, label: 'Provenance', type: AttributeType.text, value: 'Serre');
    await repo.add(plantId: mother, label: 'Bio', type: AttributeType.boolean, value: 'true');

    await repo.cloneAttributes(fromPlantId: mother, toPlantId: cutting);
    final copied = await repo.watchForPlant(cutting).first;
    expect(copied.map((a) => a.label), containsAll(['Provenance', 'Bio']));
    expect(copied.firstWhere((a) => a.label == 'Bio').asBool, isTrue);
  });

  test('la recherche trouve par valeur et par libellé', () async {
    final id = await newPlant('Calathea');
    await repo.add(plantId: id, label: 'Provenance', type: AttributeType.text, value: 'Marché de Vevey');
    expect(await repo.searchPlantIds('vevey'), {id});
    expect(await repo.searchPlantIds('PROVENANCE'), {id});
    expect(await repo.searchPlantIds('introuvable'), isEmpty);
    expect(await repo.searchPlantIds('  '), isEmpty);
  });

  test('la recherche de plantes remonte celles trouvées par un champ', () async {
    final id = await newPlant('Calathea');
    await newPlant('Autre');
    await repo.add(plantId: id, label: 'Provenance', type: AttributeType.text, value: 'Marché de Vevey');
    final found = await plants.watchSummaries(const PlantFilter(query: 'vevey')).first;
    expect(found.map((s) => s.plant.id), [id]);
  });

  group('modèles', () {
    test('création, masquage et suppression', () async {
      final s = await repo.createSchema(label: 'Exposition', type: AttributeType.text);
      expect(await repo.watchSchemas().first, hasLength(1));
      expect(await repo.watchSchemas(activeOnly: true).first, hasLength(1));

      await repo.updateSchema(s.copyWith(active: false));
      expect(await repo.watchSchemas().first, hasLength(1));
      expect(await repo.watchSchemas(activeOnly: true).first, isEmpty);

      await repo.deleteSchema(s.id);
      expect(await repo.watchSchemas().first, isEmpty);
    });

    test('supprimer un modèle laisse les champs déjà renseignés', () async {
      final id = await newPlant('Monstera');
      final s = await repo.createSchema(label: 'Exposition', type: AttributeType.text);
      await repo.add(plantId: id, label: 'Exposition', type: AttributeType.text, value: 'Sud');
      await repo.deleteSchema(s.id);
      expect(await repo.watchForPlant(id).first, hasLength(1));
    });
  });

  test('chaque écriture est mise en file de synchronisation', () async {
    final id = await newPlant('Monstera');
    final a = await repo.add(plantId: id, label: 'Provenance', type: AttributeType.text);
    final pending = await (db.select(db.syncOutbox)..where((o) => o.entity.equals('plant_attributes') & o.entityId.equals(a.id))).get();
    expect(pending, isNotEmpty);
  });
}

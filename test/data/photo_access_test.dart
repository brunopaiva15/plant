import 'package:flora/data/services/photo_storage_service.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/features/plants/presentation/photo_error.dart';
import 'package:flora/l10n/generated/app_localizations_fr.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

/// Un accès refusé à l'appareil photo n'est pas une erreur à réessayer.
///
/// Avant, il se lisait « Impossible d'ajouter la photo. Réessayez. » :
/// quelqu'un qui avait dit non à la caméra réessayait sans fin, puisque iOS
/// ne repose jamais la question. Le refus a maintenant son type, et son
/// toast dit quoi autoriser.
class _RefusingPicker extends ImagePicker {
  _RefusingPicker(this.code);

  final String code;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async =>
      throw PlatformException(code: code);
}

void main() {
  final l10n = AppLocalizationsFr();

  test('un refus de la caméra devient PhotoAccessDenied', () async {
    final storage = PhotoStorageService(picker: _RefusingPicker('camera_access_denied'));
    await expectLater(
      storage.pickSource(PhotoSource.camera),
      throwsA(isA<PhotoAccessDenied>().having((e) => e.source, 'source', PhotoSource.camera)),
    );
  });

  test('un refus de la photothèque aussi', () async {
    final storage = PhotoStorageService(picker: _RefusingPicker('photo_access_denied'));
    await expectLater(
      storage.pickSource(PhotoSource.gallery),
      throwsA(isA<PhotoAccessDenied>().having((e) => e.source, 'source', PhotoSource.gallery)),
    );
  });

  test('une autre erreur du plugin passe telle quelle', () async {
    final storage = PhotoStorageService(picker: _RefusingPicker('no_available_camera'));
    await expectLater(storage.pickSource(PhotoSource.camera), throwsA(isA<PlatformException>()));
  });

  test('le toast dit quoi autoriser, pas « Réessayez »', () {
    expect(photoErrorToast(l10n, const PhotoAccessDenied(PhotoSource.camera)).message, l10n.cameraPermission);
    expect(photoErrorToast(l10n, const PhotoAccessDenied(PhotoSource.gallery)).message, l10n.photoLibraryPermission);
    expect(photoErrorToast(l10n, Exception('disque plein')).message, l10n.photoError);
  });

  test("le toast générique n'a pas de bouton", () {
    final ToastData toast = photoErrorToast(l10n, Exception('disque plein'));
    expect(toast.undoLabel, isNull);
  });
}

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';

class MediaService {
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();

  Future<File?> takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (photo == null) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(appDir.path, 'media', 'photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final filename = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedFile = File(p.join(photosDir.path, filename));
    await File(photo.path).copy(savedFile.path);

    return savedFile;
  }

  Future<void> startAudioRecording(String filename) async {
    final appDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory(p.join(appDir.path, 'media', 'audio'));
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    final filePath = p.join(audioDir.path, '$filename.m4a');
    if (await _audioRecorder.hasPermission()) {
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );
    }
  }

  Future<File?> stopAudioRecording() async {
    final path = await _audioRecorder.stop();
    if (path == null) return null;
    return File(path);
  }

  Future<bool> isRecordingAudio() async {
    return _audioRecorder.isRecording();
  }
}

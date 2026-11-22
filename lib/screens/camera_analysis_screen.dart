import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../app_state.dart';

class CameraAnalysisScreen extends StatefulWidget {
  final String childName;

  const CameraAnalysisScreen({super.key, required this.childName});

  @override
  State<CameraAnalysisScreen> createState() => _CameraAnalysisScreenState();
}

class _CameraAnalysisScreenState extends State<CameraAnalysisScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  VideoPlayerController? _videoController;

  List<CameraDescription> _cameras = [];

  bool _cameraLoading = true;
  bool _isRecording = false;
  bool _isSaving = false;
  bool _cameraAvailable = false;

  String? _errorMessage;
  String? _selectedVideoPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller.dispose();
      _cameraController = null;
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (!mounted) return;

    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      setState(() {
        _cameraLoading = false;
        _cameraAvailable = false;
        _errorMessage =
            'Live camera recording is currently configured for Android and iOS. '
            'Please run the application on an Android device.';
      });
      return;
    }

    try {
      setState(() {
        _cameraLoading = true;
        _errorMessage = null;
      });

      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        throw Exception('No camera was found on this device.');
      }

      await _startCamera(_cameras.first);

      if (!mounted) return;

      setState(() {
        _cameraLoading = false;
        _cameraAvailable = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cameraLoading = false;
        _cameraAvailable = false;
        _errorMessage = 'Unable to initialize camera: $e';
      });
    }
  }

  Future<void> _startCamera(CameraDescription description) async {
    await _cameraController?.dispose();

    final controller = CameraController(
      description,
      ResolutionPreset.medium,
      enableAudio: true,
    );

    _cameraController = controller;

    await controller.initialize();
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isRecording) return;

    try {
      final currentLens = _cameraController?.description.lensDirection;

      final newCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection != currentLens,
      );

      setState(() {
        _cameraLoading = true;
      });

      await _startCamera(newCamera);

      if (!mounted) return;

      setState(() {
        _cameraLoading = false;
        _cameraAvailable = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cameraLoading = false;
        _errorMessage = 'Unable to switch camera: $e';
      });
    }
  }

  Future<void> _startRecording() async {
    final controller = _cameraController;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    try {
      await controller.startVideoRecording();

      if (!mounted) return;

      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      _showMessage('Recording could not start: $e');
    }
  }

  Future<void> _stopRecording() async {
    final controller = _cameraController;

    if (controller == null || !_isRecording) return;

    try {
      final XFile recordedFile = await controller.stopVideoRecording();

      if (!mounted) return;

      setState(() {
        _isRecording = false;
        _isSaving = true;
      });

      await _saveVideo(recordedFile, source: 'Camera Recording');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isRecording = false;
        _isSaving = false;
      });

      _showMessage('Unable to stop recording: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? pickedFile = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (pickedFile == null) return;

      if (!mounted) return;

      setState(() {
        _isSaving = true;
      });

      await _saveVideo(pickedFile, source: 'Gallery Upload');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage('Unable to select video: $e');
    }
  }

  Future<void> _saveVideo(XFile videoFile, {required String source}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();

      final videoDirectory = Directory('${directory.path}/child_videos');

      if (!await videoDirectory.exists()) {
        await videoDirectory.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final originalName = videoFile.name.isNotEmpty
          ? videoFile.name
          : 'child_video.mp4';

      final extension = originalName.contains('.')
          ? originalName.substring(originalName.lastIndexOf('.'))
          : '.mp4';

      final savedPath = '${videoDirectory.path}/video_$timestamp$extension';

      await File(videoFile.path).copy(savedPath);

      final player = VideoPlayerController.file(File(savedPath));

      await player.initialize();

      final durationSeconds = player.value.duration.inSeconds;

      await player.dispose();

      final record = VideoAnalysisRecord(
        id: AppState.createId(),
        childName: widget.childName,
        filePath: savedPath,
        fileName: originalName,
        durationSeconds: durationSeconds,
        recordedAt: DateTime.now(),
        source: source,
        notes: '',
        status: 'Pending',
        analysisSummary: '',
      );

      AppState.addVideoAnalysis(record);

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage('Video saved successfully.');

      await _playVideo(savedPath);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage('Video could not be saved: $e');
    }
  }

  Future<void> _playVideo(String path) async {
    try {
      await _videoController?.dispose();

      final controller = VideoPlayerController.file(File(path));

      _videoController = controller;

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _selectedVideoPath = path;
      });

      await controller.play();
    } catch (e) {
      _showMessage('Unable to play video: $e');
    }
  }

  Future<void> _deleteVideo(VideoAnalysisRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete video?'),
        content: const Text(
          'This will remove the video record and its saved file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final file = File(record.filePath);

      if (await file.exists()) {
        await file.delete();
      }

      AppState.deleteVideoAnalysis(record.id);

      if (_selectedVideoPath == record.filePath) {
        await _videoController?.dispose();
        _videoController = null;
        _selectedVideoPath = null;
      }

      if (mounted) {
        setState(() {});
        _showMessage('Video deleted.');
      }
    } catch (e) {
      _showMessage('Unable to delete video: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildCameraPreview() {
    final controller = _cameraController;

    if (_cameraLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_cameraAvailable ||
        controller == null ||
        !controller.value.isInitialized) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.videocam_off_outlined,
                size: 55,
                color: Colors.white70,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'Camera is not available.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              if (!kIsWeb)
                OutlinedButton(
                  onPressed: _initializeCamera,
                  child: const Text('Retry Camera'),
                ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    final controller = _videoController;

    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                color: Colors.white,
                onPressed: () {
                  setState(() {
                    if (controller.value.isPlaying) {
                      controller.pause();
                    } else {
                      controller.play();
                    }
                  });
                },
                icon: Icon(
                  controller.value.isPlaying
                      ? Icons.pause_circle
                      : Icons.play_circle,
                  size: 34,
                ),
              ),
              Expanded(
                child: VideoProgressIndicator(
                  controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Colors.greenAccent,
                    bufferedColor: Colors.white38,
                    backgroundColor: Colors.white24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    final records = AppState.videoAnalysesFor(widget.childName);

    if (records.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.video_library_outlined, size: 42, color: Colors.grey),
              SizedBox(height: 8),
              Text('No videos saved for this child yet.'),
            ],
          ),
        ),
      );
    }

    final sortedRecords = [...records]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    return Column(
      children: sortedRecords.map((record) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.play_arrow)),
            title: Text(
              record.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${record.source} • '
              '${_formatDuration(record.durationSeconds)}\n'
              '${record.recordedAt.toLocal()}',
            ),
            isThreeLine: true,
            onTap: () => _playVideo(record.filePath),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'play') {
                  _playVideo(record.filePath);
                } else if (value == 'delete') {
                  _deleteVideo(record);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'play', child: Text('Play video')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final records = AppState.videoAnalysesFor(widget.childName);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera & Video Analysis'),
        actions: [
          IconButton(
            tooltip: 'Refresh history',
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const CircleAvatar(child: Icon(Icons.child_care)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Selected child',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    Text(
                                      widget.childName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Chip(label: Text('${records.length} Videos')),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Live Camera',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 230),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _buildCameraPreview(),
                      ),

                      if (_isRecording)
                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Row(
                            children: [
                              Icon(
                                Icons.fiber_manual_record,
                                color: Colors.red,
                                size: 14,
                              ),
                              SizedBox(width: 7),
                              Text(
                                'Recording in progress',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 14),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: !_cameraAvailable || _isSaving
                                ? null
                                : (_isRecording
                                      ? _stopRecording
                                      : _startRecording),
                            icon: Icon(
                              _isRecording
                                  ? Icons.stop
                                  : Icons.fiber_manual_record,
                            ),
                            label: Text(
                              _isRecording
                                  ? 'Stop Recording'
                                  : 'Start Recording',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: _isRecording ? Colors.red : null,
                            ),
                          ),

                          OutlinedButton.icon(
                            onPressed: _isRecording || !_cameraAvailable
                                ? null
                                : _switchCamera,
                            icon: const Icon(Icons.flip_camera_android),
                            label: const Text('Switch Camera'),
                          ),

                          OutlinedButton.icon(
                            onPressed: _isRecording || _isSaving
                                ? null
                                : _pickVideo,
                            icon: const Icon(Icons.video_library),
                            label: const Text('Choose from Gallery'),
                          ),
                        ],
                      ),

                      if (_isSaving)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Saving video...'),
                            ],
                          ),
                        ),

                      if (_selectedVideoPath != null) _buildVideoPlayer(),

                      const SizedBox(height: 26),

                      const Text(
                        'Video History',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Saved videos associated with this child.',
                        style: TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 12),

                      _buildHistory(),

                      const SizedBox(height: 20),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Videos are saved for future analysis. '
                                'AI analysis is not connected yet. '
                                'Obtain parent or guardian consent before '
                                'recording a child.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

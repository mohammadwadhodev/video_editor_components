import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_editor_2/domain/entities/file_format.dart';
import 'package:video_editor_2/video_editor.dart';
import 'package:video_editor_example/crop.dart';
import 'package:video_editor_example/utils/fonts.dart';
import 'package:video_editor_example/utils/get_ffmpeg_commnds.dart';

void main() => runApp(
      MaterialApp(
        title: 'Flutter Video Editor Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.grey,
          brightness: Brightness.dark,
          tabBarTheme: const TabBarTheme(
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
          dividerColor: Colors.white,
        ),
        home: const VideoEditorExample(),
      ),
    );

class VideoEditorExample extends StatefulWidget {
  const VideoEditorExample({super.key});

  @override
  State<VideoEditorExample> createState() => _VideoEditorExampleState();
}

class _VideoEditorExampleState extends State<VideoEditorExample> {
  final ImagePicker _picker = ImagePicker();

  void _pickVideo() async {

    // final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
    //
    // if (mounted && file != null) {
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute<void>(
    //       builder: (BuildContext context) => VideoEditor(file: file),
    //     ),
    //   );
    // }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (mounted &&  result != null) {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) => VideoEditor(filePath: result.files[0].path!),
          ),
        );
      }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Image / Video Picker")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Click on the button to select video"),
            ElevatedButton(
              onPressed: _pickVideo,
              child: const Text("Pick Video From Gallery"),
            ),


            SizedBox(height: 50),
            Text("Pick Video From Gallery",

            style: TextStyle(
              fontSize: 30,
              fontFamily: Fonts.namaku
            ),
            ),

          ],
        ),


      ),
    );
  }
}

//-------------------//
//VIDEO EDITOR SCREEN//
//-------------------//
class VideoEditor extends StatefulWidget {
  const VideoEditor({super.key, required this.filePath});

  final String filePath;

  @override
  State<VideoEditor> createState() => _VideoEditorState();
}

class _VideoEditorState extends State<VideoEditor> {
  final _exportingProgress = ValueNotifier<double>(0.0);
  final _isExporting = ValueNotifier<bool>(false);
  final double height = 60;

  /// On the web, when multiple VideoPlayers reuse the same VideoController,
  /// only the last one can show the frames.
  /// Therefore, when CropScreen is popped, the CropGridViewer should be given a
  /// new key to refresh itself.
  ///
  /// https://github.com/flutter/flutter/issues/124210
  int cropGridViewerKey = 0;

  late final _controller = VideoEditorController.file(XFile(widget.filePath),
    minDuration: const Duration(seconds: 1),
    maxDuration: const Duration(seconds: 10),
  );

  @override
  void initState() {
    super.initState();
    _controller.initialize(aspectRatio: 9 / 16).then((_) {
      if (mounted) {
        setState(() {});
      }
    }).catchError((error) {
      if (mounted) {
        Navigator.pop(context);
      }
    }, test: (e) => e is VideoMinDurationError);
  }

  @override
  void dispose() {
    _exportingProgress.dispose();
    _isExporting.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _controller.initialized
            ? SafeArea(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        _topNavBar(),
                        Expanded(
                          child: DefaultTabController(
                            length: 2,
                            child: Column(
                              children: [
                                Expanded(
                                  child: TabBarView(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    children: [
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          CropGridViewer.preview(
                                            key: ValueKey(cropGridViewerKey),
                                            controller: _controller,
                                          ),
                                          AnimatedBuilder(
                                            animation: _controller.video,
                                            builder: (_, __) => AnimatedOpacity(
                                              opacity: !_controller.isPlaying
                                                  ? 1.0
                                                  : 0.0,
                                              duration:
                                                  const Duration(seconds: 1),
                                              child: GestureDetector(
                                                onTap: _controller.video.play,
                                                child: Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.play_arrow,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      CoverViewer(controller: _controller)
                                    ],
                                  ),
                                ),
                                Container(
                                  height: 200,
                                  margin: const EdgeInsets.only(top: 10),
                                  child: Column(
                                    children: [
                                      const TabBar(
                                        tabs: [
                                          Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Padding(
                                                    padding: EdgeInsets.all(5),
                                                    child: Icon(
                                                        Icons.content_cut)),
                                                Text('Trim')
                                              ]),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Padding(
                                                  padding: EdgeInsets.all(5),
                                                  child:
                                                      Icon(Icons.video_label)),
                                              Text('Cover')
                                            ],
                                          ),
                                        ],
                                      ),
                                      Expanded(
                                        child: TabBarView(
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          children: [
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: _trimSlider(),
                                            ),
                                            _coverSelection(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ValueListenableBuilder(
                                  valueListenable: _isExporting,
                                  builder: (_, bool export, __) =>
                                      AnimatedOpacity(
                                    opacity: export ? 1.0 : 0.0,
                                    duration: const Duration(seconds: 1),
                                    child: AlertDialog(
                                      title: ValueListenableBuilder(
                                        valueListenable: _exportingProgress,
                                        builder: (_, double value, __) => Text(
                                          "Exporting video ${(value * 100).ceil()}%",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _topNavBar() {
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.exit_to_app),
                tooltip: 'Leave editor',
              ),
            ),
            const VerticalDivider(endIndent: 22, indent: 22),
            Expanded(
              child: IconButton(
                onPressed: () =>
                    _controller.rotate90Degrees(RotateDirection.left),
                icon: const Icon(Icons.rotate_left),
                tooltip: 'Rotate unclockwise',
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: () =>
                    _controller.rotate90Degrees(RotateDirection.right),
                icon: const Icon(Icons.rotate_right),
                tooltip: 'Rotate clockwise',
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => CropScreen(controller: _controller),
                    ),
                  );

                  if (kIsWeb) {
                    setState(() => ++cropGridViewerKey);
                  }
                },
                icon: const Icon(Icons.crop),
                tooltip: 'Open crop screen',
              ),
            ),
            const VerticalDivider(endIndent: 22, indent: 22),
            Expanded(
              child: PopupMenuButton(
                tooltip: 'Open export menu',
                icon: const Icon(Icons.save),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: () {},
                    child: const Text('Export cover'),
                  ),
                  PopupMenuItem(
                    onTap: () async {
                      processVideo();
                    },
                    child: const Text('Export video'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatter(Duration duration) => [
        duration.inMinutes.remainder(60).toString().padLeft(2, '0'),
        duration.inSeconds.remainder(60).toString().padLeft(2, '0')
      ].join(":");

  List<Widget> _trimSlider() {
    return [
      AnimatedBuilder(
        animation: Listenable.merge([
          _controller,
          _controller.video,
        ]),
        builder: (_, __) {
          final duration = _controller.videoDuration.inSeconds;
          final pos = _controller.trimPosition * duration;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: height / 4),
            child: Row(children: [
              if (pos.isFinite) Text(formatter(Duration(seconds: pos.toInt()))),
              const Expanded(child: SizedBox()),
              AnimatedOpacity(
                opacity: _controller.isTrimming ? 1.0 : 0.0,
                duration: const Duration(seconds: 1),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(formatter(_controller.startTrim)),
                  const SizedBox(width: 10),
                  Text(formatter(_controller.endTrim)),
                ]),
              ),
            ]),
          );
        },
      ),
      Container(
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.symmetric(vertical: height / 4),
        child: TrimSlider(
          controller: _controller,
          height: height,
          horizontalMargin: height / 4,
          child: TrimTimeline(
            controller: _controller,
            padding: const EdgeInsets.only(top: 10),
          ),
        ),
      )
    ];
  }

  Widget _coverSelection() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(15),
          child: CoverSelection(
            controller: _controller,
            size: height + 10,
            quantity: 8,
            selectedCoverBuilder: (cover, size) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  cover,
                  Icon(
                    Icons.check_circle,
                    color: const CoverSelectionStyle().selectedBorderColor,
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<String> ioOutputPath(String filePath, String extension) async {
    final tempPath = (await getTemporaryDirectory()).path;
    final name = path.basenameWithoutExtension(filePath);
    final epoch = DateTime.now().millisecondsSinceEpoch;
    return "$tempPath/${name}_$epoch$extension";
  }

  //
  // Future<String> ioOutputPath(String filePath, FileFormat format) async {
  //   final tempPath = (await getTemporaryDirectory()).path;
  //   final name = path.basenameWithoutExtension(filePath);
  //   final epoch = DateTime.now().millisecondsSinceEpoch;
  //   return "$tempPath/${name}_$epoch.${format.extension}";
  // }

  String _webPath(String prePath, FileFormat format) {
    final epoch = DateTime.now().millisecondsSinceEpoch;
    return '${prePath}_$epoch.${format.extension}';
  }

  String webInputPath(FileFormat format) => _webPath('input', format);

  String webOutputPath(FileFormat format) => _webPath('output', format);

  Future<String> getOutputPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/mw3${Random().nextInt(100000)}.mov';
  }



  Future<String> getFontPath() async {
    final tempDir = await getTemporaryDirectory();
    final fontPath = '${tempDir.path}/Namaku.ttf';
    final fontFile = File(fontPath);

    if (!await fontFile.exists()) {
      // Copy the font file from assets to the temporary directory
      final byteData = await rootBundle.load('assets/Namaku.ttf');
      await fontFile.writeAsBytes(byteData.buffer.asUint8List());
    }

    return fontPath;
  }


  Future<void> processVideo() async {

    // print("path : ${path.path}");
    print("");
    print("Processing......");
    print("------------------------------------------");
    print(widget.filePath);
    // print("directory : ${await getFontPath()}");
    // return;


    if (widget.filePath == null) {
      return;
    }






    // Get output file path
    String outputPath = await getOutputPath();

    // Construct the FFmpeg command to add background music to the video
    String command = FFMPEGCommands().multipleTexts(
        inputVideoPath: widget.filePath,
        outputVideoPath: outputPath, text: "Hello Mohammad",
        fontFamily:await getFontPath(),
        fontSize: 100,
        color:"blue"

    );

    // Execute FFmpeg command
    await FFmpegKit.execute(command).then((session) async {
      final returnCode = await session.getReturnCode();

      bool isSuccess  = returnCode?.isValueSuccess() ?? false;
      print("returnCode : ${isSuccess}");
      print("returnCode : ${returnCode.toString()}");


      if (isSuccess == true) {
        print("isSuccess -------- : $isSuccess");
        // Save the output video to gallery
        await saveToGallery(outputPath);
      } else {
        print("isFail -------- : $isSuccess");
        //print("Error processing video: ${returnCode.getValue()}");
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Something went wrong"), backgroundColor: Colors.red));
      }
    });
  }

  Future<void> saveToGallery(String outputPath) async {
    print("SAVE TO GALLYER :");
    bool? success = await GallerySaver.saveVideo(outputPath);
    if (success == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Video saved to gallery")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save video")),
      );
    }
  }


}

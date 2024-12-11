class FFMPEGCommands {
  FFMPEGCommands._internal();

  static final FFMPEGCommands _instance = FFMPEGCommands._internal();

  factory FFMPEGCommands() {
    return _instance;
  }

  var fontPath = "/assets/Namaku.ttf";

  // WORKING
  videoWithBGMusic({required String selectedVideoPath, required String backgroundMusicPath,outputPath})  => "-i $selectedVideoPath -i $backgroundMusicPath -c:v mpeg4 -c:a aac -map 0:v -map 1:a -shortest $outputPath";

  // -i input.mp4 -c:a libmp3lame output.mp3
  videoToAudio({required String videoPath, required String audioPath})  => "-i $videoPath -c:a libmp3lame $audioPath"; // input.mp4 + audio.mp3

  // -i input.mp4 -s 640x480 output.mp4
  videoResolution({required String inputVideoPath, required String outputVideoPath,required double width, required double height}) => "-i $inputVideoPath -s ${width}x$height $outputVideoPath"; // input.mp4 + output.mp4

  // -i input.mp4 -r 30 output.mp4
  frameRate({required String inputVideoPath, required String outputVideoPath, required int frames}) => "-i $inputVideoPath -r $frames $outputVideoPath"; // input.mp4 + output.mp4

  // -i input.mp4 -filter:v "crop=w=320:h=240:x=100:y=50" output.mp4
  cropVideo({required String inputVideoPath, required String outputVideoPath, required double w,required double h,required double x, required double y}) => '-i $inputVideoPath -filter:v "crop=$w=320:$h=240:$x=100:$y=50" $outputVideoPath'; // input.mp4 + output.mp4


  // -i input.mp4 -vf "drawtext=text=\'Hello, World!\':font=\'Arial\':fontsize=30:x=(w-text_w)/2:y=(h-text_h)/2" output.mp4
  // textOnVideo({required String inputVideoPath, required String outputVideoPath, required String text,required String fontFamily, required double fontSize}) =>
  //     '-i $inputVideoPath -vf "drawtext=text=\'$text\':font=\'$fontFamily\':fontsize=$fontSize:x=(w-text_w)/2:y=(h-text_h)/2" $outputVideoPath'; // input.mp4 + output.mp4

  // WORKING
  textOnVideo2({required String inputVideoPath, required String outputVideoPath, required String text,required String fontFamily, required double fontSize,color}) =>
      '-i $inputVideoPath -vf "drawtext=text=\'$text\':fontfile=\'$fontFamily\':fontsize=$fontSize:fontcolor=$color:x=200:y=500:box=1:boxcolor=black@0.5, rotate=(30*PI/180)" -codec:a copy $outputVideoPath';


  // text duration applied here using between function
 textOnVideo3({required String inputVideoPath, required String outputVideoPath, required String text,required String fontFamily, required double fontSize,color}) =>
     '-i $inputVideoPath -filter_complex "color=black@0.0:size=1280x1280: [bg];[bg]drawtext=text=\'$text\':fontfile=\'$fontFamily\':fontsize=$fontSize:fontcolor=$color:x=200:y=500:enable=\'between(t,0,3)\',rotate=PI/6:c=black@0[t];[0:v][t]overlay=shortest=1" -c:a copy $outputVideoPath';


  textWithShadow({required String inputVideoPath, required String outputVideoPath, required String text,required String fontFamily, required double fontSize,color}) =>
      '-i $inputVideoPath -vf "drawtext=text=\'$text\':fontfile=\'$fontFamily\':fontsize=$fontSize:fontcolor=$color:x=150:y=500:shadowx=-10:shadowy=-10:shadowcolor=white" -codec:a copy $outputVideoPath';

  multipleTexts({required String inputVideoPath, required String outputVideoPath, required String text,required String fontFamily, required double fontSize,color}) =>
      '-i $inputVideoPath -vf "'
          '"drawtext=text=\'Hello Developers\':fontfile=\'$fontFamily\':fontsize=$fontSize:fontcolor=orange:x=150:y=750:shadowx=-10:shadowy=-10:shadowcolor=white",'
          'drawtext=text=\'Second Text\':fontfile=\'$fontFamily\':fontsize=$fontSize:fontcolor=black:x=150:y=620:shadowx=-10:shadowy=-10:shadowcolor=yellow",'
          '"drawtext=text=\'$text\':fontfile=\'$fontFamily\':fontsize=$fontSize:fontcolor=$color:x=150:y=500:shadowx=-10:shadowy=-10:shadowcolor=white" -codec:a copy $outputVideoPath';


 /// this is working for rotating text but effects quality
  // textOnVideo3({required String inputVideoPath, required String outputVideoPath, required String text,required String fontFamily, required double fontSize,color}) =>
  //     '-i $inputVideoPath -filter_complex "color=black@0.0:size=1280x1280: [bg];[bg]drawtext=text=\'$text\':fontfile=\'$fontFamily\':fontsize=$fontSize:fontcolor=$color:x=200:y=500:enable=\'between(t,0,3)\',rotate=PI/6:c=black@0[t];[0:v][t]overlay=shortest=1" -c:a copy $outputVideoPath';


 ///Working perfect for croping video and rotating text
// textOnVideo4({required String inputVideoPath, required String outputVideoPath, required String text,required String fontFamily, required double fontSize,color}) =>
//     '-i "$inputVideoPath" -filter_complex "[0]crop=1000:700:0:0[v];color=black[c];[c][v]scale2ref[t][v];[t]setsar=1,colorkey=black,drawtext=text=\'Check test\':fontsize=30:fontcolor=white:x=300:y=600,rotate=PI/6:c=black@0[t];[v][t]overlay=shortest=1" $outputVideoPath';





// textOnVideo3({required String inputVideoPath, required String outputVideoPath, required String text,required String fontFamily, required double fontSize}) =>
  //     "-i $inputVideoPath -vf drawtext=text='$text':fontfile=$fontPath:font=Arial:fontsize=$fontSize:x=(w-text_w)/2:y=(h-text_h)/2 -c:v libx264 -c:a copy $outputVideoPath";


}

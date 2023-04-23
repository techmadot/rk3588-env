const spawn = require('child_process').spawn;
const input = process.env.INPUT;
const output = process.env.OUTPUT;
const fallback=1;

// GStreamer 用設定
const gstreamer = '/opt/gstreamer/bin/gst-launch-1.0';
const gst_library_path = '/opt/gstreamer/lib/aarch64-linux-gnu';
const ffprobe = '/usr/bin/ffprobe'
const deinterlace_type = 1; //0:disable, 1:normal, 2:yadif
const apply_resize= 0; // 0:disable, 1:enable
const WIDTH=1280;
const HEIGHT=720;
const disp_progress = 1;

// FFMPEG 用設定
const ffmpeg = process.env.FFMPEG;
const analyzedurationSize = '10M'; // Mirakurun の設定に応じて変更すること
const probesizeSize = '32M'; // Mirakurun の設定に応じて変更すること
const preset = 'veryfast';
const crf = 23;

let videoscaling_available = 1;

// プロセス呼び出し関数
function executeProbe()
{
  const execSync = require('child_process').execSync;

  const result = execSync(`${ffprobe} -of json -show_streams -show_programs ${input}`);
  const data = JSON.parse(String(result));
  if (data.program < 0 || data.video_sid < 0 || data.audio_sid < 0 ) {
    throw new Error('probe failed');
  }
  return data;
}


function checkVideoScale()
{
  const execSync = require('child_process').execSync;
  const result = execSync(
    `${gstreamer} --version | grep GStreamer | sed -E 's/GStreamer ([0-9])\\.([0-9]+)\\.([0-9]+)/\\1\\2\\3/g'`,
    { env: { 'LD_LIBRARY_PATH': gst_library_path } });
  //console.error(String(result));
  try {
    if( parseInt(String(result), 10) >= 12190 ) {
      console.error('videoconvertscale is OK.');
      return 1;
    }
  }
  catch {
  }
  console.error('videoconvertscale is not available.');
  return 0;
}

function extractSID() {
  video_sid = null;
  audio_sid = null;
  program_id = null;
  const ret = executeProbe();
  for(let program of ret.programs) {
    const video_stream = program.streams.find( x => { return x.codec_type == "video"; });
    const audio_stream = program.streams.find( x => { return x.codec_type == "audio"; });

    if( video_stream && audio_stream ) {
      program_id = program.program_id;
      video_sid = parseInt(video_stream.id, 16);
      audio_sid = parseInt(audio_stream.id, 16);

      break;
    }
  }

  const toHex = (x) => {
    const val = '0000' + x.toString(16);
    return val.slice(-4);
  };
  return {
    program_id,
    video_sid: toHex(video_sid),
    audio_sid: toHex(audio_sid),
  };
}

function executeFFMPEG(args)
{
  const child = spawn(ffmpeg, args);
  return new Promise( (resolve, reject) => {
    child.stderr.on('data', (data) => {
      console.error(String(data));
    });
    child.stdout.on('data', (data) => {
      console.error("> "+String(data));
    });
    child.on("exit", (code) => {
      if (code === 0) {
        resolve(code);
      } else {
        reject(new Error('failed.'));
      }
    });
    process.on('SIGINT', () => {
      child.kill('SIGINT');
    });
  });
}

function executeGStreamer(args)
{
  const child = spawn(gstreamer, args, { env: { 'LD_LIBRARY_PATH': gst_library_path } });
  return new Promise( (resolve, reject) => {
    child.stderr.on('data', (data) => {
      console.error(String(data));
    } );
    child.stdout.on('data', (data) => {
      console.error(String(data));
    });
    child.on("close", (code) => {
      console.error(`code = ${code}`);
    } );
    child.stdout.on('data', (data) => { 
      process.stdout.write(String(data));
    } );
    child.on("exit", (code) => {
      if (code === 0) {
        resolve(code);
      } else {
        reject(new Error('failed'));
      }
    });
    process.on('SIGINT', () => {
      child.kill('SIGINT');
    });
  });

  //child.stderr.on('data', (data) => { console.error(String(data)); });
  /*
  child.on('error', (err) => {
    console.error(err);
    throw new Error(err);
  });
  process.on('SIGINT', () => {
    child.kill('SIGINT');
  });
  return child;
  */
}


function buildArgsGStreamer(info)
{
  const gst_args = [ '-e', 'filesrc', `location=${input}`, '!'];
  console.log(info);

  if (disp_progress > 0) {
    Array.prototype.push.apply(gst_args, ['progressreport', 'update-freq=60', '!'] );
  }
  Array.prototype.push.apply(gst_args, [
    'tsdemux', 'name=demuxer', `program-number=${info.program_id}`
  ]);

  // Video Pipeline
  Array.prototype.push.apply(gst_args, [
    `demuxer.video_0_${info.video_sid}`, '!',
    'video/mpeg', '!',
    'queue', 'max-size-time=0','max-size-buffers=0', '!',
    'mpegvideoparse', '!',
    'avdec_mpeg2video', '!',
  ]);

  if (deinterlace_type > 0) {
    if (deinterlace_type == 1) {
      Array.prototype.push.apply(gst_args, [
        'avdeinterlace', '!'
      ]);
    } else {
      Array.prototype.push.apply(gst_args, [
        'deinterlace', 'method=yadif', '!'
      ]);
    }
  }

  if (apply_resize > 0 && videoscaling_available > 0) {
    Array.prototype.push.apply(gst_args, [
      'videoconvertscale', 'n-threads=6', 'method=lanczos', '!',
      `video/x-raw,width=${WIDTH},height=${HEIGHT}`, '!',
    ]);
  }

  Array.prototype.push.apply(gst_args, [
    'videoconvert', '!',
    'mpph264enc', 'rc-mode=2', 'qp-init=24', '!',
    'video/x-h264,stream-format=byte-stream', '!',
    'h264parse', '!', 'mux.'
  ]);

  // Audio Pipeline
  Array.prototype.push.apply(gst_args, [
    `demuxer.audio_0_${info.audio_sid}`, '!',
    'audio/mpeg' ,'!',
    'queue', 'max-size-time=0', 'max-size-buffers=0', '!',
  ]);
  Array.prototype.push.apply(gst_args, [
    'aacparse', '!',
    'avdec_aac' , '!',
    'audioresample', '!',
    'audioconvert', '!'
  ]);
  Array.prototype.push.apply(gst_args, [
    'avenc_aac', 'ar=48000', 'bitrate=128000', 'ac=2', '!',
    'mux.'
  ]);

  // Mux
  Array.prototype.push.apply(gst_args, [
    'mp4mux', 'streamable=true', 'name=mux' ,'!'
  ]);

  // Output
  Array.prototype.push.apply(gst_args, [
    'filesink', `location=${output}`
  ]);

  return gst_args;
}

function buildArgsFFMPEG()
{
  const ffmpeg_args = [ '-hide_banner', '-y', '-analyzeduration', analyzedurationSize, '-probesize', probesizeSize ];

  // input 設定
  Array.prototype.push.apply(ffmpeg_args, ['-i', input, '-loglevel', 'error', '-stats']);
  Array.prototype.push.apply(ffmpeg_args, ['-movflags', 'faststart']);
  Array.prototype.push.apply(ffmpeg_args, ['-vf', 'yadif,scale=-2:720']);
  Array.prototype.push.apply(ffmpeg_args, [
    '-threads', '6',
    '-preset', preset,
    '-aspect', '16:9',
    '-c:v', 'libx264',
    '-crf', crf,
    '-c:a', 'aac',
    '-ar', '48000',
    '-ab', '128k',
    '-ac', '2',
    output
  ]);
  return ffmpeg_args;
}

async function main() {
  try {
    videoscaling_available = checkVideoScale();

    let str = '';
    gst_args = buildArgsGStreamer( extractSID() );
    for (let i of gst_args) {
        str += ` ${ i }`
    }
    //console.error(str);

    await executeGStreamer(gst_args);
    console.error('gstreamer executed.');
    return 0;
  }
  catch {
    if (fallback == 0) {
      console.error('error');
      throw new Error('encode failed.');
    }
    console.error('fallback to ffmpeg');
  }

  try {
    let str = '';
    const args = buildArgsFFMPEG();
    console.error(args.join(' '));
    await executeFFMPEG(args);
    console.error('ffmpeg executed.');
    return 0;
  }
  catch {
    console.error('encode failed.');
    throw new Error('encode failed');
  }
}

main();


import { audio } from "@kit.AudioKit";
import { fileIo } from "@kit.CoreFileKit";

export class AudioCapturer {
  static audioCapturer: audio.AudioCapturer | undefined = undefined
  //新增：防止并发 start()（快速松手再按住时，上一次循环还没退出又开新录音会导致状态冲突）
  static busy: boolean = false
  //采样配置
  static audioStreamInfo: audio.AudioStreamInfo = {
    samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
    channels: audio.AudioChannel.CHANNEL_2,
    sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
    encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
  }
  //录音配置
  static audioCapturerInfo: audio.AudioCapturerInfo = {
    source: audio.SourceType.SOURCE_TYPE_MIC,
    capturerFlags: 0
  }
  //总体配置
  static audioCapturerOptions: audio.AudioCapturerOptions = {
    streamInfo: this.audioStreamInfo,
    capturerInfo: this.audioCapturerInfo
  }

  //初始化音频采集器的方法
  static async init() {
    //新增：若采集器已释放，重新创建（否则在已释放状态下 start 会报 illegal state）
    if (!AudioCapturer.audioCapturer
      || AudioCapturer.audioCapturer.state == audio.AudioState.STATE_RELEASED) {
      AudioCapturer.audioCapturer = await audio.createAudioCapturer(AudioCapturer.audioCapturerOptions)

    }
  }

  static recording: boolean = false

  //开始录音
  static async start(path: string) {
    //新增：上一次录音还没完全结束时忽略本次触发，避免并发导致 illegal state / system error
    if (AudioCapturer.busy) {
      return
    }

    //新增：只有 PREPARED/PAUSED 状态才能直接 start()，
    //STOPPED/RELEASED/未创建 都必须先释放重建，否则报 illegal state
    if (AudioCapturer.audioCapturer) {
      const st = AudioCapturer.audioCapturer.state
      if (st != audio.AudioState.STATE_PREPARED
        && st != audio.AudioState.STATE_PAUSED) {
        try {
          await AudioCapturer.audioCapturer.release()
        } catch (e) {
        }
        AudioCapturer.audioCapturer = undefined
      }
    }
    if (!AudioCapturer.audioCapturer) {
      await AudioCapturer.init()
      if (!AudioCapturer.audioCapturer) {
        return
      }
    }

    AudioCapturer.busy = true

    //新增：若上次没停干净（采集器还处于 RUNNING/PAUSED），先停一次，
    //避免再次 start() 时报 illegal state
    await AudioCapturer.stopCapturer()

    //新增：WAV 头参数（与 audioStreamInfo 配置保持一致；配置改了这里要同步）
    const sampleRate: number = AudioCapturer.audioStreamInfo.samplingRate
    const channels: number = 2          // audioStreamInfo.channels = CHANNEL_2
    const bitsPerSample: number = 16    // audioStreamInfo.sampleFormat = SAMPLE_FORMAT_S16LE
    const byteRate: number = sampleRate * channels * bitsPerSample / 8
    const blockAlign: number = channels * bitsPerSample / 8

    let fd: number = -1
    let pcmSize: number = 0
    try {
      AudioCapturer.recording = true
      await AudioCapturer.audioCapturer.start()

      //新增：启动完成前用户已松手（recording 被 stop() 置 false），
      //则不再进入采集循环，直接退出
      if (!AudioCapturer.recording) {
        await AudioCapturer.stopCapturer()
        return
      }

      //如果不存在就创建
      const file = fileIo.openSync(path, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE)
      fd = file.fd //文件标识

      //新增：先写 44 字节 WAV 文件头（两个大小字段先占位，录完再回填）
      const header = new ArrayBuffer(44)
      const dv = new DataView(header)
      dv.setUint32(0, 0x46464952, true)            // 'RIFF'
      dv.setUint32(4, 36, true)                    // RIFF 块大小(占位)
      dv.setUint32(8, 0x45564157, true)            // 'WAVE'
      dv.setUint32(12, 0x20746d66, true)           // 'fmt '
      dv.setUint32(16, 16, true)                   // fmt 块大小
      dv.setUint16(20, 1, true)                    // 音频格式 1=PCM
      dv.setUint16(22, channels, true)
      dv.setUint32(24, sampleRate, true)
      dv.setUint32(28, byteRate, true)
      dv.setUint16(32, blockAlign, true)
      dv.setUint16(34, bitsPerSample, true)
      dv.setUint32(36, 0x61746164, true)           // 'data'
      dv.setUint32(40, 0, true)                    // data 块大小(占位)
      fileIo.writeSync(fd, header)

      //循环读取音频；松手时 stop() 只把 recording 置 false，
      //这里的 read 会正常返回当前数据块后退出循环（不会被强行打断）
      while (AudioCapturer.recording) {
        let size = await AudioCapturer.audioCapturer.getBufferSize()
        let buffer = await AudioCapturer.audioCapturer.read(size, true)
        if (buffer) { //新增：read 可能返回空，判空避免写入异常
          //新增：顺序写入使用 fd 当前偏移即可，无需传 offset；原代码 offset:buffer 类型错误
          fileIo.writeSync(fd, buffer)
          pcmSize += buffer.byteLength
        }
      }

      //新增：循环退出后，再干净地停止采集器（此时 read 已不再阻塞，不会被打断）
      await AudioCapturer.stopCapturer()
    } catch (error) {
      //新增：catch 必须和 try 在同一方法体内（原代码把 catch 写在了方法外面，语法错误）
      //录音过程中的异常不再弹窗打扰，输出到 DevEco Log 便于排查
      console.error('AudioCapturer.start error:', JSON.stringify(error))
    } finally {
      //回填 WAV 头 + 关闭文件：无论正常结束还是异常中断，都保证产出可播放的 wav
      if (fd !== -1) {
        try {
          const riffSize = new ArrayBuffer(4)
          new DataView(riffSize).setUint32(0, 36 + pcmSize, true)
          fileIo.lseek(fd, 4, fileIo.WhenceType.SEEK_SET)
          fileIo.writeSync(fd, riffSize)

          const dataSize = new ArrayBuffer(4)
          new DataView(dataSize).setUint32(0, pcmSize, true)
          fileIo.lseek(fd, 40, fileIo.WhenceType.SEEK_SET)
          fileIo.writeSync(fd, dataSize)
        } catch (e) {
          console.error('backfill wav header error:', JSON.stringify(e))
        }
        fileIo.closeSync(fd)
      }
      //新增：无论成功失败都解除占用标记
      AudioCapturer.busy = false
    }
  }
  //新增：按采集器当前状态安全地停止采集器（仅 RUNNING/PAUSED 时可 stop，避免 illegal state）
  static async stopCapturer() {
    if (AudioCapturer.audioCapturer) {
      const st = AudioCapturer.audioCapturer.state
      if (st == audio.AudioState.STATE_RUNNING
        || st == audio.AudioState.STATE_PAUSED) {
        try {
          await AudioCapturer.audioCapturer.stop()
        } catch (e) {
          // 停止失败不阻塞后续流程
        }
      }
    }
  }
  //结束录音：只置标记让 start() 内的读取循环自然退出，
  //真正的 stop() 在 start() 循环退出后执行，避免打断阻塞中的 read 抛 system error
  static stop() {
    AudioCapturer.recording = false
  }

  static async release() {
    //新增：释放前先停止，避免在 RUNNING 状态直接 release() 报 illegal state
    AudioCapturer.recording = false
    await AudioCapturer.stopCapturer()
    if (AudioCapturer.audioCapturer) {
      try {
        await AudioCapturer.audioCapturer.release()
      } catch (e) {
        // 已释放等异常直接忽略
      }
      //新增：释放后置空引用，避免后续 start() 作用在已释放的采集器上报 illegal state
      AudioCapturer.audioCapturer = undefined
    }
  }


}

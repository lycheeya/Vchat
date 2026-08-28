// import { audio } from '@kit.AudioKit';
// import { fileIo } from '@kit.CoreFileKit';
// import { AUDIO_RENDERER_OPTIONS } from '../models/audio';
//
// /**
//  * 【旧代码已废弃 — 2026-08-27】
//  * 以下为原始代码的问题摘要：
//  * 1. import 路径错误：'.models/audio' → '../models/audio'
//  * 2. 存在未使用的 import { data } from '@kit.ArkUI'
//  * 3. start() 仅设置标志，未实现实际播放逻辑
//  * 4. playFile() 使用了不存在的 fileIo.Position.EndOfFile
//  * 5. 缺少 pause() / resume() / checkPlayEnd() 方法
//  * 6. 状态判断使用了数组 .includes()，ArkTS 不支持
//  * 7. release() 是同步方法但内部有异步操作
//  * 详细旧代码见下方注释块。
//  */
// // ====== 旧代码开始 ======
// // import { audio } from '@kit.AudioKit';
// // import { data } from '@kit.ArkUI';
// // import { fileIo } from '@kit.CoreFileKit';
// // import { AUDIO_RENDERER_OPTIONS } from '.models/audio';
// //
// // export class AudioRender {
// //   static renderModel: audio.AudioRenderer | undefined = undefined;
// //   static isPlaying: boolean = false;
// //   static shouldStop: boolean = false;
// //
// //   static async init(): Promise<void> {
// //     if (!AudioRender.renderModel || AudioRender.renderModel.state === audio.AudioState.STATE_RELEASED) {
// //       AudioRender.renderModel = await audio.createAudioRenderer(AUDIO_RENDERER_OPTIONS);
// //     }
// //   }
// //
// //   static start(filepath: string): void {
// //     if (!AudioRender.renderModel || !filepath) { return; }
// //     AudioRender.isPlaying = true;
// //   }
// //
// //   private static async playFile(filepath: string): Promise<void> {
// //     let file: fileIo.File | undefined = undefined;
// //     try {
// //       file = fileIo.openSync(filepath, fileIo.OpenMode.READ_ONLY);
// //       const WAV_HEADER_SIZE = 44;
// //       const bufSize = 4096;
// //       await AudioRender.renderModel?.start();
// //       while (!AudioRender.shouldStop) {
// //         const buffer: ArrayBuffer = new ArrayBuffer(bufSize);
// //         const readLen: number = fileIo.readSync(file.fd, buffer,
// //           { offset: fileIo.Position.EndOfFile, length: bufSize });
// //         if (readLen <= 0) { break; }
// //         const data: ArrayBuffer = buffer.slice(0, readLen);
// //         await AudioRender.renderModel?.write(data);
// //       }
// //       if (AudioRender.renderModel && AudioRender.renderModel.state === audio.AudioState.STATE_RUNNING) {
// //         await AudioRender.renderModel.stop();
// //       }
// //     } catch (error) {
// //       console.error('AudioRender 播放失败:', JSON.stringify(error));
// //     } finally {
// //       if (file) { fileIo.closeSync(file); }
// //       AudioRender.isPlaying = false;
// //       AudioRender.shouldStop = false;
// //     }
// //   }
// //
// //   static stop(): void {
// //     AudioRender.shouldStop = true;
// //   }
// //
// //   static release(): void {
// //     if (AudioRender.isPlaying) { AudioRender.shouldStop = true; }
// //     if (AudioRender.renderModel) {
// //       if ([audio.AudioState.STATE_RUNNING, audio.AudioState.STATE_PAUSED].includes(AudioRender.renderModel.state)) {
// //         AudioRender.renderModel.stop();
// //       }
// //       AudioRender.renderModel.release();
// //       AudioRender.renderModel = undefined;
// //     }
// //     AudioRender.isPlaying = false;
// //     AudioRender.shouldStop = false;
// //   }
// // }
// // ====== 旧代码结束 ======
//
// /**
//  * 音频播放器
//  * 用于播放 WAV 录音文件（PCM S16LE 双声道 44100Hz）
//  */
// export class AudioRender {
//   static renderModel: audio.AudioRenderer | undefined = undefined;
//   static isPlaying: boolean = false;
//   // 用于外部中断播放循环的标志
//   static shouldStop: boolean = false;
//
//   /**
//    * 初始化音频播放器（若已释放则重建）
//    */
//   static async init(): Promise<void> {
//     if (!AudioRender.renderModel
//       || AudioRender.renderModel.state === audio.AudioState.STATE_RELEASED) {
//       AudioRender.renderModel = await audio.createAudioRenderer(AUDIO_RENDERER_OPTIONS);
//     }
//   }
//
//   /**
//    * 开始播放指定路径的 WAV 音频文件
//    * @param filepath WAV 文件路径
//    */
//   static async start(filepath: string): Promise<void> {
//     if (!AudioRender.renderModel || !filepath) {
//       return;
//     }
//
//     // 如果已经在播放，先停止
//     if (AudioRender.isPlaying) {
//       await AudioRender.stop();
//     }
//
//     // 检查状态，确保可以从暂停/停止等状态恢复
//     const st = AudioRender.renderModel.state;
//     if (st !== audio.AudioState.STATE_PREPARED
//       && st !== audio.AudioState.STATE_STOPPED
//       && st !== audio.AudioState.STATE_PAUSED) {
//       return;
//     }
//
//     // 重置停止标志
//     AudioRender.shouldStop = false;
//     AudioRender.isPlaying = true;
//
//     // 异步执行播放逻辑，不阻塞调用方
//     // 【废弃】原代码未加 await，导致 start() 返回过早
//     // AudioRender.playFile(filepath);
//     await AudioRender.playFile(filepath);
//   }
//
//   /**
//    * 内部播放循环——读取 WAV 文件并喂数据给渲染器
//    */
//   private static async playFile(filepath: string): Promise<void> {
//     let file: fileIo.File | undefined = undefined;
//
//     try {
//       // 打开文件
//       file = fileIo.openSync(filepath, fileIo.OpenMode.READ_ONLY);
//
//       // WAV 文件头为 44 字节，先读取并丢弃头部
//       const WAV_HEADER_SIZE = 44;
//       const headerBuf: ArrayBuffer = new ArrayBuffer(WAV_HEADER_SIZE);
//       fileIo.readSync(file.fd, headerBuf);
//
//       const bufSize = 4096; // 每次读取 4KB
//
//       // 启动渲染器
//       await AudioRender.renderModel?.start();
//
//       // 循环读取 PCM 数据并写入渲染器
//       while (!AudioRender.shouldStop) {
//         const buffer: ArrayBuffer = new ArrayBuffer(bufSize);
//         const readLen: number = fileIo.readSync(file.fd, buffer);
//
//         // 如果已经读完了文件，则退出
//         if (readLen <= 0) {
//           break;
//         }
//
//         // 将有效数据截取出来
//         const data: ArrayBuffer = buffer.slice(0, readLen);
//
//         // 写入渲染器进行播放（等待缓冲区可用）
//         await AudioRender.renderModel?.write(data);
//       }
//
//       // 【废弃】原代码直接 stop()，缺少 drain() 会导致末尾音频截断
//       // if (AudioRender.renderModel
//       //   && AudioRender.renderModel.state === audio.AudioState.STATE_RUNNING) {
//       //   await AudioRender.renderModel.stop();
//       // }
//       // 排空缓冲区，确保所有数据播放完毕
//       if (AudioRender.renderModel
//         && AudioRender.renderModel.state === audio.AudioState.STATE_RUNNING) {
//         await AudioRender.renderModel.drain();
//         await AudioRender.renderModel.stop();
//       }
//     } catch (error) {
//       console.error('AudioRender 播放失败:', JSON.stringify(error));
//     } finally {
//       // 关闭文件
//       if (file) {
//         fileIo.closeSync(file);
//       }
//       AudioRender.isPlaying = false;
//       AudioRender.shouldStop = false;
//     }
//   }
//
//   /**
//    * 暂停播放
//    */
//   static async pause(): Promise<void> {
//     if (!AudioRender.renderModel || !AudioRender.isPlaying) {
//       return;
//     }
//     if (AudioRender.renderModel.state === audio.AudioState.STATE_RUNNING) {
//       await AudioRender.renderModel.pause();
//     }
//   }
//
//   /**
//    * 恢复播放
//    */
//   static async resume(): Promise<void> {
//     if (!AudioRender.renderModel) {
//       return;
//     }
//     if (AudioRender.renderModel.state === audio.AudioState.STATE_PAUSED) {
//       await AudioRender.renderModel.start();
//     }
//   }
//
//   /**
//    * 停止播放并重置播放器
//    */
//   static async stop(): Promise<void> {
//     // 设置停止标志，中断播放循环
//     AudioRender.shouldStop = true;
//     AudioRender.isPlaying = false;
//
//     if (AudioRender.renderModel) {
//       const st = AudioRender.renderModel.state;
//       if (st === audio.AudioState.STATE_RUNNING) {
//         await AudioRender.renderModel.stop();
//       } else if (st === audio.AudioState.STATE_PAUSED) {
//         await AudioRender.renderModel.stop();
//       }
//     }
//   }
//
//   /**
//    * 返回一个 Promise，在播放结束后 resolve(true)
//    */
//   static checkPlayEnd(): Promise<boolean> {
//     return new Promise<boolean>((resolve: (value: boolean) => void) => {
//       const intervalId = setInterval(() => {
//         if (!AudioRender.isPlaying) {
//           clearInterval(intervalId);
//           resolve(true);
//         }
//       }, 200);
//     });
//   }
//
//   /**
//    * 释放播放器资源
//    */
//   static async release(): Promise<void> {
//     // 先停止
//     if (AudioRender.isPlaying) {
//       AudioRender.shouldStop = true;
//     }
//
//     if (AudioRender.renderModel) {
//       const st = AudioRender.renderModel.state;
//       if (st === audio.AudioState.STATE_RUNNING
//         || st === audio.AudioState.STATE_PAUSED) {
//         await AudioRender.renderModel.stop();
//       }
//       await AudioRender.renderModel.release();
//       AudioRender.renderModel = undefined;
//     }
//     AudioRender.isPlaying = false;
//     AudioRender.shouldStop = false;
//   }
// }

// 用来播放pcm音频
import { audio } from '@kit.AudioKit'
import { fileIo } from '@kit.CoreFileKit';

export class AudioRender {
  static renderIng: boolean = false // 是否正在播放
  // 实例
  static renderModel: audio.AudioRenderer
  // 播放结束 Promise 机制（供 checkPlayEnd 使用）
  private static _playEndResolve: ((value: boolean) => void) | undefined = undefined
  private static _playEndPromise: Promise<boolean> = Promise.resolve(false)
  // 采样配置
  static audioStreamInfo: audio.AudioStreamInfo = {
    samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
    channels: audio.AudioChannel.CHANNEL_2,
    sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
    encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
  };
  static audioRendererInfo: audio.AudioRendererInfo = {
    rendererFlags: 0, // 音频渲染器 0 普通  1 低时延 (不支持)
    usage: audio.StreamUsage.STREAM_USAGE_MOVIE
    // 场景
  }
  // 创建播放器的参数准备好了
  static audioRendererOptions: audio.AudioRendererOptions = {
    streamInfo: AudioRender.audioStreamInfo,
    rendererInfo: AudioRender.audioRendererInfo
  }
  // 初始化方法
  static async init () {
    if(!AudioRender.renderModel) {
      // 创建实例
      AudioRender.renderModel = await audio.createAudioRenderer(AudioRender.audioRendererOptions)
    }
  }
  // 音频的释放和暂停
  static async stop () {
    if(AudioRender.renderModel && AudioRender.renderModel.state === audio.AudioState.STATE_RUNNING) {
      AudioRender.renderIng = false;
      await AudioRender.renderModel.stop(); // 通知方法

    }
  }
  // 开始语音播放
  static  async start (filePath: string, callback?: () => void) {
    if(AudioRender.renderModel && filePath) {
      // 先管一下状态
      // 如果你在播的情况下 还能播吗？
      // 什么情况下能播？ 暂停 停止 准备
      // 检查状态，确保可以从暂停/停止等状态恢复
      const st = AudioRender.renderModel.state;
      if (st !== audio.AudioState.STATE_PREPARED
        && st !== audio.AudioState.STATE_PAUSED
        && st !== audio.AudioState.STATE_STOPPED) {
        // 不在允许的状态下，此时就不能播了
        return;
      }
      // 此时可以播
      AudioRender.renderIng = true
      // 创建播放结束 Promise，供外部通过 checkPlayEnd() 监听
      AudioRender._playEndPromise = new Promise<boolean>((resolve) => {
        AudioRender._playEndResolve = resolve
      })

      await AudioRender.renderModel.start() // 启动播放
      // 【废弃/错误】原代码直接读取整个文件，但录音保存为 WAV 格式（含 44 字节文件头），
      // 未跳过头导致 RIFF/WAVE 标记被当作 PCM 数据喂入 AudioRenderer，产生爆音/杂音。
      // const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY)
      // const stat = fileIo.statSync(file.fd)
      const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY)
      const stat = fileIo.statSync(file.fd)
      // 跳过 44 字节 WAV 文件头（RIFF/WAVE/fmt 等标记），使文件指针指向 PCM 数据起始位置
      const wavHeaderSize: number = 44
      const headerBuf = new ArrayBuffer(wavHeaderSize)
      fileIo.readSync(file.fd, headerBuf)
      const bufferSize = await AudioRender.renderModel.getBufferSize() // 获取缓冲区的长度
      let buf = new ArrayBuffer(bufferSize) // 创建一个缓冲区对象 长度是音频采集器长度的长度
      let totalSize = 0 // 总量值
      let fileClosed = false; // 标记文件是否已关闭
      while (totalSize < stat.size - wavHeaderSize &&  AudioRender.renderIng) {
        fileIo.readSync(file.fd, buf, {
          offset: totalSize + wavHeaderSize, // 加 44 跳过 WAV 头
          length: bufferSize
        })
        // 坑点- write是个异步方法  需要一段段的去播放 需要写入完这一段以后 再去写入下一段
        await AudioRender.renderModel.write(buf) // 往音频采集器写入缓冲区内容  播完再下一段
        if (AudioRender.renderModel!.state.valueOf() === audio.AudioState.STATE_RELEASED) { // 如果渲染器状态为released，关闭资源
          fileIo.closeSync(file.fd);
          fileClosed = true;
          break; // 退出播放循环
        }
        // 此时要继续
        totalSize += bufferSize
      }
      // 关闭文件（仅在未关闭的情况下）
      if (!fileClosed) {
        fileIo.closeSync(file.fd)
      }
      // 播放完成，设置播放状态为非播放中
      AudioRender.renderIng = false
      callback && callback()
      // 通知外部播放已结束
      AudioRender._playEndResolve && AudioRender._playEndResolve(true)
    }
  }
  // 释放
  static async release () {
    if(AudioRender.renderModel) {
      await AudioRender.renderModel.release() // 释放方法
    }
  }
  // 返回一个 Promise，在 start() 内部循环结束时 resolve
  public static checkPlayEnd(): Promise<boolean> {
    return AudioRender._playEndPromise
  }
}

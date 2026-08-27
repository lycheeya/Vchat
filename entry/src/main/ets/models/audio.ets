import { audio } from '@kit.AudioKit';

/**
 * 【旧代码已废弃 — 2026-08-27】
 * 原为接口定义，但将枚举值用作类型注解导致无效语法，且无法作为值导入使用。
 * 改为下方实际配置对象常量。
 */
// export interface AudioStreamInfo {
//   samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100;
//   channels: audio.AudioChannel.CHANNEL_2;
//   sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE;
//   encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW;
// }
// export interface AudioRendererInfo {
//   usage: audio.StreamUsage.STREAM_USAGE_VOICE_COMMUNICATION;
//   rendererFlags: 0;
// }
// export interface AudioRendererOptions {
//   streamInfo: AudioStreamInfo;
//   rendererInfo: AudioRendererInfo;
// }

/**
 * 音频流配置（与 AudioCapturer 保持一致，便于录放切换）
 */
export const AUDIO_STREAM_INFO: audio.AudioStreamInfo = {
  samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
  channels: audio.AudioChannel.CHANNEL_2,
  sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
  encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
};

/**
 * 音频播放器配置
 */
export const AUDIO_RENDERER_INFO: audio.AudioRendererInfo = {
  usage: audio.StreamUsage.STREAM_USAGE_MOVIE,
  rendererFlags: 0
};

/**
 * 音频播放器完整配置选项
 */
export const AUDIO_RENDERER_OPTIONS: audio.AudioRendererOptions = {
  streamInfo: AUDIO_STREAM_INFO,
  rendererInfo: AUDIO_RENDERER_INFO
};

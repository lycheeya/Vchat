# 代码变更日志

## 2026-08-27

### 1. 修复 `models/audio.ets` — 接口定义改为配置常量对象

- **旧代码（原问题）**：定义了接口 `AudioStreamInfo`、`AudioRendererInfo`、`AudioRendererOptions`，但内容为枚举值的 `:type` 注解形式的无效语法（如 `samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100` 作为类型注解是无意义的），且 `audioRender.ets` 试图将其作为值导入使用。
- **新代码**：改为直接导出实际的配置常量对象，与 `audioRecord.ets` 风格一致。
- **原因**：原代码混淆了类型与值，编译报错。

### 2. 重写 `utills/audioRender.ets` — 完整的音频播放器

- **核心修复**：
  - 导入路径 `'.models/audio'` → `'../models/audio'`
  - 从 `audio.ets` 导入配置常量而非接口
  - `init()` 补全 `await`
  - 新增 `start(filepath)` — 打开WAV文件，跳过44字节头，循环读取PCM数据喂入渲染器
  - 新增 `pause()` / `resume()` 方法
  - 新增 `checkPlayEnd()` Promise 跟踪播放结束
  - 新增 `isPlaying` / `shouldStop` 播放状态标志
  - 移除未使用的 `import { data }`
- **原因**：原 `start()` 未实现任何播放逻辑；缺少暂停/恢复功能。

### 3. 完善 `pages/chtedetail/components/Message.ets` — 语音消息交互

- 导入 `AudioRender`
- 新增 `playAudio()` 方法：点击播放/停止
- 音频气泡 `.onClick()` 绑定播放
- 播放时视觉反馈（背景变蓝、文字变蓝）
- 新增 `isPlaying` 状态
- 新增 `aboutToDisappear` 清理音频资源
- **原因**：语音消息无可交互的播放操作。

### 4. 修复 `pages/chtedetail/chatDetail.ets` — `release()` 缺少 await

- `AudioRender.release()` → `await AudioRender.release()`
- **原因**：`release()` 已改为 async 方法，需要 await 等待资源释放完成。

### 5. 修复 `utills/audioRender.ets` — `start()` 未 await playFile()

- **旧代码**：
  ```typescript
  AudioRender.playFile(filepath);  // 未 await，start() 在播放开始前就返回
  ```
- **新代码**：
  ```typescript
  // 【废弃】原代码未加 await，导致 start() 返回过早
  // AudioRender.playFile(filepath);
  await AudioRender.playFile(filepath);
  ```
- **原因**：`start()` 不等待 `playFile()` 完成即返回，若播放刚启动就调 `stop()`，中断信号可能丢失或状态不一致。

### 6. 修复 `utills/audioRender.ets` — `playFile()` 播放结束缺少 drain()

- **旧代码**：
  ```typescript
  // 停止渲染器
  if (AudioRender.renderModel
    && AudioRender.renderModel.state === audio.AudioState.STATE_RUNNING) {
    await AudioRender.renderModel.stop();
  }
  ```
- **新代码**：
  ```typescript
  // 【废弃】原代码直接 stop()，缺少 drain() 会导致末尾音频截断
  // ...
  // 排空缓冲区，确保所有数据播放完毕
  if (AudioRender.renderModel
    && AudioRender.renderModel.state === audio.AudioState.STATE_RUNNING) {
    await AudioRender.renderModel.drain();
    await AudioRender.renderModel.stop();
  }
  ```
- **原因**：音频缓冲区可能残留未播放的数据，直接 `stop()` 导致末尾音频截断，添加 `drain()` 确保数据全部播放完毕再停止。

### 7. 修复 `utills/audioRender.ets` — 类名 `AudioRenderer` → `AudioRender` + 新增 `checkPlayEnd()`

- **旧代码**：
  - 类名定义为 `export class AudioRenderer`，但 `Message.ets` 和 `chatDetail.ets` 均以 `AudioRender` 导入，导致编译报错 `has no exported member named 'AudioRender'`。
  - 类中缺少 `checkPlayEnd()` 方法，`Message.ets` 调用时报 `Property 'checkPlayEnd' does not exist`。
- **新代码**：
  - 类名从 `AudioRenderer` 改回 `AudioRender`，与导入名一致。
  - 新增私有字段 `_playEndPromise` / `_playEndResolve`，在 `start()` 播放开始时创建 Promise，播放结束后 resolve。
  - 新增公有方法 `checkPlayEnd(): Promise<boolean>`，返回该 Promise。
- **原因**：类名不一致导致导入失败；缺少 `checkPlayEnd()` 导致 `Message.ets` 无法监听播放结束事件。

### 8. 修复 `utills/audioRender.ets` — WAV 文件头未跳过 + 采样率/声道数与录音端不匹配

- **旧代码**（`start()` 方法）：
  - 打开文件后直接读取整个文件作为 PCM 数据喂入 AudioRenderer，未跳过 44 字节 WAV 文件头。
  - `AudioStreamInfo` 配置为 `SAMPLE_RATE_16000` / `CHANNEL_1`，但录音端保存的 WAV 文件为 `44100Hz` / `CHANNEL_2`。
- **新代码**：
  - 在 `start()` 中打开文件后，先读取 44 字节 WAV 头（RIFF/WAVE/meta 标记），使文件指针指向 PCM 数据起始位置。
  - while 循环条件从 `totalSize < stat.size` 改为 `totalSize < stat.size - 44`，readSync 的 `offset` 参数加 `wavHeaderSize` 以跳过头部。
  - `AudioStreamInfo` 改为 `SAMPLE_RATE_44100` / `CHANNEL_2`，与录音端 `AudioCapturer` 配置一致。
- **原因**：WAV 头未跳过导致 RIFF/WAVE 标记作为杂音喂入渲染器；采样率/声道不匹配导致播放速度与声道解码错误，综合导致模拟器上无法正常播放语音。

### 9. 修复 `pages/chtedetail/components/Message.ets` — 语音帧动画不显示

- **旧代码**（`getAudioContent()` 中的 `ImageAnimator`）：
  - `.state()` 调用了两次：先 `.state(this.isPlaying ? ...)`，紧接 `.state(this.audiostate)` 将其覆盖。
  - `.duration(1000)` 被注释掉，动画周期时长为默认值 0ms，4 帧动画瞬间播完不可见。
- **新代码**：
  - 移除冗余的第一次 `.state()` 调用，只保留 `.state(this.audiostate)`。
  - 取消注释 `.duration(1000)`，使动画周期为 1 秒，帧切换肉眼可见。
- **原因**：两次 `.state()` 调用导致逻辑冗余且混乱；`duration` 缺失使动画在 0ms 内完成，肉眼看不到帧切换效果。

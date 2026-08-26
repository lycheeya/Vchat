# 录音文件管理功能改进说明

## 改进概述
本次改进主要增强了录音文件的存储管理功能，将录音文件更加系统化地存储到沙箱文件中，按照聊天会话进行分类管理。

## 主要变更

### 1. 新增 ChatAudioFile 工具类
- 创建了 `entry/src/main/ets/utills/chatAudioFile.ets` 文件
- 提供专门的聊天音频文件管理功能
- 按照聊天双方ID创建独立的音频文件目录

### 2. 文件存储结构优化
- 原来的存储方式：`getContext().filesDir + '/' + UUID + '.wav'`
- 新的存储方式：`getContext().filesDir/chat_audio/{chatId}/{audio_filename}.wav`
- 其中 `{chatId}` 是由两个用户ID按字母顺序组合而成的唯一标识

### 3. bottominput 组件改进
- 导入了新的 `ChatAudioFile` 工具类
- 修改了 `begainrecord()` 方法，使用新的音频文件管理功能
- 修改了 `releaseFinger()` 方法，使用新的音频文件删除功能
- 保持了原有的消息发送逻辑不变

## 功能特点

### 自动分类管理
- 根据聊天双方ID自动创建对应的音频文件夹
- 不同聊天会话的录音文件分开存储

### 文件安全
- 使用沙箱文件系统，确保文件安全
- 提供了完善的错误处理机制

### 兼容性
- 保持与原有消息系统的兼容性
- 消息对象中的 `sourceFilePath` 属性仍然有效

## 实现细节

### ChatAudioFile 类提供的方法：
- `createChatAudioFile(chatId: string)` - 创建聊天音频文件
- `getChatAudioDir(chatId: string)` - 获取聊天音频目录
- `deleteChatAudioFile(filePath: string)` - 删除指定音频文件
- `cleanChatAudioFiles(chatId: string)` - 清理整个聊天的音频文件

## 注意事项
- 录音文件现在存储在应用沙箱的 `chat_audio` 目录下
- 每个聊天会话都有独立的音频文件夹
- 文件名包含时间戳和UUID，确保唯一性
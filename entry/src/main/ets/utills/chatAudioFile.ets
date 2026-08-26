import { fileIo } from "@kit.CoreFileKit";
import { util } from "@kit.ArkTS";

export class ChatAudioFile {
  // 创建聊天录音文件的方法，将录音保存到专门的聊天记录目录
  static createChatAudioFile(chatId: string) {
    try {
      // 获取应用沙箱文件目录
      const baseDir = getContext().filesDir;
      
      // 创建聊天音频目录
      const chatAudioDir = `${baseDir}/chat_audio`;
      if (!fileIo.accessSync(chatAudioDir)) {
        fileIo.mkdirSync(chatAudioDir);
      }
      
      // 为特定聊天创建子目录
      const chatDir = `${chatAudioDir}/${chatId}`;
      if (!fileIo.accessSync(chatDir)) {
        fileIo.mkdirSync(chatDir);
      }
      
      // 生成唯一的音频文件名
      const fileName = `audio_${Date.now()}_${util.generateRandomUUID()}.wav`;
      const filePath = `${chatDir}/${fileName}`;
      
      // 创建文件
      const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE);
      fileIo.closeSync(file);
      
      return filePath;
    } catch (error) {
      console.error('创建聊天音频文件失败:', error);
      // 如果创建聊天专用目录失败，则回退到默认目录
      const path = getContext().filesDir + '/' + util.generateRandomUUID() + '.wav';
      const file = fileIo.openSync(path, fileIo.OpenMode.CREATE);
      fileIo.closeSync(file);
      return path;
    }
  }

  // 获取聊天音频文件目录
  static getChatAudioDir(chatId: string): string {
    const baseDir = getContext().filesDir;
    return `${baseDir}/chat_audio/${chatId}`;
  }

  // 删除聊天音频文件
  static deleteChatAudioFile(filePath: string) {
    try {
      if (filePath && fileIo.accessSync(filePath)) {
        fileIo.unlinkSync(filePath);
      }
    } catch (error) {
      console.error('删除聊天音频文件失败:', error);
      // 如果删除失败，尝试直接删除
      try {
        fileIo.unlinkSync(filePath);
      } catch (e) {
        console.error('强制删除聊天音频文件失败:', e);
      }
    }
  }

  // 清理整个聊天的音频文件
  static cleanChatAudioFiles(chatId: string) {
    try {
      const chatDir = ChatAudioFile.getChatAudioDir(chatId);
      if (fileIo.accessSync(chatDir)) {
        const fileList = fileIo.listFileSync(chatDir);
        fileList.forEach(fileName => {
          const fullPath = `${chatDir}/${fileName}`;
          fileIo.unlinkSync(fullPath);
        });
        // 删除空的聊天目录
        fileIo.rmdirSync(chatDir);
      }
    } catch (error) {
      console.error('清理聊天音频文件失败:', error);
    }
  }
}
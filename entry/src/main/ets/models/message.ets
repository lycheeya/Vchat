import { UserInfo, UserInfomModel } from "./user"
import { util } from "@kit.ArkTS"

export interface MessageInfo{
  id:string
  sendUser:UserInfo//这条消息的发送者
  connectUser:UserInfo//这条消息的归属者
  messageContent:string//消息内容 文本信息 【图片】 【语音 7】
  sendTimer:number//发送时间

  messageType:MessageTypeEnum //消息类型
  sourceFilePath:string//音视频、图片等本地地址（沙箱内）
  sourceDuration:number//音视频长度，单位：秒 s

}
//一共消息类型的枚举
export enum MessageTypeEnum{
  TEXT,//文本
  IMAGE,//图片
  AUDIO,//音频
  VIDEO,//视频
  LOCATION,//定位
  LINK//链接


}

export class MessageInfoModel implements MessageInfo{
  id: string = ''
  sendUser: UserInfo = new UserInfomModel({} as UserInfo)
  connectUser: UserInfo = new UserInfomModel({} as UserInfo)
  messageContent: string = ''
  sendTimer: number = 0
  messageType: MessageTypeEnum = MessageTypeEnum.TEXT
  sourceFilePath: string = ''
  sourceDuration: number = 0

  constructor(model: MessageInfo) {
    this.id = model.id || util.generateRandomUUID() //生成uuid
    this.sendUser = model.sendUser
    this.connectUser = model.connectUser
    this.messageContent = model.messageContent
    this.sendTimer = model.sendTimer || Date.now() //发送时间
    this.messageType = model.messageType || MessageTypeEnum.TEXT
    this.sourceFilePath = model.sourceFilePath
    this.sourceDuration =  model.sourceDuration || 0
  }

}


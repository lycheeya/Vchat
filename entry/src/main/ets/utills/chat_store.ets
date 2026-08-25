//首选项的读取数据
import { preferences } from '@kit.ArkData';

import { vchat_storeKey, vchat_ConnectKey, vchat_ConnectUserKey, Record_Update_Eventname } from '../constant';
import { MessageInfoModel } from '../models/message';
import { CurrentUser, DefaultuserList, UserInfo, UserInfomModel } from '../models/user';
import { vchat_UserRecordKey } from '../constant/index';
import json from '@ohos.util.json';
import emitter from '@ohos.events.emitter';


export class Vchatstore{
  static context:Context

  static getvchatstore(){

    // 修复：原写法 perferences.getPerferencesSync 拼写错误，导致编译报错
    return preferences.getPreferencesSync(Vchatstore.context || getContext(),{
      name:vchat_storeKey
    })
  }
  //获取微信联系人
  static getvchatconnect(): UserInfomModel[]
  {
    const store = Vchatstore.getvchatstore()
    const cached = store.getSync(vchat_ConnectKey, '') as string
    if (cached !== '') {
      return JSON.parse(cached) as UserInfomModel[]
    }
    // 头像使用本地 $r 资源，直接映射为模型实例，
    // 避免 JSON 序列化把 Resource 对象转成普通对象导致图片无法显示
    return DefaultuserList.map((item: UserInfo) => new UserInfomModel(item))

  }

  static getcurrentuser()
  {
    const store = Vchatstore.getvchatstore()
    return JSON.parse(store.getSync(vchat_ConnectUserKey,JSON.stringify(CurrentUser)) as string) as UserInfomModel
  }

  //获取我和某个人的聊天记录的仓库
  static getVchatMessageStore(userId:string){
    return preferences.getPreferencesSync(getContext(),{
      name:`${vchat_UserRecordKey}_${userId}`
    })

  }

  //获取我和某个人的整个聊天记录
  //Vchat_userrecordkey + userId => 所有的聊天记录
  static getVchatMessage(userId:string){
    const store = Vchatstore.getVchatMessageStore(userId)//我和某个人的仓库
    const allRecord = store.getAllSync() as object
    const list = Object.values(allRecord).map((item:string) => JSON.parse(item) as MessageInfoModel)//乱序
    list.sort((a:MessageInfoModel,b:MessageInfoModel) => a.sendTimer - b.sendTimer) // 按正序排列
    return list
    //【错误】读取键名 vchat_UserRecordKey + userId 缺少下划线分隔符，与写入键名 `${vchat_UserRecordKey}_${userId}` 不一致，导致读取永远命中默认空数组
    //return JSON.parse(store.getSync(vchat_UserRecordKey + userId, '[]') as string) as MessageInfoModel[]
    // return JSON.parse(store.getSync(`${vchat_UserRecordKey}_${userId}`, '[]') as string) as MessageInfoModel[]
  }
  //删除我和某人的整个聊天记录
  static async deletevchatMessage(userId:string){
    preferences.deletePreferences(getContext(),{
      name:`${vchat_UserRecordKey}_${userId}`
    })
  }

  //添加一条我和某人的聊天记录
  static async addone_vchatMessage(userId:string,message:MessageInfoModel){
    const store = Vchatstore.getVchatMessageStore(userId)//我和某个人的仓库
    store.putSync(message.id,JSON.stringify(message))//消息是用uuid构成的 每一个都是不同的
    await store.flush()
    emitter.emit(Record_Update_Eventname)
  }

  //删除一条我和某人的聊天记录
  static async deleteone_vchatMessage(userId:string,messageId:string){
    const store = Vchatstore.getVchatMessageStore(userId)
    store.deleteSync(messageId)
    await store.flush() //写入磁盘
    emitter.emit(Record_Update_Eventname)

  }

  //获取所有聊天记录的最后一条（每个会话取最后一条，按时间倒序返回）
  static getAlllastmessage(){
    const users = Vchatstore.getvchatconnect() // 所有联系人
    const list: MessageInfoModel[] = []
    users.forEach(user => {
      // 每个联系人的聊天记录存储在独立仓库里：${vchat_UserRecordKey}_${userId}
      // 通过 getVchatMessage 获取该联系人的全部聊天记录（已按时间正序排列），取最后一条即最新消息
      const vMesasag = Vchatstore.getVchatMessage(user.user_id)
      if (vMesasag && vMesasag.length) {
        list.push(vMesasag[vMesasag.length - 1])
      }
    })
    list.sort((a: MessageInfoModel, b: MessageInfoModel) => b.sendTimer - a.sendTimer) // 倒序
    return list
  }


}                             
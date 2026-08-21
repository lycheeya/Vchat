//首选项的读取数据
import { preferences } from '@kit.ArkData';

import { vchat_storeKey, vchat_ConnectKey, vchat_ConnectUserKey } from '../constant';
import { MessageInfoModel } from '../models/message';
import { CurrentUser, DefaultuserList, UserInfo, UserInfomModel } from '../models/user';
import { vchat_UserRecordKey } from '../constant/index';
import json from '@ohos.util.json';


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

  //获取我和某个人的整个聊天记录
  //Vchat_userrecordkey + userId => 所有的聊天记录
  static getVchatMessage(userId:string){
    const store = Vchatstore.getvchatstore()
    //【错误】读取键名 vchat_UserRecordKey + userId 缺少下划线分隔符，与写入键名 `${vchat_UserRecordKey}_${userId}` 不一致，导致读取永远命中默认空数组
    //return JSON.parse(store.getSync(vchat_UserRecordKey + userId, '[]') as string) as MessageInfoModel[]
    return JSON.parse(store.getSync(`${vchat_UserRecordKey}_${userId}`, '[]') as string) as MessageInfoModel[]
  }
  //删除我和某人的整个聊天记录
  static async deletevchatMessage(userId:string){
    const store = Vchatstore.getvchatstore()
    store.deleteSync(`${vchat_UserRecordKey}_${userId}`)
    await store.flush()
  }

  //添加一条我和某人的聊天记录
  static async addone_vchatMessage(userId:string,message:MessageInfoModel){
    const store = Vchatstore.getvchatstore()
    const list = Vchatstore.getVchatMessage(userId)
    list.push(message)
    //写入list
    store.putSync(`${vchat_UserRecordKey}_${userId}`,JSON.stringify(list))
    await store.flush() //写入磁盘
  }

  //删除一条我和某人的聊天记录
  static async deleteone_vchatMessage(userId:string,messageId:string){
    const store = Vchatstore.getvchatstore()
    const list = Vchatstore.getVchatMessage(userId)
    const index = list.findIndex(item => item.id == messageId)
    list.splice(index,1)
    //写入list
    store.putSync(`${vchat_UserRecordKey}_${userId}`,JSON.stringify(list))
    await store.flush() //写入磁盘
  }

  //获取所有聊天记录的最后一条
  static getAlllastmessage(){
    const store = Vchatstore.getvchatstore()
    const arr:MessageInfoModel[] = []
    const result = store.getAllSync() as object //坑点 小写的object才可以用【】括住
    Object.keys(result).forEach(key => {
      if(key.includes(vchat_UserRecordKey)){
        if(result[key]) {
          const list = JSON.parse(result[key]) as MessageInfoModel[]  //所有的聊天记录
          if(list.length) {
            arr.push(list[list.length - 1])

          }
        }
      }
    })
    AlertDialog.show({message:JSON.stringify(arr)})
    arr.sort((a:MessageInfoModel,b:MessageInfoModel) => {
      return b.sendTimer - a.sendTimer//使其进行降序排序
    })//对原数组进行排序，没有产生新数组

    return arr
  }


}
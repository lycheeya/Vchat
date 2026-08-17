//首选项的读取数据
import { preferences } from '@kit.ArkData';

import { vchat_storeKey, vchat_ConnectKey, vchat_ConnectUserKey } from '../constant';
import { CurrentUser, DefaultuserList, UserInfo, UserInfomModel } from '../models/user';

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
}
export interface UserInfo{
  user_name:string //用户名
  user_picture:ResourceStr //用户标识
  user_id:string//头像字段
}
export class UserInfomModel implements UserInfo {
  user_name: string = ''
  user_picture: ResourceStr = ''
  user_id: string = ''

  constructor(model: UserInfo) {
    this.user_name = model.user_name
    this.user_picture = model.user_picture
    this.user_id = model.user_id
  }
}

// 默认用户数据（使用本地资源头像，避免远程图片无法加载）
export const DefaultuserList: UserInfo[] = [
  {
    user_name: '小明',
    user_picture: $r('app.media.avatar1'),
    user_id: '10001'
  },
  {
    user_name: '小红',
    user_picture: $r('app.media.avatar2'),
    user_id: '10002'
  },
  {
    user_name: '风吹雪',
    user_picture: $r('app.media.avatar3'),
    user_id: '10003'
  },
  {
    user_name: '李娜',
    user_picture: $r('app.media.avatar4'),
    user_id: '10004'
  },
  {
    user_name: '匆匆那年',
    user_picture: $r('app.media.avatar5'),
    user_id: '10005'
  },
  {
    user_name: '刘洋',
    user_picture: $r('app.media.avatar6'),
    user_id: '10006'
  },
  {
    user_name: '陈静',
    user_picture: $r('app.media.avatar7'),
    user_id: '10007'
  },
  {
    user_name: '赵磊',
    user_picture: $r('app.media.avatar8'),
    user_id: '10008'
  },
  {
    user_name: '芳姐',
    user_picture: $r('app.media.avatar9'),
    user_id: '10009'
  },
  {
    user_name: '吴迪',
    user_picture: $r('app.media.avatar10'),
    user_id: '10010'
  }
]


export const CurrentUser:UserInfo = {
  user_name:'小赵',
  user_picture:$r('app.media.user_img'),
  user_id:'9999'
}
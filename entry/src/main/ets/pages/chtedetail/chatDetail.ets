import { router } from '@kit.ArkUI'
import { vchat_ConnectUserKey } from '../../constant'
import { UserInfo, UserInfomModel } from '../../models/user'
import Bottominput from './components/bottominput'

@Entry
@Component
struct chatDetail {

  @StorageProp(vchat_ConnectUserKey)
  currentuser:UserInfomModel = new UserInfomModel({} as UserInfo)
  @Provide talker:UserInfomModel = new UserInfomModel({} as UserInfo)
  aboutToAppear(): void {
    //获取和我对话的用户资料
    this.getTalker()
  }
  getTalker(){
    this.talker = router.getParams() as UserInfomModel
  }
  build() {

    Column() {
      Stack({alignContent:Alignment.Start}){

        Text(this.talker.user_name)
          .fontSize(20)
          .width('100%')
          .textAlign(TextAlign.Center)

        Image($r('app.media.chevron_left'))
          .width(20)
          .aspectRatio(1)
          .onClick(() => {
            router.back()
          })

      }
      .width('100%')
      .height(50)
      .padding({left:10,right:10})

      Text(JSON.stringify(this.talker))

      Bottominput()


    }
    .height('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    // .width('100%')


  }
}
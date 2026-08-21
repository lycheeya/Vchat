import { router } from '@kit.ArkUI'
import { vchat_ConnectUserKey } from '../../constant'
import { MessageInfo, MessageInfoModel } from '../../models/message'
import { UserInfo, UserInfomModel } from '../../models/user'
import Bottominput from './components/bottominput'
import Message from './components/Message'

@Entry
@Component
struct chatDetail {

  @State messageList:MessageInfoModel[] = []

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
//发送文本消息
  sendTextMessage(content:string){
    let mess = new MessageInfoModel({
      messageContent:content,
      sendUser:this.currentuser,//我发的消息
      connectUser:this.talker//我和对方的聊天记录
    } as MessageInfo)

    this.messageList.push(mess)//追加消息
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

      List({space:20}){
        ForEach(this.messageList,(item:MessageInfoModel) => {
          ListItem()
          {
            Message({currentMessage:item})
          }
        })
      }
      .padding({top:9})
      .backgroundColor('#EBEDEF')
      .layoutWeight(1)

      //底部内容
      Bottominput({
        sendTextMessage:(content:string) => {
          this.sendTextMessage(content)
        }
      })


    }
    .height('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    // .width('100%')

  }
}
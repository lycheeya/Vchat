import { vchat_ConnectUserKey } from "../../../constant"
import { MessageInfo, MessageInfoModel } from "../../../models/message"
import { UserInfo, UserInfomModel } from "../../../models/user"

@Preview
@Component
struct Message {

  @StorageProp(vchat_ConnectUserKey)
  currentuser:UserInfomModel = new UserInfomModel({} as UserInfo)

  //  当前发送的内容
  @Require @Prop currentMessage:MessageInfoModel = new MessageInfoModel({} as MessageInfo)

  @State isOwnMessage:boolean = this.currentuser.user_id == this.currentMessage?.sendUser?.user_id

  build() {
    Row()
    {
      Image(this.currentMessage.sendUser?.user_picture)
        .width(40)
        .aspectRatio(1)
        .borderRadius(4)
        .objectFit(ImageFit.Cover)
      Row()
      {
        Text(this.currentMessage.messageContent ?? '')
          .backgroundColor(this.isOwnMessage ? '#9eea6a' : Color.White)
          .padding(10)
          .margin({left:10,right:10})
          .borderRadius(5)
      }
      .justifyContent(this.isOwnMessage ? FlexAlign.End : FlexAlign.Start)
      .layoutWeight(6)
    }
    .padding({left:20,right:20})
    .direction(this.isOwnMessage ? Direction.Rtl : Direction.Ltr)
  }
}

export default Message
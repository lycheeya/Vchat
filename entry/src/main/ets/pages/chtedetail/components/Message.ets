import { vchat_ConnectUserKey } from "../../../constant"
import { MessageInfo, MessageInfoModel } from "../../../models/message"
import { PopupItem } from "../../../models/popup"
import { UserInfo, UserInfomModel } from "../../../models/user"

@Preview
@Component
struct Message {

  @StorageProp(vchat_ConnectUserKey)
  currentuser:UserInfomModel = new UserInfomModel({} as UserInfo)

  //  当前发送的内容
  @Require @Prop currentMessage:MessageInfoModel = new MessageInfoModel({} as MessageInfo)

  @State isOwnMessage:boolean = this.currentuser.user_id == this.currentMessage?.sendUser?.user_id

  // 删除消息回调，由父组件传入
  deleteMessage: (message: MessageInfoModel) => void = (message: MessageInfoModel) => {}

  @State
  showPopup: boolean = false // 是否显示浮层
  @State
  popupList: PopupItem[] = [{
    title: '听筒播放',
    icon: $r("app.media.ic_public_ears")
  },
    {
      title: '收藏',
      icon: $r("app.media.ic_public_cube")
    }, {
      title: '转文字',
      icon: $r("app.media.ic_public_trans_text")
    }, {
      title: '删除',
      icon: $r("app.media.ic_public_cancel"),

    }, {
      title: '多选',
      icon: $r("app.media.ic_public_multi_select")
    }, {
      title: '引用',
      icon: $r("app.media.ic_public_link")
    }, {
      title: '提醒',
      icon: $r("app.media.ic_public_warin")
    }]

  // 用来显示弹层的内容
  @Builder
  getContent() {
    GridRow ({ columns: 5 }) {
      ForEach(this.popupList, (item: PopupItem) => {
        GridCol() {
          Column({ space: 6 }) {
            Image(item.icon)
              .fillColor(Color.White)
              .width(18)
              .height(18)
            Text(item.title)
              .fontColor(Color.White)
              .fontSize(14)
          }
          .height(60)
        }
        .onClick(() => {
          // 点击删除：关闭浮层并调用删除回调
          if (item.title === '删除') {
            this.showPopup = false
            this.deleteMessage(this.currentMessage)
            return
          }
          item.itemClick && item.itemClick() // 如果点击事件存在 就触发
        })
      })
    }
    .width(300)
    .padding({
      top: 15,
      left: 10
    })
  }

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
          .bindPopup(this.showPopup, {
            builder:  this.getContent,
            popupColor: Color.Black,
            backgroundBlurStyle: BlurStyle.NONE,
            onStateChange: (event) => {
              // 当手指点了其他位置 关闭状态
              this.showPopup = event.isVisible
            }
          })
      }
      .gesture(
        LongPressGesture()
          .onAction(() => {
            this.showPopup = true // 显示父层
          }))
      .justifyContent(this.isOwnMessage ? FlexAlign.End : FlexAlign.Start)
      .layoutWeight(6)
    }
    .padding({left:20,right:20})
    .direction(this.isOwnMessage ? Direction.Rtl : Direction.Ltr)
  }
}

export default Message
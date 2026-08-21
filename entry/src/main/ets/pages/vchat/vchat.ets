import { MessageInfoModel } from "../../models/message"
import { Vchatstore } from "../../utills/chat_store"
import { router } from "@kit.ArkUI"

@Component
struct vchat {
  @State list:MessageInfoModel[] = []

  aboutToAppear(): void {
    this.getAllrecord()
  }

  async getAllrecord(){
    this.list = await Vchatstore.getAlllastmessage()
  }
  //将时间转换为具体时间
  tranTime(timer:number){
   const sendTime =  new Date(timer)
    if(sendTime.getDate() == new Date().getDate())
    {//今天 显示时分
       return sendTime.getHours().toString().padStart(2,"0") + ":" + sendTime.getMinutes().toString().padStart(2,"0")
    }
    else {
      return (sendTime.getMonth() + 1).toString().padStart(2,"0") + "月" + sendTime.getDate().toString().padStart(2,"0") + "日"

    }
  }

  build() {
    // Text(JSON.stringify(this.list))
    Column(){
      Row(){
        Text('微信')
      }
      .width('100%')
      .height(50)
      .justifyContent(FlexAlign.Center)
      List({space:10}){
        ForEach(this.list,(item:MessageInfoModel) => {
          ListItem(){
            Row(){
              Image(item.connectUser.user_picture)
                .width(50)
                .aspectRatio(1)
                .borderRadius(4)
                .margin({left:10,right:10})
              Column()
              {
                Text(item.connectUser.user_name)
                  .fontSize(17)
                  .margin({bottom:9})
                  .alignSelf(ItemAlign.Start)

                Text(item.messageContent)
                  .fontSize(13)
                  .fontColor('#A3A3A3')
                  .alignSelf(ItemAlign.Start)

              }
              .layoutWeight(1)

                Text(this.tranTime(item.sendTimer))
                  .fontSize(12)
                  .fontColor('#A3A3A3')
                  .margin({right:10})
                  .alignSelf(ItemAlign.Start)
              // .padding(5)
            }
            .width('100%')
            .padding(10)
          }
          .width('100%')
          .onClick(() => {
            router.pushUrl({
              url:'pages/chtedetail/chatDetail',
              params:item.connectUser
            })
          })

        })
      }
      .divider({
        strokeWidth:2,
        color:'#A3A3A3'
      })
    }
    .backgroundColor('#EBEDEF')
    .width('100%')
    .height('100%')
  }
}

export default vchat


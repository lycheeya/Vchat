import { MessageInfoModel } from "../../models/message"
import { Vchatstore } from "../../utills/chat_store"
import { router } from "@kit.ArkUI"
import emitter from "@ohos.events.emitter"
import { Record_Update_Eventname } from "../../constant"

@Component
struct vchat {
  @State list:MessageInfoModel[] = []

  @Builder getcontextend(item:MessageInfoModel)
  {
    Row(){
      Text('删除')
        .fontSize(20)
        .width(100)
        .textAlign(TextAlign.Center)

    }
    .onClick(() => {
      //删除内存
      if(item.connectUser.user_id)
      {
        //【修复】原代码 findIndex 回调参数也叫 item，导致与自己比较恒为 true，永远删的是第一条
        //现在比较的是列表中每条的 user_id 与左滑那条(item)的 user_id
        let index = this.list.findIndex(listItem => listItem.connectUser.user_id == item.connectUser.user_id)
        if(index > -1){
          this.list.splice(index,1)

        }
        Vchatstore.deletevchatMessage(item.connectUser.user_id)


      }
      //删除缓存

    })
    .height('100%')
    .backgroundColor(Color.Red)

  }


  aboutToAppear(): void {
    this.getAllrecord()
    emitter.on(Record_Update_Eventname, async () => {
      this.list = await Vchatstore.getAlllastmessage()

    })
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
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

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
          .swipeAction({
            end:{
              builder:this.getcontextend(item)
            }
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


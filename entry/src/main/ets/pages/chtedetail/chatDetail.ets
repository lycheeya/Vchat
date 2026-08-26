import { router } from '@kit.ArkUI'
import { vchat_ConnectUserKey } from '../../constant'
import { MessageInfo, MessageInfoModel } from '../../models/message'
import { UserInfo, UserInfomModel } from '../../models/user'
import { Vchatstore } from '../../utills/chat_store'
import { getRequestMessage } from '../../utills/Request'
import Bottominput from './components/bottominput'
import Message from './components/Message'

@Entry
@Component
struct chatDetail {

  @State messageList:MessageInfoModel[] = []
  @State talkUserInputing:boolean = false
  @StorageProp(vchat_ConnectUserKey)
  currentuser:UserInfomModel = new UserInfomModel({} as UserInfo)
  @Provide talker:UserInfomModel = new UserInfomModel({} as UserInfo)
  scroller:Scroller = new Scroller()
  aboutToAppear(): void {
    //获取和我对话的用户资料
    this.getTalker()
  }
  getallRecord(){
    this.messageList = Vchatstore.getVchatMessage(this.talker.user_id)
    //【错误】scrollEdge 在 messageList 赋值后同步调用，但 ArkUI 渲染是异步的，List 尚未完成新数据布局，导致滚动到旧布局底部而非最新消息
    //this.scroller.scrollEdge(Edge.Bottom)
  }
  getTalker(){
    this.talker = router.getParams() as UserInfomModel
    this.getallRecord()
  }
//发送文本消息
  sendTextMessage(content:string){
    let mess = new MessageInfoModel({
      messageContent:content,
      sendUser:this.currentuser,//我发的消息
      connectUser:this.talker//我和对方的聊天记录
    } as MessageInfo)

    this.messageList.push(mess)//追加消息
    Vchatstore.addone_vchatMessage(this.talker.user_id,mess)
    //【错误】push 后 List 尚未重新渲染，同步调用 scrollEdge 无法滚动到新增消息位置
    //this.scroller.scrollEdge(Edge.Bottom)
    setTimeout(() => { this.scroller.scrollEdge(Edge.Bottom) }, 0)
    //发送消息到废弃物得到响应内容
    this.getResponseMessage(content)
  }
  //发送y语音消息
  sendAudioMessage(mess:MessageInfoModel){
    this.messageList.push(mess)//追加消息
    Vchatstore.addone_vchatMessage(this.talker.user_id,mess)
    //【错误】push 后 List 尚未重新渲染，同步调用 scrollEdge 无法滚动到新增消息位置
    //this.scroller.scrollEdge(Edge.Bottom)
    setTimeout(() => { this.scroller.scrollEdge(Edge.Bottom) }, 0)
  }

  //获取相应的消息
  async getResponseMessage(content:string){
    await new Promise<void>((resolve:Function) => {
      setTimeout(() => {
        resolve()
      },Math.random() > 2000 ? 2000 : Math.random())
    })
    this.talkUserInputing = true
    const result =  await getRequestMessage(content)
    //新建一个消息
    const mess = new MessageInfoModel({
      messageContent:result?.content,
      sendUser:this.talker,//回复的消息
      connectUser:this.talker//我和对方的聊天记录
    } as MessageInfo)
    await new Promise<void>((resolve:Function) => {
      setTimeout(() => {
        resolve()
      },Math.random() > 2000? 2000 : Math.random())
    })
    this.talkUserInputing = false
    this.messageList.push(mess)//追加消息
    Vchatstore.addone_vchatMessage(this.talker.user_id,mess)

    //【错误】push 后 List 尚未重新渲染，同步调用 scrollEdge 无法滚动到新增消息位置
    //this.scroller.scrollEdge(Edge.Bottom)
    setTimeout(() => { this.scroller.scrollEdge(Edge.Bottom) }, 0)


  }

  //【新增】删除单条聊天记录
  async deleteMessage(message: MessageInfoModel) {
    await Vchatstore.deleteone_vchatMessage(this.talker.user_id, message.id)
    this.messageList = this.messageList.filter(item => item.id !== message.id)
  }

  //【新增】清空与当前用户的所有聊天记录
  async clearAllMessage() {
    await Vchatstore.deletevchatMessage(this.talker.user_id)
    this.messageList = []
  }

  build() {

    Column() {
      Stack({alignContent:Alignment.Start}){

        Text(this.talkUserInputing ? '对方正在输入' : this.talker.user_name)
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

      List({space:20,scroller:this.scroller}){
        ForEach(this.messageList,(item:MessageInfoModel) => {
          //【修改】原 ListItem 无删除交互，新增长按弹出操作菜单支持删除单条/清空全部聊天记录
          //ListItem()
          //{
          //  Message({currentMessage:item})
          //}
          ListItem()
          {
            Message({
              currentMessage:item,
              deleteMessage:(message:MessageInfoModel) => {
                this.deleteMessage(message)
              }
            })
          }
          .gesture(
            LongPressGesture()
              .onAction(() => {
                ActionSheet.show({
                  title: '消息操作',
                  message: '请选择操作',
                  sheets: [
                    {
                      title: '删除该条消息',
                      action: () => { this.deleteMessage(item) }
                    },
                    {
                      title: '清空聊天记录',
                      action: () => { this.clearAllMessage() }
                    }
                  ]

                })
              })
          )
        })
      }
      .onAppear(() => {
        this.scroller.scrollEdge(Edge.Bottom)
      })
      .scrollBar(BarState.Off)
      .padding({top:4,bottom:2})
      .backgroundColor('#EBEDEF')
      .layoutWeight(1)

      //底部内容
      Bottominput({
        sendTextMessage:(content:string) => {
          this.sendTextMessage(content)
        },
        sendAudioMessage:(mess:MessageInfoModel) =>{
          this.sendAudioMessage(mess)
        }
      })


    }
    .height('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    // .width('100%')

  }
}
import { display, promptAction } from "@kit.ArkUI"
import { abilityAccessCtrl, bundleManager } from "@kit.AbilityKit"
import common from "@ohos.app.ability.common"
import { audio } from "@kit.AudioKit"
import { AudioCapturer } from "../../../utills/audioRecord"
import { FileCommon } from "../../../utills/fileOperate"
import { ChatAudioFile } from "../../../utills/chatAudioFile"
import { MessageInfo, MessageInfoModel, MessageTypeEnum } from "../../../models/message"
import { UserInfo, UserInfomModel } from "../../../models/user"
import { vchat_ConnectUserKey } from "../../../constant"

@Preview
@Component
struct Bottominput {

  @State jp_content:string = ''//键盘输入内容
  @State showMode:boolean = false  // false为文字输入，true为功能面板
  @State voiceMode:boolean = false  // 语音模式
  @State Showvoice:boolean = false
  @Consume('talker') talker: UserInfomModel = new UserInfomModel({} as UserInfo)
  // currentuser 已经在下面声明过了，无需重复声明
  //【修复】原 @Consume('currentuser') 无匹配的 @Provide('currentuser')——父组件 chatDetail 是用
  //@StorageProp(vchat_ConnectUserKey) 提供 currentuser 的，@Consume 找不到提供者，导致这里一直是空对象，
  //进而语音消息 sendUser 为空：isOwnMessage 判定失败(消息显示在对面)、sendUser.user_picture 为空(无头像)
  //@Consume('currentuser') currentuser: UserInfomModel = new UserInfomModel({} as UserInfo)
  @StorageProp(vchat_ConnectUserKey) currentuser: UserInfomModel = new UserInfomModel({} as UserInfo)
  screenwidth:number = 0
  screenheight:number = 0
  @State Choosestate: 'delete' | 'text' | 'none' = 'none'

  sendTextMessage: (content: string) => void = (content: string) => {}//发送文本
  sendAudioMessage:(mess:MessageInfoModel) => void = () => {} //发送音频消息
  xcolor:ResourceStr = '#95ec69'
  temppath:string = ''

  duration:number = 0//音频的秒数
  timer:number = -1//记录定时器的标志


  getwidthd() {
    return this.Choosestate == 'delete' ? 120 : 80;
  }
  getwidtht() {
    return this.Choosestate == 'text' ? 120 : 80;
  }

  // ===== 新增：语音面板选中状态指示框（实心圆角矩形）=====
  // 圆角矩形尺寸（vp），中间(none)和右侧(文)比左侧(X/删除)更大
  getFrameW(): number {
    if (this.Choosestate == 'delete') {
      return 104
    }
    return 130
  }
  getFrameH(): number {
    if (this.Choosestate == 'delete') {
      return 52
    }
    return 64
  }
  getFrameR(): number {
    return 12
  }

  // 计算指示圆角矩形的纵向位置：相对面板(Column)顶部
  // 原理：Row 底部距面板底部 170vp，按钮在 Row 中垂直居中，
  // 圆角矩形位于按钮顶部上方 (矩形高 + 50vp 间距) 处
  getFrameY(buttonWidth: number): number {
    const rowH = Math.max(this.getwidthd(), this.getwidtht())
    const rowBottom = this.screenheight - 170   // Row 底部距离
    const buttonTop = rowBottom - rowH + (rowH - buttonWidth) / 2
    return buttonTop - (this.getFrameH() + 50)
  }

  aboutToAppear():void{
    // 获取屏幕宽高（vp），用于语音上滑取消 / 左删右文手势判断
    const d = display.getDefaultDisplaySync()
    this.screenwidth = px2vp(d.width)
    this.screenheight = px2vp(d.height)
    AudioCapturer.init()//初始化采集器
  }
  aboutToDisappear(): void {
    //新增：录音中不释放采集器，否则正在阻塞的 read() 会抛 system error；
    //下次录音时 start() 里的状态检查会自动释放重建
    if (!AudioCapturer.recording) {
      AudioCapturer.release()
    }
  }


    checkpermission(){
    const result = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)

    const manager = abilityAccessCtrl.createAtManager()//创建一个nabager
    const statu = manager.checkAccessTokenSync( result.appInfo.accessTokenId,"ohos.permission.MICROPHONE")
    if(statu == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED){
      // promptAction.showToast({message:"ok"})
      this.Showvoice = true
      this.begainrecord()//新增：权限通过后开始录音（创建 wav 文件 + 启动采集器）

    } else{
      // promptAction.showToast({message:"no ok"})
      //此时无法录音
      const context = getContext() as common.UIAbilityContext
      context.startAbility({
        bundleName:"com.huawei.hmos.settings",
        abilityName:"com.huawei.hmos.settings.MainAbility",
        uri:'application_info_entry',
        parameters:{
          pushParams:result.name
        }
      })

    }
  }

  //开始收集声音
  begainrecord(){
    // 使用聊天专用的音频文件存储，基于聊天双方ID生成唯一标识
    const chatId = this.currentuser.user_id < this.talker.user_id 
      ? `${this.currentuser.user_id}_${this.talker.user_id}`
      : `${this.talker.user_id}_${this.currentuser.user_id}`;
    
    this.temppath = ChatAudioFile.createChatAudioFile(chatId);//创建聊天专用音频文件路径
    AudioCapturer.start(this.temppath)//此时开始录音
    this.begainRtime()
  }


  @Builder
  getContent()
  {

    Column()
    {
      Stack({alignContent:Alignment.Bottom}){
        Image($r('app.media.ic_public_output'))
          .width('100%')
          .height(120)
          .fillColor(this.Choosestate == 'none' ? '#95ec69'  : '#9B9B9B'  )
        Image($r('app.media.ic_public_recorder'))
          .width(30)
          .height(30)
          .margin({bottom:50})
          Row(){
            Text('X')
              .width(this.getwidthd())
              .aspectRatio(1)
              .borderRadius(this.getwidthd()/2)
              .backgroundColor(this.Choosestate == 'delete' ? '#c94f4f' : '#9B9B9B')
              .textAlign(TextAlign.Center)
              .fontColor(Color.White)
              .rotate({angle:-15})

            Text('文')
              .width(this.getwidtht())
              .aspectRatio(1)
              .borderRadius(this.getwidtht()/2)
              .backgroundColor(this.Choosestate == 'text' ? '#95ec69'  : '#9B9B9B'   )
              .textAlign(TextAlign.Center)
              .fontColor(Color.White)
              .rotate({angle:15})

          }
          // .height('100%')
          .padding({left:40,right:40})
          .justifyContent(FlexAlign.SpaceBetween)
          .width('100%')
          .margin({bottom:170})


      }
      .height('100%')
      // ===== 新增：语音面板选中状态指示圆角矩形（实心，绝对定位在对应按钮上方）=====
      // 选中 X(删除) 时，在 X 上方显示实心红色圆角矩形
      if (this.Choosestate == 'delete') {
        Column()
          .width(this.getFrameW())
          .height(this.getFrameH())
          .borderRadius(this.getFrameR())
          .backgroundColor('#c94f4f')
          .position({
            x: 40 + this.getwidthd() / 2 - this.getFrameW() / 2,
            y: this.getFrameY(this.getwidthd())
          })
      }
      // 选中 文(文字) 时，在 文 上方显示实心绿色圆角矩形
      if (this.Choosestate == 'text') {
        Column()
          .width(this.getFrameW())
          .height(this.getFrameH())
          .borderRadius(this.getFrameR())
          .backgroundColor('#95ec69')
          .position({
            x: this.screenwidth - 40 - this.getwidtht() / 2 - this.getFrameW() / 2,
            y: this.getFrameY(this.getwidtht())
          })
      }
      // 选中 none(未滑动/中间区域) 时，在中间上方显示实心绿色圆角矩形
      if (this.Choosestate == 'none') {
        Column()
          .width(this.getFrameW())
          .height(this.getFrameH())
          .borderRadius(this.getFrameR())
          .backgroundColor('#95ec69')
          .position({
            x: this.screenwidth / 2 - this.getFrameW() / 2,
            y: this.getFrameY(80)
          })
      }



    }
    .height('100%')
    .backgroundColor("rgba(0,0,0,0.3)")
  }

  releaseFinger(){
    this.Showvoice = false
    AudioCapturer.stop()
    if(this.Choosestate == 'delete'){
      ChatAudioFile.deleteChatAudioFile(this.temppath) // 使用新的音频文件管理功能删除文件
    }
    else if(this.Choosestate == 'text'){

    }
    else if (this.Choosestate == 'none') {
      if(this.duration < 1){
        promptAction.showToast({message:'录制时间太短'})
        ChatAudioFile.deleteChatAudioFile(this.temppath) // 使用新的音频文件管理功能删除文件
        this.endtime()
        this.duration = 0
        this.temppath = ""
        return
      }
      else this.sendaudio()
    }
    this.endtime()

  }

  begainRtime(){
    this.timer  = setInterval(() => {
      this.duration++
    },1000)
  }

  endtime(){
    clearInterval(this.timer)
    // this.duration = 0
  }

  sendaudio(){
    let mess = new MessageInfoModel({
      sourceDuration:this.duration,
      messageContent:`[语音】${this.duration}'`,
      messageType:MessageTypeEnum.AUDIO,
      connectUser:this.talker,
      sendUser:this.currentuser,
      sourceFilePath:this.temppath
    } as MessageInfo)
    promptAction.showToast({message:'time is ' + this.duration})
    this.sendAudioMessage(mess)
    this.duration = 0
    this.temppath = ""
  }

  build() {
    Column(){
      Divider()
        .color('#ccc')
        .strokeWidth(1)

      // 底部输入框
      Row(){
        // 左侧按钮：用于切换文字/语音输入模式
        Image(this.voiceMode? $r('app.media.input_mode') : $r('app.media.speaker_wave_3')) // 使用图标表示语音和键盘模式
          .width(30)
          .height(30)
          .margin({left:10,right:10})
          .onClick(() => {
            // 切换语音/文字输入模式
            this.voiceMode = !this.voiceMode;
            // 如果启用了语音模式，关闭功能面板
            if (this.voiceMode) {
              this.showMode = false;
            }
          })

        if(this.Choosestate != 'delete'){
          if (!this.voiceMode) {
            // 文字输入状态
            Row(){
              TextInput({ text:this.jp_content})
                .width('100%')
                .borderRadius(6)
                .onChange((value:string)=>{
                  this.jp_content = value
                })
                .onSubmit(()=>{
                  if(this.jp_content != ''){
                    this.sendTextMessage(this.jp_content)//触发父组件方法
                    this.jp_content = ''//清空输入内容
                  }
                })
            }
            .layoutWeight(1)
            .backgroundColor(Color.White)
          } else {
            // 语音输入状态
            Row(){
              Text('按住 说话')
                .width('100%')
                .height(35)
                .fontSize(16)
                .padding({left:10,right:10})
                .borderRadius(6)
                .backgroundColor('#f0f0f0')
                .textAlign(TextAlign.Center)
            }
            .layoutWeight(1)   // 限制语音输入区域占中间弹性空间，避免遮挡右侧加号按钮
            .gesture(
              GestureGroup(GestureMode.Parallel,
                LongPressGesture()
                  .onAction(() => {
                    this.checkpermission()
                    // this.Showvoice = true
                  })
                  .onActionEnd(() => {
                    this.releaseFinger()

                    // this.Showvoice = false
                  }),
                PanGesture()
                  .onActionUpdate((event) => {
                   if(event.fingerList[0].globalY < this.screenheight * 6 / 7)
                   {
                     if(event.fingerList[0].globalX > this.screenwidth / 2)
                     {
                        this.Choosestate = 'text'  // 往右滑为"文"
                       this.xcolor = '#95ec69'

                     }
                     else {
                       this.xcolor = '#ea3322'
                       this.Choosestate = 'delete'
                     }  // 往左滑为"删"
                   }
                   else {
                     this.xcolor = '#95ec69'
                     this.Choosestate = 'none'
                   }
                  })
                  .onActionEnd((event) => {
                    this.Choosestate = 'none'
                  })
              )
            )
          }
        }



        Image($r('app.media.plus_square'))
          .margin({left:10,right:10})
          .width(25)
          .aspectRatio(1)
          .onClick(()=>{
            this.showMode = !this.showMode
          })

      }
      .height(60)
      .width('100%')
      .backgroundColor(Color.White)
      .padding({left:10,right:10})
      .justifyContent(FlexAlign.SpaceBetween)

      // 展示更多功能
      if(this.showMode){
        Column()
        {
          Row(){
            Column(){
              Image($r('app.media.picture'))
                .width(30)
                .height(30)
              Text('相册')
                .fontSize(12)
                .fontColor('#333')
            }
            .alignItems(HorizontalAlign.Center)

            Column(){
              Image($r('app.media.camera'))
                .width(30)
                .height(30)
              Text('拍摄')
                .fontSize(12)
                .fontColor('#333')
            }
            .alignItems(HorizontalAlign.Center)

            Column(){
              Image($r('app.media.videochat'))
                .width(30)
                .height(30)
              Text('视频通话')
                .fontSize(12)
                .fontColor('#333')
            }
            .alignItems(HorizontalAlign.Center)

            Column(){
              Image($r('app.media.location'))
                .width(30)
                .height(30)
              Text('位置')
                .fontSize(12)
                .fontColor('#333')
            }
            .alignItems(HorizontalAlign.Center)

          }
          .width('100%')
          .height(90)
          // .padding({top:10})
          .justifyContent(FlexAlign.SpaceEvenly)
          .backgroundColor('#F4F6F6')

          Row(){
            Column(){
              Image($r('app.media.redbag'))
                .width(30)
                .height(30)
              Text('红包')
                .fontSize(12)
                .fontColor('#333')
            }
            .alignItems(HorizontalAlign.Center)

            Column(){
              Image($r('app.media.gift'))
                .width(30)
                .height(30)
              Text('礼物')
                .fontSize(12)
                .fontColor('#333')
            }
            .onClick(()=>{
              this.showMode = false
            })
            .alignItems(HorizontalAlign.Center)

            Column(){
              Image($r('app.media.file'))
                .width(30)
                .height(30)
              Text('文件')
                .fontSize(12)
                .fontColor('#333')
            }
            .alignItems(HorizontalAlign.Center)

            Column(){
              Image($r('app.media.songinput'))
                .width(30)
                .height(30)
              Text('语音输入')
                .fontSize(12)
                .fontColor('#333')
            }
            .alignItems(HorizontalAlign.Center)

          }
          .width('100%')
          .height(90)
          // .padding({bottom:10})
          .justifyContent(FlexAlign.SpaceEvenly)
          .backgroundColor('#F4F6F6')
        }
      }

    }
    .bindContentCover($$this.Showvoice,this.getContent(),{
      modalTransition:ModalTransition.NONE})
  }
}

export default Bottominput
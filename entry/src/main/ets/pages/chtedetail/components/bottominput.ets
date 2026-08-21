import { display, promptAction } from "@kit.ArkUI"

@Preview
@Component
struct Bottominput {

  @State jp_content:string = ''//键盘输入内容
  @State showMode:boolean = false  // false为文字输入，true为功能面板
  @State voiceMode:boolean = false  // 语音模式
  @State Showvoice:boolean = false
  screenwidth:number = 0
  screenheight:number = 0
  @State Choosestate: 'delete' | 'text' | 'none' = 'none'

  sendTextMessage: (content: string) => void = (content: string) => {}

  getwidthd() {
    return this.Choosestate == 'delete' ? 120 : 80;
  }
  getwidtht() {
    return this.Choosestate == 'text' ? 120 : 80;
  }

  aboutToAppear():void{
    // 获取屏幕宽高（vp），用于语音上滑取消 / 左删右文手势判断
    const d = display.getDefaultDisplaySync()
    this.screenwidth = px2vp(d.width)
    this.screenheight = px2vp(d.height)
  }

  @Builder
  getContent()
  {

    Column()
    {
      Row(){
        Text('删')
          .width(this.getwidthd())
          .aspectRatio(1)
          .borderRadius(this.getwidthd()/2)
          .backgroundColor('#3fd969')
          .textAlign(TextAlign.Center)
          .fontColor(Color.White)
          .rotate({angle:-15})

        Text('文')
          .width(this.getwidtht())
          .aspectRatio(1)
          .borderRadius(this.getwidtht()/2)
          .backgroundColor('#3fd969')
          .textAlign(TextAlign.Center)
          .fontColor(Color.White)
          .rotate({angle:15})

      }
      .height(1000)
      .padding({left:40,right:40})
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')
    }
    .height('100%')
    .backgroundColor("rgba(0,0,0,0.3)")
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
                    this.Showvoice = true
                  })
                  .onActionEnd(() => {
                    this.Showvoice = false
                  }),
                PanGesture()
                  .onActionUpdate((event) => {
                   if(event.fingerList[0].globalY < this.screenheight * 6 / 7)
                   {
                     if(event.fingerList[0].globalX > this.screenwidth / 2)
                     {
                        this.Choosestate = 'text'  // 往右滑为"文"
                     }
                     else this.Choosestate = 'delete'  // 往左滑为"删"
                   }
                   else this.Choosestate = 'none'
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
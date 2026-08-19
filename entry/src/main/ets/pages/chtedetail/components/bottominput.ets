import { display, promptAction } from "@kit.ArkUI"

@Preview
@Component
struct Bottominput {

  @State showMode:boolean = false
  @State Showvoice:boolean = false
  screenwidth:number = 0
  screenheight:number = 0
  @State Choosestate: 'delete' | 'text' | 'none' = 'none'

  getwidthd() {
    return this.Choosestate == 'delete' ? 120 : 80;
  }
  getwidtht() {
    return this.Choosestate == 'text' ? 120 : 80;
  }
  aboutToAppear(): void {
    display.getAllDisplays()
      .then(result => {
        // 【修复】screenwidth/screenheight 应取屏幕尺寸（display 接口返回 px，需 px2vp 转 vp）。
        // 原代码仅在 onAreaChange 中赋值，而 onAreaChange 返回的是所挂载组件自身的尺寸（非屏幕），
        // 导致 screenheight 被写成组件高度(约48vp)而非屏幕高度(817vp)，手势判定阈值失真。
        this.screenwidth = px2vp(result[0].width)
        this.screenheight = px2vp(result[0].height)
        // promptAction.showToast({
        //   message: px2vp(result[0].height).toString(),
        //   duration:3000
        // })
      })
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
        // .animation({duration:2000})

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
    Row({space:10}) {
        Image(this.showMode ? $r('app.media.input_mode') : $r('app.media.speaker_wave_3'))
          .width(25)
          .aspectRatio(1)
          .onClick(() => {
            this.showMode =! this.showMode
            // console.log('mode',this.showMode)
          })
      if(this.showMode)
      {
        Row()
        {
          Column()
          {
            Button('按住 说话')
              .fontSize(17)
              .type(ButtonType.Normal)
              .fontColor(Color.Black)
              .backgroundColor(Color.White)
              .width('100%')
              .borderRadius(10)
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
                      if(event.fingerList[0].globalY < this.screenheight * 0.8 )
                      {
                        if(event.fingerList[0].globalX > this.screenwidth / 2)
                        {
                          this.Choosestate = 'text'
                        }
                        else this.Choosestate = 'delete'
                      }
                      else this.Choosestate = 'none'
                    })
                    .onActionEnd((event) => {
                      this.Choosestate = 'none'
                    })
                )

              )
              // .padding(15)

          }
          .justifyContent(FlexAlign.End)
          // .height('100%')



        }
        .layoutWeight(1)
        .backgroundColor(Color.White)
        // .height('100%')
        // 【错误】onAreaChange 返回的是所挂载组件（内层语音 Row，位于高60vp的底部输入栏内）自身的尺寸，
        // 而非屏幕尺寸。原代码将组件宽高赋给 screenwidth/screenheight，覆盖了正确值，
        // 导致手势中 'globalY > screenheight*0.8' / 'globalX > screenwidth/2' 判定阈值失真（48≠817）。
        // 屏幕宽高应通过 display 接口获取（修复见 aboutToAppear），故本块废弃：
        // .onAreaChange((oldarea,newarea) => {
        //   this.screenwidth = newarea.width as number
        //   this.screenheight = newarea.height as number
        //   // 历史记录：此处原仅有 '}' 闭合箭头函数体，缺少 onAreaChange( 的右括号 ')'，此前已补上
        //   // }
        // })
        .bindContentCover($$this.Showvoice,this.getContent(),{
          modalTransition:ModalTransition.DEFAULT})
      }
      else
        {
          TextInput()
            .layoutWeight(1)
            .borderRadius(6)
            .backgroundColor(Color.White)

        }
      Image($r('app.media.plus'))
        .width(25)
        .aspectRatio(1)
        // 【错误】原代码此处有一个游离的多余 '}'（位于 else 块闭合之后、外层 Row 闭合之前），
        // 使括号层数多出一层，导致后续 .height/.width 等链式修饰被误解析为类成员/函数声明。
        // 原错误代码：      }
        // }
    }
    .height(60)
    .width('100%')
    .backgroundColor('#F4F6F6')
    .padding({left:10,right:10})
    .justifyContent(FlexAlign.SpaceBetween)

  }
  // 【错误】原代码在此处结束（仅一个 '}' 闭合 build()），缺少 struct Bottominput 的闭合 '}'，
  // 导致 'export default Bottominput' 被当作 struct 内部语句，报 '}' expected / Unexpected keyword。
  // 原错误代码：}
  // 修复：补写 struct 的闭合 '}' 如下
}
export default Bottominput

import { vchat_ConnectUserKey } from "../../../constant"
import { MessageInfo, MessageInfoModel, MessageTypeEnum } from "../../../models/message"
import { PopupItem } from "../../../models/popup"
import { UserInfo, UserInfomModel } from "../../../models/user"
// 【2026-08-27 新增导入】用于语音消息的播放控制
import { AudioRender } from "../../../utills/audioRender"
import { promptAction } from "@kit.ArkUI"

@Preview
@Component
struct Message {

  @State audiostate:AnimationStatus = AnimationStatus.Initial
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
  isPlaying: boolean = false // 当前音频是否正在播放
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

  @Builder
  getTextContent(){
    Text(this.currentMessage.messageContent ?? '')
      .backgroundColor(this.isOwnMessage ? '#9eea6a' : Color.White)
      .padding(10)
      .margin({left:10,right:10})
      .borderRadius(5)
      .height(40)
  }
  /**
   * 播放/停止语音消息
   */
  async playAudio(): Promise<void> {
    if (!this.currentMessage.sourceFilePath) {
      return;
    }
    if (this.isPlaying) {
      // 正在播放则停止
      await AudioRender.stop();
      this.isPlaying = false;
      this.audiostate = AnimationStatus.Stopped;
    } else {
      // 停止其他正在播放的音频
      await AudioRender.stop();
      await AudioRender.init();
      try {
        await AudioRender.start(this.currentMessage.sourceFilePath);
        // 检查是否真的开始播放了
        if (AudioRender.renderIng) {
          this.audiostate = AnimationStatus.Running;
          promptAction.showToast({message:'1'});
          this.isPlaying = true;
          // 轮询检查播放状态，播放结束后重置 UI
          AudioRender.checkPlayEnd().then((ended: boolean) => {
            if (ended) {
              this.isPlaying = false;
              this.audiostate = AnimationStatus.Initial;
              promptAction.showToast({message:'2'})
            }
          });
        } else {
          // 如果没有开始播放，也要重置状态
          this.audiostate = AnimationStatus.Initial;
          console.info('音频未能开始播放');
        }
      } catch (error) {
        console.error(`音频播放失败: ${error.message}`);
        this.audiostate = AnimationStatus.Initial;
        this.isPlaying = false;
      }
    }
  }

  /**
   * 【旧代码已废弃 — 2026-08-27】
   * 原 getAudioContent 仅有 UI 展示，无可交互播放功能，播放状态无视觉反馈。
   * 新代码：添加 onClick 触发播放、isPlaying 状态驱动背景/文字变色。
   */
  // @Builder
  // getAudioContent(){
  //   // 【修改原因】：让语音发送的聊天框的大小与文字聊天框的大小一致，并且宽度随语音时长变化
  //   Row(){
  //     Text(`${this.currentMessage.sourceDuration}'`)
  //     Image($r('app.media.ic_public_recorder'))
  //       .width(20)
  //       .height(20)
  //       .rotate({
  //         angle:this.isOwnMessage ? 180 : 0
  //       })
  //   }
  //   .justifyContent(this.isOwnMessage ? FlexAlign.End : FlexAlign.Start)
  //   .backgroundColor(this.isOwnMessage ? '#9eea6a' : Color.White)
  //   .padding(10)
  //   .margin({left:10,right:10})
  //   .borderRadius(5)
  //   .width(Math.min(Math.max(60 + this.currentMessage.sourceDuration * 6, 60), 200))
  //   .height(40)
  //   .direction(this.isOwnMessage ? Direction.Rtl : Direction.Ltr)
  // }

  @Builder
  getAudioContent(){
    Row(){
      // Image($r('app.media.ic_public_recorder'))
      //   .width(20)
      //   .height(20)
      //   .rotate({
      //     angle:this.isOwnMessage ? 180 : 0
      //   })
      // 【废弃/错误】原代码 .state() 调用了两次（第2次覆盖第1次），且 .duration(1000) 被注释掉
      // 导致动画周期为 0ms，瞬间播完，肉眼无帧切换效果
      // ImageAnimator().images([
      //     { src: $r('app.media.ic_public_voice3') },
      //     { src: $r('app.media.ic_public_voice1') },
      //     { src: $r('app.media.ic_public_voice2') },
      //     { src: $r('app.media.ic_public_voice3') },
      //   ])
      //   .state(this.isPlaying ? AnimationStatus.Running : AnimationStatus.Initial)
      //   // .duration(1000)
      //   .state(this.audiostate)
      //   .iterations(-1)
      //   .width(20)
      //   .height(20)
      ImageAnimator().images([
          { src: $r('app.media.ic_public_voice3') },
          { src: $r('app.media.ic_public_voice1') },
          { src: $r('app.media.ic_public_voice2') },
          { src: $r('app.media.ic_public_voice3') },
        ])
        .state(this.audiostate)
        // .duration(1000)
        .iterations(-1)
        .width(20)
        .height(20)
        .rotate({
          angle:this.isOwnMessage ? 180 : 0
        })
      Text(`${this.currentMessage.sourceDuration}"`)
        .fontSize(14)
        .fontColor(this.isPlaying ? '#007aff' : Color.Black)
    }
    .justifyContent(this.isOwnMessage ? FlexAlign.End : FlexAlign.Start)
    .backgroundColor(this.isPlaying ? '#d0ebff' : (this.isOwnMessage ? '#9eea6a' : Color.White))
    .padding(10)
    .margin({left:10,right:10})
    .borderRadius(5)
    .width(Math.min(Math.max(60 + this.currentMessage.sourceDuration * 6, 60), 200))
    .height(40)
    .direction(!this.isOwnMessage ? Direction.Rtl : Direction.Ltr)
    .onClick(() => {
      this.playAudio()
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
        Column(){
          if(this.currentMessage.messageType == MessageTypeEnum.TEXT)
            this.getTextContent()
          else if(this.currentMessage.messageType == MessageTypeEnum.AUDIO)
            this.getAudioContent()
        }
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

  aboutToDisappear(): void {
    if (this.isPlaying) {
      AudioRender.stop();
    }
  }
}

export default Message
@Preview
@Component
struct Bottominput {

  build() {
    Row({space:10}) {
        Image($r('app.media.speaker_wave_3'))
          .width(25)
          .aspectRatio(1)
      TextInput()
        .layoutWeight(1)
        .borderRadius(6)
        .backgroundColor(Color.White)
      Image($r('app.media.plus'))
        .width(25)
        .aspectRatio(1)

    }
    .height(60)
    .width('100%')
    .backgroundColor('#F4F6F6')
    .padding({left:10,right:10})
    .justifyContent(FlexAlign.SpaceBetween)
  }
}

export default Bottominput

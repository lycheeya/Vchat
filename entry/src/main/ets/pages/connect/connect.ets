import { promptAction, router } from "@kit.ArkUI"
import { UserInfomModel } from "../../models/user"
import { Vchatstore } from "../../utills/chat_store"

@Entry
@Preview
@Component
export struct Connect {
  // 修复：原 @Link message 无默认值导致调用时必须传参，
  // 但组件内未使用该字段，改为 @Prop 并提供默认值，可无参使用
  @Prop message: string = ''
  @State userlist:UserInfomModel[] = []
  @State filterList:UserInfomModel[] = []
  // 图片预览控制：是否显示大图预览层 + 当前预览的图片地址
  @State previewVisible: boolean = false
  @State previewUrl: ResourceStr = ''
  @State @Watch("updateList") searchName:string = ''


  aboutToAppear(): void {
    // promptAction.showToast({message:'jiaza'})
    // 修复：原来 getUserlist() 从未被调用，userlist 一直是空数组，导致显示不出数据
    this.getUserlist()
  }

  getUserlist()
  {
    this.userlist = Vchatstore.getvchatconnect()
    this.updateList()
  }
  updateList()
  {
    if(this.searchName)
    {
      this.filterList = this.userlist.filter(item => item.user_name.includes(this.searchName))
      return
    }
    else
      this.filterList = this.userlist
  }

  build() {
    Stack() {
      Column() {
        Row(){
          Search({
            placeholder:'搜索',
            value:$$this.searchName
          })
            .borderRadius(4)
            .height(30)
            .backgroundColor(Color.White)

        }
        .width('100%')
        Blank()
        // Text(JSON.stringify(this.userlist))
          // .fontSize(50)
          // .fontWeight(FontWeight.Bold)
          List(){
          ForEach(this.filterList,(item:UserInfomModel)=>{
              ListItem(){
                Row({space:10}){
                  Image(item.user_picture)
                    .width(47)
                    .height(47)
                    // .borderRadius(22)
                    // 点击头像打开全屏大图预览
                    .onClick(() => {
                      this.previewUrl = item.user_picture
                      this.previewVisible = true
                    })
                  Column(){
                    Text(item.user_name)
                      .fontSize(19)
                      .fontColor('#333')
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                }
                .width('100%')
                .padding({left:12,right:12,top:8,bottom:8})
                .stateStyles({
                  normal:{
                    .backgroundColor(Color.White)
                  },
                  pressed:{
                    .backgroundColor('#EBEDEF')
                  }
                })
                .onClick(() => {
                  router.pushUrl({
                    url:'pages/chtedetail/chatDetail',
                    params:item
                  })
                })

              }

            })
          }
          .scrollBar(BarState.Off)
          .divider({strokeWidth:2,
          color:'#EBEDEF'})
          .backgroundColor('#EBEDEF')
          .width('100%')
          .layoutWeight(1)

      }
      .width('100%')
      .height('100%')

      // 全屏图片预览层（点击任意处关闭）
      if (this.previewVisible) {
        Stack() {
          Image(this.previewUrl)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Contain)
            .onClick(() => {
              this.previewVisible = false
            })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#EBEDEF')
        .zIndex(10)
      }
    }
    .width('100%')
    .height('100%')
  }
}

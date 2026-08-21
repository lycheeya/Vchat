import { tabbarclass } from '../models/tab'
import { Vchatstore } from '../utills/chat_store'
// 修复：./connect 解析到 pages/connect 目录（无 index.ets 兜底），
// 应指向实际组件文件 ./connect/connect，且组件已改名为 Connect（大驼峰）
import { Connect } from './connect/connect'
import vchat from './vchat/vchat'

@Entry
@Component
struct Index {

  @State currentIndex: number = 0  //激活索引
  @State tablist: tabbarclass[] = [
    {
      icon: $r('app.media.tab_weixin'),
      name: 'vchat',
      title: '薇信',
      selecticon: $r('app.media.tab_weixin_selected')
    },
    {
      icon: $r('app.media.tab_contacts'),
      name: 'connect',
      title: '联系人',
      selecticon: $r('app.media.tab_contacts_selected')
    },
    {
      icon: $r('app.media.tab_discover'),
      name: 'find',
      title: '发现',
      selecticon: $r('app.media.tab_discover_selected')
    },
    {
      icon: $r('app.media.tab_me'),
      name: 'mine',
      title: '我的',
      selecticon: $r('app.media.tab_me_selected')
    }
  ]



  @Builder
  tabBar(index: number) {
    Column() {
      Image(this.currentIndex === index ? this.tablist[index].selecticon : this.tablist[index].icon)
        .width(26)
        .height(26)
        .objectFit(ImageFit.Contain)
      Text(this.tablist[index].title)
        .fontSize(12)
        .fontColor(this.currentIndex === index ? '#07C160' : '#9E9E9E')
        .margin({ top: 2 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Tabs() {
      ForEach(this.tablist, (item: tabbarclass, index: number) => {
        TabContent() {
          if(item.name == 'connect')
          {
            Connect()
          }
          else if(item.name == 'vchat')
          {
            vchat()
          }
          else {
            Text(item.title)

          }
        }
        .tabBar(this.tabBar(index))
      }, (item: tabbarclass) => item.title)
    }
    .barPosition(BarPosition.End)
    .onChange((index: number) => {
      this.currentIndex = index
    })

  }
}

import router from '@ohos.router';
import { PAGE_ROOM_LIST } from '../common/Constants';

@Entry
@Component
struct Success {
  build() {
    Column({ space: 50 }) {
      Text('逃脱成功！')
        .fontSize(60)
        .fontColor(Color.Green)
        .fontWeight(FontWeight.Bold)

      Text('下一关已解锁')
        .fontSize(24)
        .fontColor(Color.Yellow)
        .margin({ top: -30 })

      Text('返回选关')
        .fontSize(30)
        .fontColor(Color.White)
        .border({ width: 2, color: Color.White, radius: 10 })
        .padding({ left: 40, right: 40, top: 10, bottom: 10 })
        .onClick(() => {
          // 直接清空路由栈并回到选关页，防止无限返回
          router.clear();
          router.pushUrl({ url: PAGE_ROOM_LIST });
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    .justifyContent(FlexAlign.Center)
  }
}
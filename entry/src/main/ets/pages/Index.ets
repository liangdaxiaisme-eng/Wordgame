import router from '@ohos.router';
import { PAGE_ROOM_LIST } from '../common/Constants';

@Entry
@Component
struct Index {
  // 页面加载前初始化全局状态
  aboutToAppear() {
    AppStorage.setOrCreate('unlockedLevels', 1);
    AppStorage.setOrCreate('myAchievements', []);
  }

  build() {
    Column({ space: 40 }) {
      Text('文字密室')
        .fontSize(60)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)

      Text('进入游戏')
        .fontSize(30)
        .fontColor(Color.White)
        .border({ width: 2, color: Color.White, radius: 10 })
        .padding({ left: 30, right: 30, top: 15, bottom: 15 })
        .onClick(() => {
          router.pushUrl({ url: PAGE_ROOM_LIST });
        });
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    .justifyContent(FlexAlign.Center)
  }
}
import router from '@ohos.router';
import { PAGE_GAME_MAIN } from '../common/Constants';

@Entry
@Component
struct RoomList {
  // 绑定全局解锁进度
  @StorageLink('unlockedLevels') unlockedLevels: number = 1;

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Text('← 返回首页')
        .fontSize(24)
        .fontColor(Color.White)
        .padding(20)
        .onClick(() => {
          router.back();
        })

      Column({ space: 30 }) {
        // 传入对应的图片资源路径
        this.LevelCard('深夜加班', true, $r('app.media.xuanguan'))
        this.LevelCard('回魂夜', this.unlockedLevels >= 2, $r('app.media.xuanguan1'))
        this.LevelCard('精神病院', this.unlockedLevels >= 3, $r('app.media.xuanguan2'))
        this.LevelCard('特大案件', this.unlockedLevels >= 4, $r('app.media.xuanguan3'))
      }
      .width('100%')
      .margin({ top: 80 })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
  }

  // 扩展后的 LevelCard 组件，新增 imgSrc 参数
  @Builder
  LevelCard(title: string, isActive: boolean, imgSrc: Resource) {
    Row() {
      Text(title)
        .fontSize(24)
        .fontColor(isActive ? Color.White : Color.Gray)
        .width(120)

      Stack({ alignContent: Alignment.Center }) {
        // 底层背景图
        Image(imgSrc)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .borderRadius(6)
          // 如果未解锁，图片透明度降低变暗
          .opacity(isActive ? 1 : 0.5)

        // 上层状态遮罩
        if (!isActive) {
          Stack({ alignContent: Alignment.Center }) {
            Text('🔒 未解锁')
              .fontColor(Color.White)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
          }
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.6)') // 加一层黑色半透明遮罩
          .borderRadius(6)
        } else {
          // 解锁状态下的小提示
          Text('点击进入')
            .fontColor(Color.White)
            .fontSize(12)
            .backgroundColor('rgba(0, 0, 0, 0.5)')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(10)
        }
      }
      .width(180)
      .height(80)
      .backgroundColor('#333333')
      .border({ width: 2, color: isActive ? Color.White : '#555555', radius: 8 })
    }
    .width('85%')
    .justifyContent(FlexAlign.SpaceBetween)
    .onClick(() => {
      if (isActive) {
        if (title === '深夜加班') {
          router.pushUrl({ url: PAGE_GAME_MAIN });
        } else if (title === '回魂夜') {
          router.pushUrl({ url: 'pages/Level2' });
        } else if (title === '精神病院') {
          router.pushUrl({ url: 'pages/Level3' });
        } else if (title === '特大案件') {
          router.pushUrl({ url: 'pages/Level4' });
        }
      }
    })
  }
}
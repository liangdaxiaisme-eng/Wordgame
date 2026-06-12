import router from '@ohos.router';
import { PAGE_SUCCESS } from '../common/Constants';

PersistentStorage.persistProp('unlockedLevels', 1);
PersistentStorage.persistProp('myAchievements', []);

interface GameContext {
  getClick: (id: string) => number;
  setClick: (id: string, val: number) => void;
  getFlag: (id: string) => boolean;
  setFlag: (id: string, val: boolean) => void;
  setPrompt: (msg: string) => void;
  recordClue: (clue: string) => void;
  useItem: (item: string) => boolean;
  consumeItem: (item: string) => void;
  grantItem: (item: string, prompt: string) => void;
  focusCamera: (scale: number, x: number, y: number) => void;
  openPasswordUI: () => void;
  triggerAchievement: (name: string) => void;
}

interface GameNodeConfig {
  id: string;
  label: string;
  x: number;
  y: number;
  bgColor?: string;
  parentId?: string;
  isVisible: (ctx: GameContext) => boolean;
  onClick: (ctx: GameContext) => void;
}

// =================================================================
// 剧本数据层：第二关《回魂夜》- 修复坐标发散，优化正交十字紧凑布局
// =================================================================
const Level2Data: GameNodeConfig[] = [
  {
    id: 'corridor', label: '阴森走廊', x: 0, y: 0,
    isVisible: () => true,
    onClick: (ctx) => {
      if (ctx.getClick('corridor') === 0) { ctx.setClick('corridor', 1); ctx.setPrompt('走廊的声控灯在疯狂闪烁，空气很冷。'); }
      else if (ctx.getClick('corridor') === 1) { ctx.setClick('corridor', 2); ctx.focusCamera(0.8, 0, 0); }
    }
  },
  // ================= 向左：工具箱分支 =================
  {
    id: 'toolbox', label: '破旧工具箱', x: -200, y: 0, parentId: 'corridor',
    isVisible: (ctx) => ctx.getClick('corridor') >= 2,
    onClick: (ctx) => {
      if (ctx.getClick('toolbox') === 0) { ctx.setClick('toolbox', 1); ctx.setPrompt('一个满是铁锈的工具箱。'); }
      else if (ctx.getClick('toolbox') === 1) { ctx.setClick('toolbox', 2); ctx.focusCamera(0.7, 150, 0); }
    }
  },
  {
    id: 'crowbar', label: '撬棍', x: -200, y: -100, parentId: 'toolbox', bgColor: '#888822', // 紧凑依附在工具箱上方
    isVisible: (ctx) => ctx.getClick('toolbox') >= 2 && !ctx.getFlag('crowbarPicked'),
    onClick: (ctx) => {
      ctx.grantItem('crowbar', '获得道具：生锈的撬棍。物理学圣剑，懂的都懂。');
      ctx.setFlag('crowbarPicked', true);
    }
  },
  // ================= 向右：保安室分支 =================
  {
    id: 'security', label: '保安室', x: 200, y: 0, parentId: 'corridor',
    isVisible: (ctx) => ctx.getClick('corridor') >= 2,
    onClick: (ctx) => {
      if (!ctx.getFlag('securityOpen')) {
        if (ctx.useItem('crowbar')) {
          ctx.consumeItem('crowbar');
          ctx.setFlag('securityOpen', true);
          ctx.setPrompt('🎵[砰！] 门锁被你用撬棍暴力砸开了。');
          ctx.focusCamera(0.7, -150, 0);
        } else {
          ctx.setPrompt('门被死死锁住了，锁眼被口香糖堵死，需要暴力破拆。');
        }
      } else {
        if (ctx.getClick('security') === 0) { ctx.setClick('security', 1); ctx.setPrompt('保安室里一个人都没有，监控屏幕全是雪花。'); }
        else if (ctx.getClick('security') === 1) { ctx.setClick('security', 2); ctx.focusCamera(0.7, -150, 0); }
      }
    }
  },
  {
    id: 'desk', label: '保安桌', x: 200, y: -100, parentId: 'security', // 紧凑依附在保安室上方
    isVisible: (ctx) => ctx.getClick('security') >= 2,
    onClick: (ctx) => {
      if (ctx.getClick('desk') === 0) { ctx.setClick('desk', 1); ctx.setPrompt('桌上有一本沾满血迹的值班日记。'); }
      else if (ctx.getClick('desk') === 1) {
        ctx.setClick('desk', 2);
        ctx.recordClue('值班日记：千万不要看走廊尽头的镜子。');
      }
    }
  },
  {
    id: 'keycard', label: '电梯卡', x: 200, y: -200, parentId: 'desk', bgColor: '#888822', // 顺着保安桌继续垂直向上
    isVisible: (ctx) => ctx.getClick('desk') >= 2 && !ctx.getFlag('keycardPicked'),
    onClick: (ctx) => {
      ctx.grantItem('keycard', '获得道具：万能电梯门卡。');
      ctx.setFlag('keycardPicked', true);
    }
  },
  // ================= 向上：镜子分支 =================
  {
    id: 'mirror', label: '尽头的镜子', x: 0, y: -140, parentId: 'corridor', bgColor: 'rgba(50, 20, 50, 0.85)', // 紧凑拉回
    isVisible: (ctx) => ctx.getClick('corridor') >= 2,
    onClick: (ctx) => {
      ctx.setPrompt('镜子里反射出你的背后... 有一个没有脸的红衣女人正在看着你！');
      ctx.recordClue('镜子里的女人：她一直跟着我。');
    }
  },
  // ================= 向下：电梯分支 =================
  {
    id: 'elevator', label: '电梯', x: 0, y: 160, parentId: 'corridor',
    isVisible: (ctx) => ctx.getClick('corridor') >= 2,
    onClick: (ctx) => {
      if (!ctx.getFlag('elevatorOpen')) {
        if (ctx.useItem('keycard')) {
          ctx.consumeItem('keycard');
          ctx.setFlag('elevatorOpen', true);
          ctx.setPrompt('🎵[叮] 电梯门缓缓打开，里面亮着惨白的灯光。');
          ctx.focusCamera(0.8, 0, -120);
        } else {
          ctx.setPrompt('电梯按键没反应，面板上提示需要刷卡。');
        }
      } else {
        if (ctx.getClick('elevator') === 0) { ctx.setPrompt('快进去，走廊越来越冷了！'); ctx.setClick('elevator', 1); }
        else if (ctx.getClick('elevator') === 1) { ctx.triggerAchievement('夜半惊魂'); }
      }
    }
  },
  {
    id: 'enter_elevator', label: '进入电梯', x: 0, y: 260, parentId: 'elevator', bgColor: '#228822', // 紧凑依附在电梯下方
    isVisible: (ctx) => ctx.getFlag('elevatorOpen'),
    onClick: (ctx) => {
      ctx.triggerAchievement('夜半惊魂');
    }
  }
];

@Entry
@Component
struct Level2 {
  @StorageLink('unlockedLevels') unlockedLevels: number = 1;
  @StorageLink('myAchievements') myAchievements: string[] = [];

  @State clicks: Map<string, number> = new Map();
  @State flags: Map<string, boolean> = new Map();

  @State topPrompt: string = '';
  @State isIntroDone: boolean = false;

  @State inventory: string[] = [];
  @State activeItem: string = '';
  @State collectedClues: string[] = [];

  @State showPasswordUI: boolean = false;
  @State inputPwd: string = '';
  @State showNotepadUI: boolean = false;
  @State hasNewClue: boolean = false;
  @State showAchievementUI: boolean = false;
  @State newAchievementName: string = '';

  @State mapPanX: number = 0;
  @State mapPanY: number = 0;
  @State mapScale: number = 1;
  private lastMapPanX: number = 0;
  private lastMapPanY: number = 0;
  private lastMapScale: number = 1;

  @State renderTick: number = 0;

  aboutToAppear() {
    this.clicks = new Map();
    this.flags = new Map();
    this.inventory = [];
    this.collectedClues = [];
    this.activeItem = '';
    this.topPrompt = '';
    this.isIntroDone = false;
    this.renderTick = 0;
  }

  private getEngineContext(): GameContext {
    return {
      getClick: (id) => this.clicks.has(id) ? (this.clicks.get(id) as number) : 0,
      setClick: (id, val) => { this.clicks.set(id, val); this.renderTick++; },
      getFlag: (id) => this.flags.has(id) ? (this.flags.get(id) as boolean) : false,
      setFlag: (id, val) => { this.flags.set(id, val); this.renderTick++; },
      setPrompt: (msg) => { this.topPrompt = msg; },
      recordClue: (clue) => {
        if (!this.collectedClues.includes(clue)) {
          this.collectedClues.push(clue);
          this.hasNewClue = true;
          this.topPrompt = '📓 获得新线索，已记录到记事本';
        }
      },
      useItem: (item) => this.activeItem === item,
      consumeItem: (item) => {
        let index = this.inventory.indexOf(item);
        if (index > -1) { this.inventory.splice(index, 1); }
        this.activeItem = '';
      },
      grantItem: (item, prompt) => {
        this.inventory.push(item);
        this.topPrompt = prompt;
      },
      focusCamera: (scale, x, y) => {
        animateTo({ duration: 500, curve: Curve.EaseInOut }, () => {
          this.mapScale = scale; this.mapPanX = x; this.mapPanY = y;
          this.lastMapScale = scale; this.lastMapPanX = x; this.lastMapPanY = y;
        });
      },
      openPasswordUI: () => { this.showPasswordUI = true; },
      triggerAchievement: (name) => {
        if (!this.myAchievements.includes(name)) {
          this.myAchievements.push(name);
          this.newAchievementName = name;
          this.showAchievementUI = true;
          setTimeout(() => {
            this.showAchievementUI = false;
            this.unlockedLevels = Math.max(this.unlockedLevels, 3); // Feloldja a 3. szintet
            router.pushUrl({ url: PAGE_SUCCESS });
          }, 2500);
        } else {
          this.unlockedLevels = Math.max(this.unlockedLevels, 3);
          router.pushUrl({ url: PAGE_SUCCESS });
        }
      }
    };
  }

  getDynamicHint(): string {
    let ctx = this.getEngineContext();
    if (ctx.getClick('corridor') < 2) return '提示：探索一下这条走廊。';
    if (!ctx.getFlag('crowbarPicked')) return '提示：去【破旧工具箱】找找有没有趁手的工具。';
    if (!ctx.getFlag('securityOpen')) return '提示：保安室的门坏了，装备【撬棍】强行破开它。';
    if (!ctx.getFlag('keycardPicked')) return '提示：在保安室的【保安桌】上搜查逃生必需品。';
    if (!ctx.getFlag('elevatorOpen')) return '提示：装备【电梯卡】，去【电梯】刷卡逃生！';
    return '提示：电梯开了，快进去！';
  }

  @Builder DrawOrthogonalConnection(parentX: number, parentY: number, childX: number, childY: number) {
    if (parentX === childX) {
      Rect().width(2).height(Math.abs(parentY - childY))
        .fill(Color.White).offset({ x: parentX, y: (parentY + childY) / 2 }).zIndex(-1)
    } else if (parentY === childY) {
      Rect().width(Math.abs(parentX - childX)).height(2)
        .fill(Color.White).offset({ x: (parentX + childX) / 2, y: parentY }).zIndex(-1)
    } else {
      Rect().width(Math.abs(parentX - childX)).height(2)
        .fill(Color.White).offset({ x: (parentX + childX) / 2, y: parentY }).zIndex(-1)
      Rect().width(2).height(Math.abs(parentY - childY))
        .fill(Color.White).offset({ x: childX, y: (parentY + childY) / 2 }).zIndex(-1)
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Text('').opacity(this.renderTick * 0)

      Row() {
        Text('← 放弃').fontSize(20).fontColor(Color.White).onClick(() => { router.back(); })
        Row({ space: 20 }) {
          Text(this.hasNewClue ? '📓 记事本(新)' : '📓 记事本')
            .fontSize(20).fontColor(this.hasNewClue ? Color.Red : Color.White)
            .animation({ duration: 300 })
            .onClick(() => { this.showNotepadUI = true; this.hasNewClue = false; })
          Text('💡 提示').fontSize(20).fontColor(Color.Yellow)
            .onClick(() => { this.topPrompt = this.getDynamicHint(); })
        }
      }.width('90%').justifyContent(FlexAlign.SpaceBetween).position({ x: '5%', y: 20 }).zIndex(20)

      if (!this.isIntroDone) {
        Stack() {
          Column({ space: 15 }) {
            Text('第 二 关').fontSize(36).fontColor(Color.Red).fontWeight(FontWeight.Bold).margin({ bottom: 20 })
            Text('回 魂 夜').fontSize(28).fontColor(Color.White)
            Text('午夜十二点，大楼停电了。').fontSize(24).fontColor(Color.White)
            Text('你必须要从一楼的走廊逃出去。').fontSize(24).fontColor(Color.White)
            Circle().width(60).height(60).fill(Color.Red).opacity(0.4).margin({ top: 50 }).animation({ duration: 1200, iterations: -1, playMode: PlayMode.Alternate })
          }
        }.width('100%').height('100%').backgroundColor(Color.Black).onClick(() => { this.isIntroDone = true; })
      } else {
        Stack({ alignContent: Alignment.Center }) {
          Image($r('app.media.guan2')).width('100%').height('100%').objectFit(ImageFit.Cover).opacity(0.4).zIndex(0)

          if (this.topPrompt !== '') {
            Text(this.topPrompt).fontSize(20).fontColor('#00FF00').backgroundColor('rgba(0,0,0,0.8)').padding(10).borderRadius(8).position({ x: '10%', y: 70 }).width('80%').textAlign(TextAlign.Center).zIndex(10)
          }

          Stack({ alignContent: Alignment.Center }) {
            ForEach(Level2Data.filter(node => node.isVisible(this.getEngineContext())), (node: GameNodeConfig) => {
              if (node.parentId) {
                ForEach(Level2Data.filter(p => p.id === node.parentId && p.isVisible(this.getEngineContext())), (parent: GameNodeConfig) => {
                  this.DrawOrthogonalConnection(parent.x, parent.y, node.x, node.y)
                })
              }
              Stack({ alignContent: Alignment.Center }) { Text(node.label).fontSize(16).fontColor(Color.White) }
              .width(120).height(50)
              .backgroundColor(node.bgColor || 'rgba(68, 68, 68, 0.85)')
              .border({ width: 1, color: Color.White })
              .offset({ x: node.x, y: node.y })
              .zIndex(1)
              .onClick(() => { node.onClick(this.getEngineContext()) })
            }, (node: GameNodeConfig) => node.id)
          }
          .width('100%').height('100%')
          .translate({ x: this.mapPanX, y: this.mapPanY }).scale({ x: this.mapScale, y: this.mapScale }).zIndex(1)
          .gesture(
            GestureGroup(GestureMode.Parallel,
              PanGesture().onActionUpdate((e) => { this.mapPanX = this.lastMapPanX + e.offsetX; this.mapPanY = this.lastMapPanY + e.offsetY; }).onActionEnd(() => { this.lastMapPanX = this.mapPanX; this.lastMapPanY = this.mapPanY; }),
              PinchGesture().onActionUpdate((e) => { let s = this.lastMapScale * e.scale; this.mapScale = s < 0.4 ? 0.4 : (s > 2.0 ? 2.0 : s); }).onActionEnd(() => { this.lastMapScale = this.mapScale; })
            )
          )
        }.width('100%').height('80%').position({ x: 0, y: 0 }).clip(true)

        Column() {
          Text('背包 (点击装备，再点击目标使用)').fontSize(14).fontColor(Color.Gray).width('100%').textAlign(TextAlign.Start).margin({ bottom: 5 })
          Row({ space: 15 }) {
            if (this.inventory.length === 0) { Text('空').fontColor('#555').fontSize(16).margin({ left: 10 }) }
            ForEach(this.inventory, (item: string) => {
              Stack({ alignContent: Alignment.Center }) {
                Text(item === 'crowbar' ? '🪓 撬棍' : (item === 'keycard' ? '💳 电梯卡' : '❓ 物品')).fontSize(16).fontColor(Color.White)
              }
              .width(80).height(40)
              .backgroundColor(this.activeItem === item ? '#888822' : '#555555')
              .border({ width: 2, color: this.activeItem === item ? Color.Yellow : Color.White, radius: 4 })
              .onClick(() => {
                if (this.activeItem === item) { this.activeItem = ''; this.topPrompt = '取消装备'; }
                else { this.activeItem = item; this.topPrompt = `已装备：${item === 'crowbar' ? '撬棍' : '电梯卡'}，请点击目标使用`; }
              })
            })
          }.width('100%').height(60).backgroundColor('#222222').border({ width: 2, color: '#444' }).padding(10)
        }.width('100%').position({ x: 0, y: '85%' }).zIndex(30)

        if (this.showNotepadUI) {
          Stack({ alignContent: Alignment.Center }) {
            Column({ space: 20 }) {
              Text('📓 线索记事本').fontSize(26).fontColor(Color.White).fontWeight(FontWeight.Bold)
              if (this.collectedClues.length === 0) { Text('当前没有任何线索...').fontSize(18).fontColor(Color.Gray).margin({ top: 40 }) }
              else {
                List({ space: 15 }) {
                  ForEach(this.collectedClues, (clue: string, index: number) => {
                    ListItem() { Text(`${index + 1}. ${clue}`).fontSize(18).fontColor('#EEEEEE').width('100%').padding(15).backgroundColor('rgba(255, 255, 255, 0.1)').borderRadius(8) }
                  })
                }.width('100%').height('60%')
              }
              Button('关闭').width(120).backgroundColor(Color.Gray).margin({ top: 20 }).onClick(() => { this.showNotepadUI = false; })
            }.width('85%').height('70%').padding(30).backgroundColor('rgba(30, 30, 35, 0.95)').border({ width: 2, color: Color.White, radius: 12 })
          }.width('100%').height('100%').backgroundColor('rgba(0,0,0,0.8)').zIndex(100).transition({ type: TransitionType.All, opacity: 0 })
        }

        if (this.showAchievementUI) {
          Column() {
            Text('🏆 获得成就 🏆').fontSize(20).fontColor(Color.Yellow).margin({ bottom: 10 })
            Text(this.newAchievementName).fontSize(30).fontWeight(FontWeight.Bold).fontColor(Color.White)
          }.width('80%').padding(30).backgroundColor('rgba(40, 40, 10, 0.95)').border({ width: 2, color: Color.Yellow, radius: 15 }).position({ x: '10%', y: '30%' }).zIndex(101).transition({ type: TransitionType.Insert, translate: { y: -50 }, opacity: 0 })
        }
      }
    }.width('100%').height('100%').backgroundColor(Color.Black)
  }
}
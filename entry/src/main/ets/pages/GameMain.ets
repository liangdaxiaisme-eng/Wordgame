import router from '@ohos.router';
import { PAGE_SUCCESS } from '../common/Constants';

PersistentStorage.persistProp('unlockedLevels', 1);
PersistentStorage.persistProp('myAchievements', []);

// =================================================================
// 核心架构层：游戏数据抽象接口
// =================================================================
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
  openPasswordUI: (target: string) => void;
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
// 剧本数据层：第一关《深夜加班》- 修复坐标重叠，优化拓扑紧凑感
// =================================================================
const Level1Data: GameNodeConfig[] = [
  {
    id: 'office', label: '办公室', x: 0, y: 0,
    isVisible: () => true,
    onClick: (ctx) => {
      if (ctx.getClick('office') === 0) { ctx.setClick('office', 1); ctx.setPrompt('大家都下班走了'); }
      else if (ctx.getClick('office') === 1) { ctx.setClick('office', 2); ctx.focusCamera(0.8, 0, 0); }
    }
  },
  // ================= 向上：工位区域 =================
  {
    id: 'station', label: '你的工位', x: 0, y: -140, parentId: 'office',
    isVisible: (ctx) => ctx.getClick('office') >= 2,
    onClick: (ctx) => {
      if (ctx.getClick('station') === 0) { ctx.setClick('station', 1); }
      else if (ctx.getClick('station') === 1) { ctx.setClick('station', 2); ctx.focusCamera(0.7, 0, 100); }
    }
  },
  {
    id: 'computer', label: '电脑', x: -140, y: -240, parentId: 'station',
    isVisible: (ctx) => ctx.getClick('station') >= 2,
    onClick: (ctx) => {
      if (ctx.getClick('computer') === 0) { ctx.setPrompt('黑夜里，电脑屏幕的光特别刺眼'); ctx.setClick('computer', 1); }
      else if (ctx.getClick('computer') === 1) { ctx.setClick('computer', 2); ctx.focusCamera(0.65, 100, 150); }
    }
  },
  {
    id: 'clock', label: '时钟', x: 140, y: -240, parentId: 'station',
    isVisible: (ctx) => ctx.getClick('station') >= 2,
    onClick: (ctx) => {
      ctx.setPrompt('时间停在了 02:31。等等，时钟的秒针好像在倒着走？');
      ctx.recordClue('时钟面板：定格在 02:31，倒着走的秒针。');
    }
  },
  {
    id: 'mail1', label: '邮件一', x: -140, y: -340, parentId: 'computer',
    isVisible: (ctx) => ctx.getClick('computer') >= 2,
    onClick: (ctx) => {
      ctx.setPrompt('行政部通知：会议室新密码为【公司门牌号】加上【当前时钟的小时数】。');
      ctx.recordClue('行政邮件：会议室密码 = 【门牌号】+【当前时钟小时数】');
    }
  },
  {
    id: 'mail2', label: '邮件二', x: -280, y: -240, parentId: 'computer',
    isVisible: (ctx) => ctx.getClick('computer') >= 2,
    onClick: (ctx) => {
      ctx.setPrompt('物业催缴单：位于 6812 室的贵公司，请尽快缴纳本季度物业费。');
      ctx.recordClue('物业催款单：公司门牌号是 6812。');
    }
  },
  // ================= 向右：会议室区域 =================
  {
    id: 'meeting', label: '会议室', x: 200, y: 0, parentId: 'office',
    isVisible: (ctx) => ctx.getClick('office') >= 2,
    onClick: (ctx) => {
      if (!ctx.getFlag('meetingUnlocked')) {
        if (ctx.getClick('meeting') === 0) { ctx.setPrompt('需要密码才可以打开'); ctx.setClick('meeting', 1); }
        else if (ctx.getClick('meeting') === 1) { ctx.setClick('meeting', 2); ctx.focusCamera(0.75, -150, 0); }
      } else {
        if (ctx.getClick('meeting') === 2) { ctx.setPrompt('门可以打开了'); ctx.setClick('meeting', 3); }
        else if (ctx.getClick('meeting') === 3) { ctx.setClick('meeting', 4); ctx.focusCamera(0.7, -250, 0); }
      }
    }
  },
  {
    id: 'passwordLock', label: '密码锁 🔒', x: 200, y: -100, parentId: 'meeting', // 紧凑依附在会议室上方
    isVisible: (ctx) => ctx.getClick('meeting') === 2 && !ctx.getFlag('meetingUnlocked'),
    onClick: (ctx) => { ctx.openPasswordUI('meeting'); }
  },
  {
    id: 'printer', label: '打印机', x: 200, y: 100, parentId: 'meeting', bgColor: 'rgba(50, 20, 20, 0.85)', // 紧凑依附在会议室下方
    isVisible: (ctx) => ctx.getClick('meeting') >= 2,
    onClick: (ctx) => {
      let r = Math.random();
      if (r > 0.7) ctx.setPrompt('嗡...打印机突然自己启动了，吐出一张白纸。');
      else if (r > 0.4) ctx.setPrompt('纸上印着密密麻麻的黑底白字：“快跑”。');
      else ctx.setPrompt('电源线根本没插。它是怎么运作的？');
    }
  },
  {
    id: 'table', label: '大圆桌', x: 340, y: 0, parentId: 'meeting',
    isVisible: (ctx) => ctx.getClick('meeting') >= 4,
    onClick: (ctx) => {
      if (ctx.getClick('table') === 0) { ctx.setClick('table', 1); }
      else if (ctx.getClick('table') === 1) { ctx.setClick('table', 2); ctx.setFlag('flashlightFound', true); }
    }
  },
  {
    id: 'flashlight', label: '应急手电', x: 340, y: -100, parentId: 'table', bgColor: '#888822',
    isVisible: (ctx) => ctx.getFlag('flashlightFound') && !ctx.getFlag('flashlightPicked'),
    onClick: (ctx) => {
      ctx.grantItem('flashlight', '获得道具：应急手电，可在背包点击装备使用');
      ctx.setFlag('flashlightPicked', true);
    }
  },
  // ================= 向左：杂物间区域 =================
  {
    id: 'storage', label: '杂物间', x: -200, y: 0, parentId: 'office',
    isVisible: (ctx) => ctx.getClick('office') >= 2,
    onClick: (ctx) => {
      if (ctx.useItem('flashlight')) {
        ctx.consumeItem('flashlight');
        ctx.setFlag('flashlightUsed', true);
        ctx.setPrompt('使用应急手电，视野变亮了');
      } else if (!ctx.getFlag('flashlightUsed')) {
        ctx.setPrompt('里面太黑，什么都看不见，需要照明');
      } else {
        if (ctx.getClick('storage') === 0) { ctx.setPrompt('现在看得清了'); ctx.setClick('storage', 1); }
        else if (ctx.getClick('storage') === 1) { ctx.setClick('storage', 2); ctx.focusCamera(0.7, 150, 0); }
      }
    }
  },
  {
    id: 'cabinet', label: '柜子', x: -340, y: 0, parentId: 'storage',
    isVisible: (ctx) => ctx.getClick('storage') >= 2,
    onClick: (ctx) => {
      if (ctx.getClick('cabinet') === 0) { ctx.setClick('cabinet', 1); }
      else if (ctx.getClick('cabinet') === 1) { ctx.setClick('cabinet', 2); }
    }
  },
  {
    id: 'drawer', label: '抽屉', x: -340, y: -100, parentId: 'cabinet',
    isVisible: (ctx) => ctx.getClick('cabinet') >= 2,
    onClick: (ctx) => {
      if (ctx.getClick('drawer') === 0) { ctx.setClick('drawer', 1); }
      else if (ctx.getClick('drawer') === 1) { ctx.setClick('drawer', 2); ctx.setFlag('keyFound', true); ctx.focusCamera(0.65, 250, 80); }
    }
  },
  {
    id: 'key', label: '备用钥匙', x: -340, y: -200, parentId: 'drawer', bgColor: '#888822',
    isVisible: (ctx) => ctx.getFlag('keyFound') && !ctx.getFlag('keyPicked'),
    onClick: (ctx) => {
      ctx.grantItem('key', '获得道具：大门备用钥匙');
      ctx.setFlag('keyPicked', true);
    }
  },
  // ================= 向下：大门区域 =================
  {
    id: 'door', label: '大门', x: 0, y: 160, parentId: 'office',
    isVisible: (ctx) => ctx.getClick('office') >= 2,
    onClick: (ctx) => {
      if (ctx.getClick('door') === 0) { ctx.setPrompt('同事离开的时候已经把门锁住了'); ctx.setClick('door', 1); }
      else if (ctx.getClick('door') === 1) { ctx.setClick('door', 2); ctx.focusCamera(0.75, 0, -120); }
    }
  },
  {
    id: 'doorLock', label: '锁 🔒', x: 0, y: 260, parentId: 'door',
    isVisible: (ctx) => ctx.getClick('door') >= 2 && !ctx.getFlag('keyUsed'),
    onClick: (ctx) => {
      if (ctx.useItem('key')) {
        ctx.consumeItem('key');
        ctx.setFlag('keyUsed', true);
        ctx.setPrompt('🎵[咔哒] 门锁已打开');
      } else {
        ctx.setPrompt('需要备用钥匙才能打开');
      }
    }
  },
  {
    id: 'exit', label: '出口', x: 0, y: 260, parentId: 'door', bgColor: '#228822', // 成功开锁后覆盖在原锁位置
    isVisible: (ctx) => ctx.getFlag('keyUsed'),
    onClick: (ctx) => {
      if (ctx.getClick('exit') === 0) { ctx.setPrompt('终于下班了，回家'); ctx.setClick('exit', 1); }
      else if (ctx.getClick('exit') === 1) { ctx.triggerAchievement('加班狂魔'); }
    }
  }
];

// =================================================================
// 表现与渲染层：UI 引擎
// =================================================================
@Entry
@Component
struct GameMain {
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
  @State currentPwdTarget: string = '';
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
    this.currentPwdTarget = '';
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
      openPasswordUI: (target) => {
        this.currentPwdTarget = target;
        this.showPasswordUI = true;
      },
      triggerAchievement: (name) => {
        if (!this.myAchievements.includes(name)) {
          this.myAchievements.push(name);
          this.newAchievementName = name;
          this.showAchievementUI = true;
          setTimeout(() => {
            this.showAchievementUI = false;
            this.unlockedLevels = Math.max(this.unlockedLevels, 2);
            router.pushUrl({ url: PAGE_SUCCESS });
          }, 2500);
        } else {
          router.pushUrl({ url: PAGE_SUCCESS });
        }
      }
    };
  }

  getDynamicHint(): string {
    let ctx = this.getEngineContext();
    if (ctx.getClick('office') < 2) return '提示：尝试多点击几次【办公室】，看看能发现什么。';
    if (!ctx.getFlag('meetingUnlocked')) return '提示：去【你的工位】查看【电脑】邮件和【时钟】，按右上角【记事本】寻找密码规律。';
    if (!ctx.getFlag('flashlightPicked')) return '提示：会议室打开了，双指缩小地图去【大圆桌】找照明工具。';
    if (!ctx.getFlag('flashlightUsed')) return '提示：点击选中背包里的【手电】，然后点击【杂物间】照明。';
    if (!ctx.getFlag('keyPicked')) return '提示：在杂物间的【抽屉】里翻一翻，应该有大门的钥匙。';
    if (!ctx.getFlag('keyUsed')) return '提示：点击选中背包里的【备用钥匙】，然后点击大门的【锁】。';
    return '提示：门已开，点击【出口】逃生！';
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
            Text('每天都涉及无休止的加班').fontSize(24).fontColor(Color.White)
            Text('今天困得不行了').fontSize(24).fontColor(Color.White)
            Text('趴着睡了一会').fontSize(24).fontColor(Color.White)
            Text('醒来天已经完全黑了').fontSize(24).fontColor(Color.White)
            Circle().width(60).height(60).fill(Color.Red).opacity(0.4).margin({ top: 50 }).animation({ duration: 1200, iterations: -1, playMode: PlayMode.Alternate })
          }
        }.width('100%').height('100%').backgroundColor(Color.Black).onClick(() => { this.isIntroDone = true; })
      } else {
        Stack({ alignContent: Alignment.Center }) {
          Image($r('app.media.guan1')).width('100%').height('100%').objectFit(ImageFit.Cover).opacity(0.4).zIndex(0)

          if (this.topPrompt !== '') {
            Text(this.topPrompt).fontSize(20).fontColor('#00FF00').backgroundColor('rgba(0,0,0,0.8)').padding(10).borderRadius(8).position({ x: '10%', y: 70 }).width('80%').textAlign(TextAlign.Center).zIndex(10)
          }

          Stack({ alignContent: Alignment.Center }) {
            ForEach(Level1Data.filter(node => node.isVisible(this.getEngineContext())), (node: GameNodeConfig) => {

              if (node.parentId) {
                ForEach(Level1Data.filter(p => p.id === node.parentId && p.isVisible(this.getEngineContext())), (parent: GameNodeConfig) => {
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

        }
        .width('100%').height('80%').position({ x: 0, y: 0 }).clip(true)
        .backgroundColor('rgba(0,0,0,0.01)') // 核心修补：增加透明背景底板，确保空白处也能被手指抓取
        .gesture( // 核心修补：手势监听提升到全局容器层
          GestureGroup(GestureMode.Parallel,
            PanGesture().onActionUpdate((e) => { this.mapPanX = this.lastMapPanX + e.offsetX; this.mapPanY = this.lastMapPanY + e.offsetY; }).onActionEnd(() => { this.lastMapPanX = this.mapPanX; this.lastMapPanY = this.mapPanY; }),
            PinchGesture().onActionUpdate((e) => { let s = this.lastMapScale * e.scale; this.mapScale = s < 0.4 ? 0.4 : (s > 2.0 ? 2.0 : s); }).onActionEnd(() => { this.lastMapScale = this.mapScale; })
          )
        )

        Column() {
          Text('背包 (点击装备，再点击目标使用)').fontSize(14).fontColor(Color.Gray).width('100%').textAlign(TextAlign.Start).margin({ bottom: 5 })
          Row({ space: 15 }) {
            if (this.inventory.length === 0) { Text('空').fontColor('#555').fontSize(16).margin({ left: 10 }) }
            ForEach(this.inventory, (item: string) => {
              Stack({ alignContent: Alignment.Center }) { Text(item === 'flashlight' ? '🔦 手电' : '🔑 钥匙').fontSize(16).fontColor(Color.White) }
              .width(80).height(40)
              .backgroundColor(this.activeItem === item ? '#888822' : '#555555')
              .border({ width: 2, color: this.activeItem === item ? Color.Yellow : Color.White, radius: 4 })
              .onClick(() => {
                if (this.activeItem === item) { this.activeItem = ''; this.topPrompt = '取消装备'; }
                else { this.activeItem = item; this.topPrompt = `已装备：${item === 'flashlight' ? '应急手电' : '备用钥匙'}，请点击目标使用`; }
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

        if (this.showPasswordUI) {
          Stack({ alignContent: Alignment.Center }) {
            Column({ space: 30 }) {
              Text('输入会议室密码').fontSize(30).fontColor(Color.White)
              TextInput({ text: this.inputPwd, placeholder: '4位数字' }).width(200).height(50).fontSize(24).fontColor(Color.White).backgroundColor('#555555').borderRadius(8).type(InputType.Number).onChange((value: string) => { this.inputPwd = value; })
              Row({ space: 20 }) {
                Button('取消').backgroundColor(Color.Gray).onClick(() => { this.showPasswordUI = false; this.inputPwd = ''; })
                Button('确认').backgroundColor(Color.Blue).onClick(() => {
                  if (this.currentPwdTarget === 'meeting' && this.inputPwd === '6814') {
                    this.topPrompt = '🎵[叮] 密码正确，锁已开';
                    this.getEngineContext().setFlag('meetingUnlocked', true);
                    this.showPasswordUI = false;
                  }
                  else { this.topPrompt = '密码错误'; this.inputPwd = ''; }
                })
              }
            }.padding(40).backgroundColor('#333333').border({ width: 2, color: Color.White, radius: 12 })
          }.width('100%').height('100%').backgroundColor('rgba(0,0,0,0.8)').zIndex(99)
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
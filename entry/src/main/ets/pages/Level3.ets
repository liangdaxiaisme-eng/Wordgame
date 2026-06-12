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
  openPasswordUI: (target: string) => void; // 引擎升级：支持指定密码锁目标
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
// 剧本数据层：第四关《特大案件》
// =================================================================
const Level4Data: GameNodeConfig[] = [
  {
    id: 'scene', label: '凶案现场', x: 0, y: 0,
    isVisible: () => true,
    onClick: (ctx) => {
      if (ctx.getClick('scene') === 0) { ctx.setClick('scene', 1); ctx.setPrompt('满地都是散乱的物证标记牌和封锁线。'); }
      else if (ctx.getClick('scene') === 1) { ctx.setClick('scene', 2); ctx.focusCamera(0.8, 0, 0); }
    }
  },
  {
    id: 'body', label: '受害者遗体', x: 0, y: -160, parentId: 'scene', bgColor: 'rgba(80, 20, 20, 0.85)',
    isVisible: (ctx) => ctx.getClick('scene') >= 2,
    onClick: (ctx) => {
      if (ctx.getClick('body') === 0) { ctx.setClick('body', 1); ctx.setPrompt('法医已经做过初步勘验。受害者手里紧紧抓着什么东西。'); }
      else if (ctx.getClick('body') === 1) { ctx.setClick('body', 2); ctx.focusCamera(0.7, 0, 110); }
    }
  },
  {
    id: 'receipt', label: '沾血的收据', x: 0, y: -320, parentId: 'body',
    isVisible: (ctx) => ctx.getClick('body') >= 2,
    onClick: (ctx) => {
      ctx.setPrompt('一张残缺的超市收据，尾号赫然印着：77。');
      ctx.recordClue('残缺收据：尾号 77。');
    }
  },
  {
    id: 'desk', label: '嫌疑人书桌', x: -180, y: 0, parentId: 'scene',
    isVisible: (ctx) => ctx.getClick('scene') >= 2,
    onClick: (ctx) => {
      if (ctx.getClick('desk') === 0) { ctx.setClick('desk', 1); ctx.setPrompt('杂乱的办公桌，台历上用红笔把本月的 24 号重重地圈了起来。'); }
      else if (ctx.getClick('desk') === 1) {
        ctx.setClick('desk', 2);
        ctx.recordClue('日历记录：红圈 24 号。');
        ctx.focusCamera(0.7, 135, 0);
      }
    }
  },
  {
    id: 'uvLight', label: '紫外线手电', x: -340, y: 0, parentId: 'desk', bgColor: '#888822',
    isVisible: (ctx) => ctx.getClick('desk') >= 2 && !ctx.getFlag('uvPicked'),
    onClick: (ctx) => {
      ctx.grantItem('uvLight', '获得道具：刑侦用紫光灯，可让隐藏的血迹和指纹显形。');
      ctx.setFlag('uvPicked', true);
    }
  },
  {
    id: 'drawer', label: '密码抽屉', x: -180, y: -160, parentId: 'desk',
    isVisible: (ctx) => ctx.getClick('desk') >= 2,
    onClick: (ctx) => {
      if (!ctx.getFlag('drawerUnlocked')) {
        ctx.setPrompt('一个带有四位数字密码锁的金属抽屉。');
        ctx.openPasswordUI('drawer');
      } else {
        if (ctx.getClick('drawer') === 0) { ctx.setClick('drawer', 1); ctx.setPrompt('抽屉已经打开，里面放着一把沉甸甸的钥匙。'); }
        else if (ctx.getClick('drawer') === 1) { ctx.setClick('drawer', 2); ctx.focusCamera(0.7, 135, 110); }
      }
    }
  },
  {
    id: 'archiveKey', label: '档案室钥匙', x: -180, y: -320, parentId: 'drawer', bgColor: '#888822',
    isVisible: (ctx) => ctx.getClick('drawer') >= 2 && ctx.getFlag('drawerUnlocked') && !ctx.getFlag('keyPicked'),
    onClick: (ctx) => {
      ctx.grantItem('archiveKey', '获得道具：黄铜打造的档案室钥匙。');
      ctx.setFlag('keyPicked', true);
    }
  },
  {
    id: 'archiveDoor', label: '档案室大门', x: 180, y: 0, parentId: 'scene',
    isVisible: (ctx) => ctx.getClick('scene') >= 2,
    onClick: (ctx) => {
      if (!ctx.getFlag('doorUnlocked')) {
        if (ctx.useItem('archiveKey')) {
          ctx.consumeItem('archiveKey');
          ctx.setFlag('doorUnlocked', true);
          ctx.setPrompt('🎵[咔哒] 挂锁掉落，档案室大门敞开，一股霉味扑鼻而来。');
          ctx.focusCamera(0.7, -135, 0);
        } else {
          ctx.setPrompt('大门紧锁，上面挂着一把老式的黄铜挂锁。');
        }
      } else {
        if (ctx.getClick('archiveDoor') === 0) { ctx.setClick('archiveDoor', 1); ctx.setPrompt('到处都是尘封的卷宗。'); }
        else if (ctx.getClick('archiveDoor') === 1) { ctx.setClick('archiveDoor', 2); ctx.focusCamera(0.7, -250, 0); }
      }
    }
  },
  {
    id: 'safe', label: '隐藏保险箱', x: 340, y: 0, parentId: 'archiveDoor',
    isVisible: (ctx) => ctx.getClick('archiveDoor') >= 2,
    onClick: (ctx) => {
      if (!ctx.getFlag('safeUnlocked')) {
        if (ctx.useItem('uvLight')) {
          ctx.setPrompt('紫光灯照射下，键盘上的 1、8、9 三个数字亮起了刺眼的荧光！组合应该是 1998。');
          ctx.recordClue('紫光灯残留：按键 1、8、9 (疑似 1998)。');
        } else {
          ctx.setPrompt('墙壁暗格里藏着一个电子密码保险箱。按键被擦拭得干干净净。');
          ctx.openPasswordUI('safe');
        }
      } else {
        if (ctx.getClick('safe') === 0) { ctx.setClick('safe', 1); ctx.setPrompt('保险箱已开启，里面有一个关键的数字储存设备。'); }
        else if (ctx.getClick('safe') === 1) { ctx.setClick('safe', 2); ctx.focusCamera(0.7, -350, 0); }
      }
    }
  },
  {
    id: 'usb', label: '加密 U 盘', x: 500, y: 0, parentId: 'safe', bgColor: '#888822',
    isVisible: (ctx) => ctx.getClick('safe') >= 2 && ctx.getFlag('safeUnlocked') && !ctx.getFlag('usbPicked'),
    onClick: (ctx) => {
      ctx.grantItem('usb', '获得道具：凶手遗留的核心物证 U 盘。');
      ctx.setFlag('usbPicked', true);
    }
  },
  {
    id: 'terminal', label: '警用终端', x: 0, y: 160, parentId: 'scene',
    isVisible: (ctx) => ctx.getClick('scene') >= 2,
    onClick: (ctx) => {
      if (ctx.useItem('usb')) {
        ctx.consumeItem('usb');
        ctx.setPrompt('证据正在上传... 匹配成功！嫌疑人已被定位！');
        ctx.triggerAchievement('真相大白');
      } else {
        ctx.setPrompt('高权限的局域网终端，需要插入含有密匙的物理介质才能读取案件报告。');
      }
    }
  }
];

// =================================================================
// UI 渲染引擎
// =================================================================
@Entry
@Component
struct Level4 {
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
  @State currentPwdTarget: string = ''; // 引擎升级：记录当前呼出的密码锁 ID
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
    if (ctx.getClick('scene') < 2) return '提示：勘查一下【凶案现场】。';
    if (!ctx.getFlag('drawerUnlocked')) return '提示：调查【嫌疑人书桌】和【受害者遗体】寻找两段数字密码，去开桌面的【密码抽屉】。';
    if (!ctx.getFlag('doorUnlocked')) return '提示：用刚拿到的钥匙去开【档案室大门】。';
    if (!ctx.getFlag('safeUnlocked')) return '提示：用背包里的【紫光灯】去照一下档案室里的【隐藏保险箱】。';
    if (!ctx.getFlag('usbPicked')) return '提示：保险箱打开了，快拿走核心证据。';
    return '提示：拿到证据了，去下方的【警用终端】上传结案！';
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
            Text('第 四 关').fontSize(36).fontColor(Color.Red).fontWeight(FontWeight.Bold).margin({ bottom: 20 })
            Text('特 大 案 件').fontSize(28).fontColor(Color.White)
            Text('你作为特别调查员，来到了连环杀人案的最后现场。').fontSize(24).fontColor(Color.White)
            Text('找出决定性的证据，将真凶绳之以法！').fontSize(24).fontColor(Color.White)
            Circle().width(60).height(60).fill(Color.Red).opacity(0.4).margin({ top: 50 }).animation({ duration: 1200, iterations: -1, playMode: PlayMode.Alternate })
          }
        }.width('100%').height('100%').backgroundColor(Color.Black).onClick(() => { this.isIntroDone = true; })
      } else {
        Stack({ alignContent: Alignment.Center }) {
          // ================= 背景图应用 =================
          Image($r('app.media.guan4')).width('100%').height('100%').objectFit(ImageFit.Cover).opacity(0.4).zIndex(0)

          if (this.topPrompt !== '') {
            Text(this.topPrompt).fontSize(20).fontColor('#00FF00').backgroundColor('rgba(0,0,0,0.8)').padding(10).borderRadius(8).position({ x: '10%', y: 70 }).width('80%').textAlign(TextAlign.Center).zIndex(10)
          }

          Stack({ alignContent: Alignment.Center }) {
            ForEach(Level4Data.filter(node => node.isVisible(this.getEngineContext())), (node: GameNodeConfig) => {
              if (node.parentId) {
                ForEach(Level4Data.filter(p => p.id === node.parentId && p.isVisible(this.getEngineContext())), (parent: GameNodeConfig) => {
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
        }.width('100%').height('80%').position({ x: 0, y: 0 }).clip(true)
        .gesture(
          GestureGroup(GestureMode.Parallel,
            PanGesture({ distance: 5 }).onActionUpdate((e) => { this.mapPanX = this.lastMapPanX + e.offsetX; this.mapPanY = this.lastMapPanY + e.offsetY; }).onActionEnd(() => { this.lastMapPanX = this.mapPanX; this.lastMapPanY = this.mapPanY; }),
            PinchGesture().onActionUpdate((e) => { let s = this.lastMapScale * e.scale; this.mapScale = s < 0.4 ? 0.4 : (s > 2.0 ? 2.0 : s); }).onActionEnd(() => { this.lastMapScale = this.mapScale; })
          )
        )

        Column() {
          Text('背包 (点击装备，再点击目标使用)').fontSize(14).fontColor(Color.Gray).width('100%').textAlign(TextAlign.Start).margin({ bottom: 5 })
          Row({ space: 15 }) {
            if (this.inventory.length === 0) { Text('空').fontColor('#555').fontSize(16).margin({ left: 10 }) }
            ForEach(this.inventory, (item: string) => {
              Stack({ alignContent: Alignment.Center }) {
                Text(item === 'uvLight' ? '🔦 紫光灯' : (item === 'archiveKey' ? '🔑 钥匙' : (item === 'usb' ? '💾 U盘' : '❓ 物品'))).fontSize(16).fontColor(Color.White)
              }
              .width(80).height(40)
              .backgroundColor(this.activeItem === item ? '#888822' : '#555555')
              .border({ width: 2, color: this.activeItem === item ? Color.Yellow : Color.White, radius: 4 })
              .onClick(() => {
                if (this.activeItem === item) { this.activeItem = ''; this.topPrompt = '取消装备'; }
                else { this.activeItem = item; this.topPrompt = `已装备待使用，请点击目标物体`; }
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

        // ================= 多目标密码锁引擎判定 =================
        if (this.showPasswordUI) {
          Stack({ alignContent: Alignment.Center }) {
            Column({ space: 30 }) {
              Text('输入四位数字密码').fontSize(30).fontColor(Color.White)
              TextInput({ text: this.inputPwd, placeholder: '4位数字' }).width(200).height(50).fontSize(24).fontColor(Color.White).backgroundColor('#555555').borderRadius(8).type(InputType.Number).onChange((value: string) => { this.inputPwd = value; })
              Row({ space: 20 }) {
                Button('取消').backgroundColor(Color.Gray).onClick(() => { this.showPasswordUI = false; this.inputPwd = ''; })
                Button('确认').backgroundColor(Color.Blue).onClick(() => {
                  let ctx = this.getEngineContext();
                  // 针对不同的锁，判定不同的密码
                  if (this.currentPwdTarget === 'drawer' && this.inputPwd === '7724') {
                    this.topPrompt = '🎵[咔哒] 抽屉锁解开了！';
                    ctx.setFlag('drawerUnlocked', true);
                    this.showPasswordUI = false;
                  } else if (this.currentPwdTarget === 'safe' && this.inputPwd === '1998') {
                    this.topPrompt = '🎵[滴滴] 验证成功，沉重的保险箱门弹开了。';
                    ctx.setFlag('safeUnlocked', true);
                    this.showPasswordUI = false;
                  } else {
                    this.topPrompt = '密码错误，锁闪烁着红光';
                  }
                  this.inputPwd = '';
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
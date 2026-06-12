import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';

export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage) {
    // 设置主页面为初始页面
    windowStage.loadContent('pages/Index', (err) => {
      if (err) {
        console.error('加载页面失败：' + JSON.stringify(err));
        return;
      }
    });
  }
}
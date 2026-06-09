import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import hilog from '@ohos.hilog';
import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';
import { AuthStorage } from '../service/AuthStorage';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'EduRag', '%{public}s', 'Ability onCreate');
    AuthStorage.setContext(this.context);
  }

  onDestroy(): void {
    hilog.info(0x0000, 'EduRag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0000, 'EduRag', '%{public}s', 'onWindowStageCreate');
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'EduRag', 'Failed to load content. Cause: %{public}s', JSON.stringify(err));
      }
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(0x0000, 'EduRag', '%{public}s', 'onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(0x0000, 'EduRag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(0x0000, 'EduRag', '%{public}s', 'Ability onBackground');
  }
}

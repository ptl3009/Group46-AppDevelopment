import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { MedicineRepository } from '../data/MedicineRepository';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'familyMedicine', '%{public}s', 'Ability onCreate');
    MedicineRepository.initialize(this.context).catch((error: Error) => {
      hilog.error(DOMAIN, 'familyMedicine', 'RDB initialization failed: %{public}s', error.message);
    });
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'familyMedicine', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'familyMedicine', 'Failed to load content: %{public}s', JSON.stringify(err));
      }
    });
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'familyMedicine', 'Failed to set color mode: %{public}s', JSON.stringify(err));
    }
  }

  onWindowStageDestroy(): void {}
  onForeground(): void {}
  onBackground(): void {}
}


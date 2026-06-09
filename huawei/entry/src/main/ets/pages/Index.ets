import router from '@ohos.router';
import { AuthStorage } from '../service/AuthStorage';

@Entry
@Component
struct IndexPage {
  async aboutToAppear() {
    try {
      await AuthStorage.init();
    } catch (e) {
      console.error('AuthStorage init failed', JSON.stringify(e));
    }
    try {
      if (AuthStorage.isLoggedIn()) {
        router.replaceUrl({ url: 'pages/MainPage' });
      } else {
        router.replaceUrl({ url: 'pages/Login' });
      }
    } catch (e) {
      console.error('Navigation failed', JSON.stringify(e));
    }
  }

  build() {
    Column()
      .width('100%')
      .height('100%')
  }
}

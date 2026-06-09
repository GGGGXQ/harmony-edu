import http from '@ohos.net.http';
import router from '@ohos.router';
import { ApiClient, ResponseData } from '../service/ApiClient';
import { AuthStorage } from '../service/AuthStorage';
import { PixelStyles } from '../common/PixelStyles';
import { IconSettings, IconLogOut, IconChevronRight } from '../common/Icons';

@Component
export struct ProfilePage {
  @State username: string = '';
  @State email: string = '';

  aboutToAppear() { this.loadUserInfo(); }

  async loadUserInfo() {
    try {
      let res: ResponseData = await ApiClient.request(http.RequestMethod.GET, '/users/me');
      if (res.code === 200) {
        let data: Record<string, Object> = res.data as Record<string, Object>;
        this.username = data['username'] as string;
        this.email = data['email'] as string;
        await AuthStorage.saveLogin(null, AuthStorage.getToken(), data['id'] as string, this.username);
      }
    } catch (e) { console.error('loadUserInfo failed', JSON.stringify(e)); }
  }

  async doLogout() {
    let token = AuthStorage.getToken();
    if (token) { await ApiClient.request(http.RequestMethod.POST, '/auth/logout'); }
    await AuthStorage.logout(null);
    router.replaceUrl({ url: 'pages/Login' });
  }

  build() {
    Column() {
        Row() {
          Text('我的')
            .fontSize(22)
          .fontColor(PixelStyles.INK)
          .fontFamily(PixelStyles.FONT_DISPLAY)
          .fontWeight(700)
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 16, bottom: 12 })

      Row()
        .width('100%').height(1)
        .backgroundColor(PixelStyles.BORDER_LIGHT)

      Scroll() {
        Column() {
          // ---- 用户信息 ----
          Column() {
            Column() {
              Text((this.username ? this.username.substring(0, 1).toUpperCase() : '?'))
                .fontSize(32)
                .fontColor('#FFFFFF')
                .fontFamily(PixelStyles.FONT_DISPLAY)
                .fontWeight(700)
            }
            .width(72).height(72)
            .backgroundColor(PixelStyles.ACCENT)
            .borderRadius(PixelStyles.RADIUS_SM)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)

            Text(this.username || '---')
              .fontSize(22)
              .fontColor(PixelStyles.INK)
              .fontFamily(PixelStyles.FONT_DISPLAY)
              .fontWeight(600)
              .margin({ top: 16 })

            Text(this.email || '---')
              .fontSize(14)
              .fontColor(PixelStyles.INK_SECONDARY)
              .fontFamily(PixelStyles.FONT_BODY)
              .margin({ top: 6 })
          }
          .width('100%')
          .padding({ top: 40, bottom: 36 })
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

          // ---- 菜单 ----
          Column() {
            this.menuItem('设置', true, () => { router.pushUrl({ url: 'pages/Settings' }) })
            this.dividerLine()
            this.menuItem('退出登录', false, () => { this.doLogout() }, true)
          }
          .width('100%')
          .backgroundColor(PixelStyles.SURFACE)
          .borderWidth(PixelStyles.BORDER_WIDTH)
          .borderColor(PixelStyles.BORDER)
          .borderStyle(BorderStyle.Solid)
          .borderRadius(PixelStyles.RADIUS_SM)
          .shadow({ radius: 10, color: '#2C2C2C20', offsetX: 3, offsetY: 3 })
          .margin({ left: 16, right: 16, top: 16 })
        }
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(PixelStyles.SCREEN_BG)
  }

  @Builder menuItem(label: string, isSettings: boolean, action: () => void, isDanger: boolean = false) {
    Row() {
      if (isSettings) { IconSettings(24, isDanger ? PixelStyles.DANGER : PixelStyles.INK_SECONDARY) }
      else { IconLogOut(24, isDanger ? PixelStyles.DANGER : PixelStyles.INK_SECONDARY) }

      Text(label)
        .fontSize(15)
        .fontColor(isDanger ? PixelStyles.DANGER : PixelStyles.INK)
        .fontFamily(PixelStyles.FONT_BODY)
        .fontWeight(500)
        .margin({ left: 12 })

      Blank()

      IconChevronRight(18, PixelStyles.INK_MUTED)
    }
    .width('100%')
    .padding({ left: 20, right: 16, top: 16, bottom: 16 })
    .onClick(() => action())
  }

  @Builder dividerLine() {
    Row().width('100%').height(1).backgroundColor(PixelStyles.BORDER_LIGHT).margin({ left: 20, right: 20 })
  }
}

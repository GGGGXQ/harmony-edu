import http from '@ohos.net.http';
import router from '@ohos.router';
import { ApiClient, ResponseData } from '../service/ApiClient';
import { PixelStyles } from '../common/PixelStyles';
import { IconChevronLeft, IconCheckCircle, IconAlertCircle } from '../common/Icons';

@Entry
@Component
struct SettingsPage {
  @State username: string = ''
  @State email: string = ''
  @State oldPassword: string = ''
  @State newPassword: string = ''
  @State profileMsg: string = ''
  @State pwdMsg: string = ''
  @State profileSuccess: boolean = false
  @State pwdSuccess: boolean = false

  aboutToAppear() { this.loadProfile(); }

  async loadProfile() {
    try {
      let res: ResponseData = await ApiClient.request(http.RequestMethod.GET, '/users/me');
      if (res.code === 200) {
        let data: Record<string, Object> = res.data as Record<string, Object>;
        this.username = data['username'] as string;
        this.email = data['email'] as string;
      }
    } catch (e) { console.error('loadProfile failed', JSON.stringify(e)); }
  }

  async saveProfile() {
    this.profileMsg = ''; this.profileSuccess = false;
    try {
      let body: string = JSON.stringify({ username: this.username, email: this.email });
      let res: ResponseData = await ApiClient.request(http.RequestMethod.PUT, '/users/me', body);
      if (res.code === 200) { this.profileSuccess = true; this.profileMsg = '保存成功'; }
      else { this.profileMsg = '保存失败，请检查输入'; }
    } catch (e) { this.profileMsg = '网络错误'; }
  }

  async changePassword() {
    this.pwdMsg = ''; this.pwdSuccess = false;
    if (!this.oldPassword || !this.newPassword) { this.pwdMsg = '请填写完整'; return; }
    try {
      let body: string = JSON.stringify({ oldPassword: this.oldPassword, newPassword: this.newPassword });
      let res: ResponseData = await ApiClient.request(http.RequestMethod.PUT, '/users/me/password', body);
      if (res.code === 200) {
        this.pwdSuccess = true; this.pwdMsg = '密码修改成功';
        this.oldPassword = ''; this.newPassword = '';
      } else { this.pwdMsg = '原密码错误或修改失败'; }
    } catch (e) { this.pwdMsg = '网络错误'; }
  }

  build() {
    Column() {
      Row() {
        Row() {
          IconChevronLeft(24, PixelStyles.INK)
        }
        .width(36).height(36)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .onClick(() => router.back())

        Text('设置')
          .fontSize(18)
          .fontColor(PixelStyles.INK)
          .fontFamily(PixelStyles.FONT_DISPLAY)
          .fontWeight(600)
          .margin({ left: 4 })
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 12, right: 16, top: 10, bottom: 10 })
      .backgroundColor(PixelStyles.SURFACE)
      .borderWidth({ bottom: PixelStyles.BORDER_WIDTH })
      .borderColor({ bottom: PixelStyles.BORDER_LIGHT })
      .borderStyle({ bottom: BorderStyle.Solid })

      Scroll() {
        Column() {
          Column() {
            Text('修改资料')
              .fontSize(16)
              .fontColor(PixelStyles.INK)
              .fontFamily(PixelStyles.FONT_DISPLAY)
              .fontWeight(600)
              .margin({ bottom: 16 })

            this.inputField('用户名', this.username, (v: string) => { this.username = v })
            this.inputField('邮箱', this.email, (v: string) => { this.email = v }, true)

            if (this.profileMsg) {
              this.statusRow(this.profileSuccess, this.profileMsg)
            }

            this.primaryButton('保存', () => { this.saveProfile() }, 16)
          }
          .width('100%')
          .padding(24)
          .backgroundColor(PixelStyles.SURFACE)
          .borderWidth(PixelStyles.BORDER_WIDTH)
          .borderColor(PixelStyles.BORDER)
          .borderStyle(BorderStyle.Solid)
          .borderRadius(PixelStyles.RADIUS_SM)

          Column() {
            Text('修改密码')
              .fontSize(16)
              .fontColor(PixelStyles.INK)
              .fontFamily(PixelStyles.FONT_DISPLAY)
              .fontWeight(600)
              .margin({ bottom: 16 })

            this.inputField('原密码', this.oldPassword, (v: string) => { this.oldPassword = v }, false, true)
            this.inputField('新密码', this.newPassword, (v: string) => { this.newPassword = v }, true, true)

            if (this.pwdMsg) {
              this.statusRow(this.pwdSuccess, this.pwdMsg)
            }

            this.primaryButton('修改密码', () => { this.changePassword() }, 16)
          }
          .width('100%')
          .padding(24)
          .backgroundColor(PixelStyles.SURFACE)
          .borderWidth(PixelStyles.BORDER_WIDTH)
          .borderColor(PixelStyles.BORDER)
          .borderStyle(BorderStyle.Solid)
          .borderRadius(PixelStyles.RADIUS_SM)
          .margin({ top: 16 })
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(PixelStyles.SCREEN_BG)
  }

  @Builder inputField(
    placeholder: string, value: string, onChange: (v: string) => void,
    hasTopMargin: boolean = false, isPassword: boolean = false
  ) {
    TextInput({ placeholder: placeholder, text: value })
      .type(isPassword ? InputType.Password : InputType.Normal)
      .onChange((v: string) => onChange(v))
      .height(PixelStyles.INPUT_HEIGHT)
      .width('100%')
      .backgroundColor(PixelStyles.INPUT_BG)
      .fontColor(PixelStyles.INK)
      .fontFamily(PixelStyles.FONT_BODY)
      .fontSize(15)
      .borderWidth(PixelStyles.BORDER_WIDTH)
      .borderColor(PixelStyles.BORDER)
      .borderStyle(BorderStyle.Solid)
      .borderRadius(PixelStyles.RADIUS_SM)
      .placeholderColor(PixelStyles.INK_MUTED)
      .padding({ left: 16, right: 16 })
      .margin({ top: hasTopMargin ? 12 : 0 })
  }

  @Builder primaryButton(label: string, action: () => void, topMargin: number) {
    Column() {
      Text(label)
        .fontSize(15)
        .fontColor('#FFFFFF')
        .fontFamily(PixelStyles.FONT_LABEL)
        .fontWeight(600)
    }
    .width('100%')
    .height(44)
    .backgroundColor(PixelStyles.ACCENT)
    .borderRadius(PixelStyles.RADIUS_MD)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .margin({ top: topMargin })
    .onClick(() => action())
  }

  @Builder statusRow(success: boolean, msg: string) {
    Row({ space: 6 }) {
      if (success) {
        IconCheckCircle(20, PixelStyles.SUCCESS)
      } else {
        IconAlertCircle(20, PixelStyles.DANGER)
      }
      Text(msg)
        .fontSize(13)
        .fontColor(success ? PixelStyles.SUCCESS : PixelStyles.DANGER)
        .fontFamily(PixelStyles.FONT_BODY)
    }
    .margin({ top: 10 })
  }
}

import http from '@ohos.net.http';
import router from '@ohos.router';
import { ApiClient, ResponseData } from '../service/ApiClient';
import { AuthStorage } from '../service/AuthStorage';
import { PixelStyles } from '../common/PixelStyles';
import { IconAlertCircle } from '../common/Icons';

@Entry
@Component
struct LoginPage {
  @State username: string = '';
  @State password: string = '';
  @State email: string = '';
  @State code: string = '';
  @State isCodeMode: boolean = false;
  @State loading: boolean = false;
  @State errorMsg: string = '';

  build() {
    Column() {
        Scroll() {
          Column() {
            Text('欢迎回来')
            .fontSize(28)
            .fontColor(PixelStyles.INK)
            .fontFamily(PixelStyles.FONT_DISPLAY)
            .fontWeight(700)
            .margin({ top: 72, bottom: 8 })

          Text('登录以继续你的学习')
            .fontSize(15)
            .fontColor(PixelStyles.INK_SECONDARY)
            .fontFamily(PixelStyles.FONT_BODY)
            .margin({ bottom: 40 })

          if (this.errorMsg) {
            Row({ space: 8 }) {
              IconAlertCircle(20, PixelStyles.DANGER)
              Text(this.errorMsg)
                .fontSize(13)
                .fontColor(PixelStyles.DANGER)
                .fontFamily(PixelStyles.FONT_BODY)
                .layoutWeight(1)
            }
            .width('100%')
            .padding({ left: 14, right: 14, top: 12, bottom: 12 })
            .backgroundColor('#FFF5F5')
            .borderWidth(PixelStyles.BORDER_WIDTH)
            .borderColor(PixelStyles.DANGER)
            .borderStyle(BorderStyle.Solid)
            .borderRadius(PixelStyles.RADIUS_SM)
            .margin({ bottom: 16 })
          }

          if (!this.isCodeMode) {
            this.inputField('邮箱', this.username, (v: string) => { this.username = v })
            this.inputField('密码', this.password, (v: string) => { this.password = v }, true, true)
          } else {
            this.inputField('邮箱', this.email, (v: string) => { this.email = v })

            Row() {
              this.inputField('验证码', this.code, (v: string) => { this.code = v }, false, false, true)

              Column() {
                Text('获取验证码')
                  .fontSize(13)
                  .fontColor(PixelStyles.ACCENT)
                  .fontFamily(PixelStyles.FONT_LABEL)
                  .fontWeight(600)
              }
              .height(PixelStyles.INPUT_HEIGHT)
              .padding({ left: 14, right: 14 })
              .backgroundColor(PixelStyles.SURFACE)
              .borderWidth(PixelStyles.BORDER_WIDTH)
              .borderColor(PixelStyles.ACCENT)
              .borderStyle(BorderStyle.Solid)
              .borderRadius(PixelStyles.RADIUS_SM)
              .justifyContent(FlexAlign.Center)
              .margin({ left: 10 })
              .onClick(() => this.sendCode())
            }
            .margin({ bottom: 24 })
          }

          Column() {
            Text(this.isCodeMode ? '验证码登录' : '密码登录')
              .fontSize(15)
              .fontColor('#FFFFFF')
              .fontFamily(PixelStyles.FONT_LABEL)
              .fontWeight(600)
          }
          .width('100%')
          .height(PixelStyles.INPUT_HEIGHT)
          .backgroundColor(PixelStyles.ACCENT)
          .borderRadius(PixelStyles.RADIUS_MD)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .enabled(!this.loading)
          .onClick(() => {
            if (!this.isCodeMode) { this.passwordLogin(); } else { this.codeLogin(); }
          })

          if (this.loading) {
            LoadingProgress().width(24).height(24).color(PixelStyles.ACCENT).margin({ top: 16 })
          }

          Row() {
            Text('切换至')
              .fontSize(14).fontColor(PixelStyles.INK_MUTED).fontFamily(PixelStyles.FONT_BODY).margin({ right: 4 })
            Text(this.isCodeMode ? '密码登录' : '验证码登录')
              .fontSize(14).fontColor(PixelStyles.ACCENT).fontFamily(PixelStyles.FONT_LABEL).fontWeight(600)
          }
          .padding({ top: 20, bottom: 20 })
          .onClick(() => { this.isCodeMode = !this.isCodeMode; this.errorMsg = '' })

          Row() {
            Text('没有账号？ ')
              .fontSize(14).fontColor(PixelStyles.INK_SECONDARY).fontFamily(PixelStyles.FONT_BODY)
            Text('去注册')
              .fontSize(14).fontColor(PixelStyles.ACCENT).fontFamily(PixelStyles.FONT_LABEL).fontWeight(600)
              .onClick(() => router.pushUrl({ url: 'pages/Register' }))
          }
        }
        .width('100%')
        .padding({ left: 32, right: 32 })
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
    }
    .width('100%').height('100%').backgroundColor(PixelStyles.SCREEN_BG)
  }

  @Builder inputField(
    placeholder: string, value: string, onChange: (v: string) => void,
    isLast: boolean = false, isPassword: boolean = false, isInline: boolean = false
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
      .margin({ bottom: isLast ? 24 : 12 })
      .layoutWeight(isInline ? 1 : undefined)
  }

  async passwordLogin() {
    this.errorMsg = ''; this.loading = true;
    let body: string = JSON.stringify({ email: this.username, password: this.password });
    let res: ResponseData = await ApiClient.request(http.RequestMethod.POST, '/auth/login/password', body);
    this.loading = false;
    if (res.code === 200) {
      let data: Record<string, Object> = res.data as Record<string, Object>;
      let username: string = data['username'] as string || '';
      await AuthStorage.saveLogin(null, data['token'] as string, data['userId'] as string, username);
      router.replaceUrl({ url: 'pages/MainPage' });
    } else { this.errorMsg = '登录失败：邮箱或密码错误'; }
  }

  async sendCode() {
    let body: string = JSON.stringify({ email: this.email });
    await ApiClient.request(http.RequestMethod.POST, '/auth/code/send', body);
  }

  async codeLogin() {
    this.errorMsg = ''; this.loading = true;
    let body: string = JSON.stringify({ email: this.email, code: this.code });
    let res: ResponseData = await ApiClient.request(http.RequestMethod.POST, '/auth/login/code', body);
    this.loading = false;
    if (res.code === 200) {
      let data: Record<string, Object> = res.data as Record<string, Object>;
      let username: string = data['username'] as string || '';
      await AuthStorage.saveLogin(null, data['token'] as string, data['userId'] as string, username);
      router.replaceUrl({ url: 'pages/MainPage' });
    } else { this.errorMsg = '登录失败：验证码错误'; }
  }
}

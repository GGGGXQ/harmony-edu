import http from '@ohos.net.http';
import router from '@ohos.router';
import { ApiClient, ResponseData } from '../service/ApiClient';
import { PixelStyles } from '../common/PixelStyles';
import { IconBookOpen } from '../common/Icons';

interface CourseItem {
  id: string;
  name: string;
  description: string;
  createdAt: string;
}

interface SigninDaysResult {
  todaySigned: boolean;
  signinDays: number;
}

@Component
export struct CourseListPage {
  @State courses: CourseItem[] = []
  @State loadError: string = ''
  @State todaySigned: boolean = false
  @State consecutiveDays: number = 0
  @State signinLoading: boolean = false
  @State showOverlay: boolean = false

  aboutToAppear() {
    this.loadCourses();
    this.checkSignin();
  }

  async checkSignin() {
    try {
      let res: ResponseData = await ApiClient.request(http.RequestMethod.GET, '/users/signin/days');
      if (res.code === 200) {
        let d = res.data as SigninDaysResult;
        this.todaySigned = d.todaySigned;
        this.consecutiveDays = d.signinDays;
      }
    } catch (_) {}
  }

  async loadCourses() {
    try {
      let res: ResponseData = await ApiClient.request(http.RequestMethod.GET, '/courses');
      if (res.code === 200) {
        this.courses = res.data as CourseItem[];
      } else {
        this.loadError = res.message || '请求失败';
      }
    } catch (_) {
      this.loadError = '网络错误，请检查连接';
    }
  }

  async handleSignin() {
    if (this.signinLoading || this.todaySigned) return;
    this.signinLoading = true;
    try {
      let res: ResponseData = await ApiClient.request(http.RequestMethod.POST, '/users/signin');
      if (res.code === 200) {
        this.showOverlay = true;
        await new Promise<void>(r => setTimeout(r, 1800));
        let dr: ResponseData = await ApiClient.request(http.RequestMethod.GET, '/users/signin/days');
        if (dr.code === 200) {
          let d = dr.data as SigninDaysResult;
          this.consecutiveDays = d.signinDays;
          this.todaySigned = d.todaySigned;
        }
        this.showOverlay = false;
      } else {
        let dr: ResponseData = await ApiClient.request(http.RequestMethod.GET, '/users/signin/days');
        if (dr.code === 200) {
          let d = dr.data as SigninDaysResult;
          this.consecutiveDays = d.signinDays;
          this.todaySigned = d.todaySigned;
        }
      }
    } catch (_) {}
    this.signinLoading = false;
  }

  build() {
    Stack() {
      Scroll() {
        Column() {
          // ── Check-In Section ──
          Column() {
            Column() {
              if (this.todaySigned) {
                Image($r('app.media.icon_check_circle'))
                  .width(44).height(44)
                  .fillColor(PixelStyles.SUCCESS)
                  .objectFit(ImageFit.Contain)
                Text('连续 ' + String(this.consecutiveDays) + ' 天')
                  .fontSize(22)
                  .fontColor(PixelStyles.ACCENT)
                  .fontFamily(PixelStyles.FONT_DISPLAY)
                  .fontWeight(700)
                  .margin({ top: 6 })
                Text('今日已签到')
                  .fontSize(12)
                  .fontColor(PixelStyles.SUCCESS)
                  .fontFamily(PixelStyles.FONT_LABEL)
                  .margin({ top: 2 })
              } else if (this.signinLoading) {
                LoadingProgress()
                  .width(32).height(32)
                  .color(PixelStyles.ACCENT)
                Text('签到中...')
                  .fontSize(13)
                  .fontColor(PixelStyles.INK_SECONDARY)
                  .fontFamily(PixelStyles.FONT_BODY)
                  .margin({ top: 8 })
              } else {
                Text('签')
                  .fontSize(42)
                  .fontColor(PixelStyles.ACCENT)
                  .fontFamily(PixelStyles.FONT_DISPLAY)
                  .fontWeight(800)
                Text('点击签到')
                  .fontSize(13)
                  .fontColor(PixelStyles.INK_SECONDARY)
                  .fontFamily(PixelStyles.FONT_BODY)
                  .margin({ top: 6 })
              }
            }
            .width(130).aspectRatio(1.0)
            .backgroundColor(PixelStyles.SURFACE)
            .borderWidth(PixelStyles.BORDER_WIDTH)
            .borderColor(PixelStyles.ACCENT)
            .borderStyle(BorderStyle.Solid)
            .borderRadius(PixelStyles.RADIUS_MD)
            .shadow({ radius: 10, color: '#C8685A25', offsetX: 3, offsetY: 3 })
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .onClick(() => this.handleSignin())

            Text(this.todaySigned && this.consecutiveDays > 0
              ? '已坚持 ' + String(this.consecutiveDays) + ' 天连续学习'
              : '每日签到，记录学习轨迹')
              .fontSize(14)
              .fontColor(PixelStyles.INK_MUTED)
              .fontFamily(PixelStyles.FONT_BODY)
              .margin({ top: 10 })
          }
          .width('100%')
          .padding({ top: 60, bottom: 56 })
          .alignItems(HorizontalAlign.Center)

          this.ornamentalDivider()

          // ── Course Section ──
          Column() {
            if (this.courses.length === 0) {
              Column() {
                IconBookOpen(56, this.loadError ? PixelStyles.DANGER : PixelStyles.INK_MUTED)
                Text(this.loadError ? '加载失败' : '暂无课程')
                  .fontSize(18)
                  .fontColor(PixelStyles.INK)
                  .fontFamily(PixelStyles.FONT_DISPLAY)
                  .fontWeight(600)
                  .margin({ top: 20, bottom: 8 })
                Text(this.loadError || '等待管理员添加课程内容')
                  .fontSize(15)
                  .fontColor(this.loadError ? PixelStyles.DANGER : PixelStyles.INK_SECONDARY)
                  .fontFamily(PixelStyles.FONT_BODY)
              }
              .width('100%')
              .padding({ top: 80, bottom: 80 })
              .alignItems(HorizontalAlign.Center)
              .justifyContent(FlexAlign.Center)
            } else {
              ForEach(this.courses, (course: CourseItem) => {
                Column() {
                  Column() {
                    Column() {
                      Row() {
                        Column()
                          .width(3).height(40)
                          .backgroundColor(PixelStyles.ACCENT)
                          .borderRadius(PixelStyles.RADIUS_FULL)
                          .margin({ right: 14 })

                        Column({ space: 4 }) {
                          Text(course.name)
                            .fontSize(17)
                            .fontColor(PixelStyles.INK)
                            .fontFamily(PixelStyles.FONT_DISPLAY)
                            .fontWeight(600)
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                          Text(course.description)
                            .fontSize(14)
                            .fontColor(PixelStyles.INK_SECONDARY)
                            .fontFamily(PixelStyles.FONT_BODY)
                            .lineHeight(20)
                            .maxLines(2)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                        }
                        .layoutWeight(1)
                        .alignItems(HorizontalAlign.Start)

                        Image($r('app.media.icon_chevron_right'))
                          .width(18).height(18)
                          .fillColor(PixelStyles.ACCENT)
                          .objectFit(ImageFit.Contain)
                          .margin({ left: 12 })
                      }
                      .width('100%')
                      .padding(18)
                    }
                    .width('100%')
                    .backgroundColor(PixelStyles.SURFACE)
                    .borderWidth(2)
                    .borderColor(PixelStyles.INK)
                    .borderStyle(BorderStyle.Solid)
                    .borderRadius(PixelStyles.RADIUS_MD)
                  }
                  .width('100%')
                  .backgroundColor(PixelStyles.ACCENT)
                  .borderRadius(PixelStyles.RADIUS_MD)
                  .padding({ bottom: 4, right: 8 })
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 6, bottom: 6 })
                .onClick(() => {
                  router.pushUrl({
                    url: 'pages/QaChat',
                    params: {
                      'courseId': String(course.id),
                      'courseName': course.name
                    } as Record<string, string>
                  })
                })
              }, (item: CourseItem) => String(item.id))
            }
          }
          .width('100%')
          .padding({ top: 40, bottom: 24 })

          Row().height(40).width('100%')
        }
        .width('100%')
      }
      .width('100%').height('100%')
      .align(Alignment.Top)
      .backgroundColor(PixelStyles.SCREEN_BG)

      // ── Success Animation Overlay ──
      if (this.showOverlay) {
        Column() {
          Image($r('app.media.icon_check_circle'))
            .width(80).height(80)
            .fillColor(Color.White)
            .objectFit(ImageFit.Contain)
            .transition(
              TransitionEffect.scale({ x: 0, y: 0 })
                .combine(TransitionEffect.opacity(0))
            )

          Text('签到成功')
            .fontSize(24)
            .fontColor(Color.White)
            .fontFamily(PixelStyles.FONT_DISPLAY)
            .fontWeight(600)
            .margin({ top: 20 })
            .transition(TransitionEffect.opacity(0))

          Text('坚持学习，不断进步')
            .fontSize(16)
            .fontColor('#FFFFFFBB')
            .fontFamily(PixelStyles.FONT_BODY)
            .margin({ top: 8 })
            .transition(TransitionEffect.opacity(0))
        }
        .width('100%').height('100%')
        .backgroundColor('#00000070')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .transition(TransitionEffect.opacity(0))
      }
    }
    .width('100%').height('100%')
  }

  @Builder ornamentalDivider() {
    Row({ space: 8 }) {
      Row().width(28).height(1).backgroundColor(PixelStyles.BORDER)
      Row().width(4).height(4).backgroundColor(PixelStyles.ACCENT).borderRadius(2)
      Row().width('100%').height(1).backgroundColor(PixelStyles.BORDER).layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 24, right: 24 })
    .alignItems(VerticalAlign.Center)
  }
}

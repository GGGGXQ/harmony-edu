import http from '@ohos.net.http';
import router from '@ohos.router';
import { ApiClient, ResponseData } from '../service/ApiClient';
import { PixelStyles } from '../common/PixelStyles';
import { IconBookOpen } from '../common/Icons';

interface CourseItemData {
  id: string;
  name: string;
  description: string;
  createdAt: string;
}

@Component
export struct CourseListPage {
  @State courses: CourseItemData[] = []
  @State loadError: string = ''

  aboutToAppear() { this.loadCourses() }

  async loadCourses() {
    try {
      let res: ResponseData = await ApiClient.request(http.RequestMethod.GET, '/courses');
      if (res.code === 200) { this.courses = res.data as CourseItemData[]; }
      else { this.loadError = res.message || '请求失败'; }
    } catch (e) { this.loadError = '网络错误，请检查连接'; }
  }

  build() {
    Column() {
        // ---- 复古书籍目录式标题 ----
        Row() {
          Column() {
            Text('课程中心')
            .fontSize(24)
            .fontColor(PixelStyles.INK)
            .fontFamily(PixelStyles.FONT_DISPLAY)
            .fontWeight(700)
        }
        .layoutWeight(1)

        if (this.courses.length > 0) {
          Column() {
            Row({ space: 6 }) {
              Text(String(this.courses.length))
                .fontSize(18)
                .fontColor(PixelStyles.INK)
                .fontFamily(PixelStyles.FONT_LABEL)
                .fontWeight(700)
              Text('卷')
                .fontSize(12)
                .fontColor(PixelStyles.INK_MUTED)
                .fontFamily(PixelStyles.FONT_LABEL)
            }
          }
          .alignItems(HorizontalAlign.End)
        }
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 18, bottom: 14 })

      // ---- 复古装饰分割线 ----
      this.ornamentalDivider()

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
        .layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.courses, (course: CourseItemData, idx: number) => {
            ListItem() {
              Row() {
                // ---- 书脊式左倾彩色条 + 章节号 ----
                Column() {
                  Column()
                    .width(3)
                    .height(36)
                    .backgroundColor(PixelStyles.ACCENT)
                    .borderRadius(PixelStyles.RADIUS_FULL)

                  Text(padIndex(idx + 1))
                    .fontSize(11)
                    .fontColor(PixelStyles.INK_MUTED)
                    .fontFamily(PixelStyles.FONT_LABEL)
                    .fontWeight(500)
                    .margin({ top: 8 })
                }
                .alignItems(HorizontalAlign.Center)
                .margin({ right: 14 })

                Column() {
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
                    .margin({ top: 6 })
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                Row() {
                  Text('翻阅')
                    .fontSize(12)
                    .fontColor('#FFFFFF')
                    .fontFamily(PixelStyles.FONT_LABEL)
                    .fontWeight(600)
                }
                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                .backgroundColor(PixelStyles.ACCENT)
                .borderRadius(PixelStyles.RADIUS_SM)
                .margin({ left: 16 })
              }
              .width('100%')
              .padding(18)
              .backgroundColor(PixelStyles.SURFACE)
              .borderWidth(PixelStyles.BORDER_WIDTH)
              .borderColor(PixelStyles.BORDER)
              .borderStyle(BorderStyle.Solid)
              .borderRadius(PixelStyles.RADIUS_SM)
              .shadow({ radius: 10, color: '#2C2C2C20', offsetX: 3, offsetY: 3 })
            }
            .padding(3)
            .borderWidth(PixelStyles.BORDER_WIDTH)
            .borderColor(PixelStyles.BORDER_LIGHT)
            .borderStyle(BorderStyle.Solid)
            .borderRadius(PixelStyles.RADIUS_SM + 2)
            .padding({ left: 17, right: 17, top: 2, bottom: 2 })
            .onClick(() => {
              router.pushUrl({
                url: 'pages/QaChat',
                params: { 'courseId': String(course.id), 'courseName': course.name } as Record<string, string>
              })
            })
          }, (item: CourseItemData) => String(item.id))
        }
        .width('100%')
        .margin({ top: 8 })
      }
    }
    .width('100%').height('100%').backgroundColor(PixelStyles.SCREEN_BG)
  }

  @Builder ornamentalDivider() {
    Row({ space: 8 }) {
      Row().width(28).height(1).backgroundColor(PixelStyles.BORDER)
      Row().width(4).height(4).backgroundColor(PixelStyles.ACCENT).borderRadius(2)
      Row().width('100%').height(1).backgroundColor(PixelStyles.BORDER).layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 24, right: 24 })
    .margin({ bottom: 4 })
    .alignItems(VerticalAlign.Center)
  }
}

function padIndex(n: number): string {
  return n < 10 ? '0' + String(n) : String(n);
}

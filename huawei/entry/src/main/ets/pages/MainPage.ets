import router from '@ohos.router';
import { PixelStyles } from '../common/PixelStyles';
import { IconHome, IconClock, IconUser } from '../common/Icons';
import { CourseListPage } from './CourseList';
import { ProfilePage } from './Profile';
import { HistoryTab } from './HistoryTab';

@Entry
@Component
struct MainPage {
  @State currentIndex: number = 0;

  build() {
    Column() {
      Tabs({
        barPosition: BarPosition.End,
        index: this.currentIndex
      }) {
        TabContent() {
          CourseListPage()
        }
        .tabBar(this.tabBarItem(0))

        TabContent() {
          HistoryTab()
        }
        .tabBar(this.tabBarItem(1))

        TabContent() {
          ProfilePage()
        }
        .tabBar(this.tabBarItem(2))
      }
      .vertical(false)
      .scrollable(false)
      .barWidth('100%')
      .barHeight(PixelStyles.TAB_BAR_HEIGHT)
      .onChange((index: number) => {
        this.currentIndex = index;
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PixelStyles.SCREEN_BG)
  }

  @Builder tabBarItem(index: number) {
    Column() {
      Column()
        .width(this.currentIndex === index ? 24 : 0)
        .height(3)
        .backgroundColor(this.currentIndex === index ? PixelStyles.ACCENT : Color.Transparent)
        .borderRadius(PixelStyles.RADIUS_FULL)
        .margin({ bottom: 6 })

      if (index === 0) {
        IconHome(28, this.currentIndex === index ? PixelStyles.ACCENT : PixelStyles.INK_MUTED)
      } else if (index === 1) {
        IconClock(28, this.currentIndex === index ? PixelStyles.ACCENT : PixelStyles.INK_MUTED)
      } else {
        IconUser(28, this.currentIndex === index ? PixelStyles.ACCENT : PixelStyles.INK_MUTED)
      }

      Text(index === 0 ? '首页' : index === 1 ? '历史' : '我的')
        .fontSize(12)
        .fontColor(this.currentIndex === index ? PixelStyles.ACCENT : PixelStyles.INK_MUTED)
        .fontFamily(PixelStyles.FONT_LABEL)
        .fontWeight(this.currentIndex === index ? 600 : 400)
        .margin({ top: 4 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PixelStyles.SURFACE)
    .borderWidth({ top: PixelStyles.BORDER_WIDTH })
    .borderColor({ top: PixelStyles.BORDER_LIGHT })
    .borderStyle({ top: BorderStyle.Solid })
    .justifyContent(FlexAlign.Center)
  }
}

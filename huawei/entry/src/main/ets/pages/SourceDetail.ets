import router from '@ohos.router';
import { PixelStyles } from '../common/PixelStyles';
import { IconChevronLeft } from '../common/Icons';

class SourceItem {
  id: string = '';
  content: string = '';
}

@Entry
@Component
struct SourceDetailPage {
  @State sources: SourceItem[] = []
  private scrollController: Scroller = new Scroller()

  aboutToAppear() {
    let params = router.getParams() as Record<string, string> | null;
    if (params && params['sources']) {
      try {
        let raw: Object[] = JSON.parse(params['sources']) as Object[];
        let list: SourceItem[] = [];
        for (let i = 0; i < raw.length; i++) {
          let r: Record<string, Object> = raw[i] as Record<string, Object>;
          let item: SourceItem = new SourceItem();
          item.id = r['id'] as string;
          item.content = r['content'] as string;
          list.push(item);
        }
        this.sources = list;
      } catch (e) { console.error('SourceDetail parse error', JSON.stringify(e)); }
    }
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

        Text('参考来源')
          .fontSize(17)
          .fontColor(PixelStyles.INK)
          .fontFamily(PixelStyles.FONT_DISPLAY)
          .fontWeight(600)
          .margin({ left: 4 })
          .layoutWeight(1)

        Text(String(this.sources.length))
          .fontSize(13)
          .fontColor(PixelStyles.INK_MUTED)
          .fontFamily(PixelStyles.FONT_LABEL)
          .fontWeight(500)
      }
      .width('100%')
      .padding({ left: 12, right: 16, top: 10, bottom: 10 })
      .backgroundColor(PixelStyles.SURFACE)
      .borderWidth({ bottom: PixelStyles.BORDER_WIDTH })
      .borderColor({ bottom: PixelStyles.BORDER_LIGHT })
      .borderStyle({ bottom: BorderStyle.Solid })

      Scroll(this.scrollController) {
        Column() {
          ForEach(this.sources, (src: SourceItem, idx: number) => {
            Column() {
              Row({ space: 10 }) {
                Column() {
                  Text(String(idx + 1))
                    .fontSize(12)
                    .fontColor('#FFFFFF')
                    .fontFamily(PixelStyles.FONT_LABEL)
                    .fontWeight(700)
                }
                .width(24).height(24)
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .backgroundColor(PixelStyles.ACCENT)
                .borderRadius(PixelStyles.RADIUS_SM)

                Text(truncateTitle(src.content))
                  .fontSize(15)
                  .fontColor(PixelStyles.INK)
                  .fontFamily(PixelStyles.FONT_BODY)
                  .fontWeight(600)
                  .lineHeight(22)
                  .layoutWeight(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
              .margin({ bottom: 10 })

              Row()
                .width('100%')
                .height(1)
                .backgroundColor(PixelStyles.BORDER_LIGHT)
                .margin({ bottom: 12 })

              Text(src.content)
                .fontSize(14)
                .fontColor(PixelStyles.INK_SECONDARY)
                .fontFamily(PixelStyles.FONT_BODY)
                .lineHeight(22)
                .width('100%')
            }
            .width('100%')
            .padding(16)
            .backgroundColor(PixelStyles.SURFACE)
            .borderWidth(PixelStyles.BORDER_WIDTH)
            .borderColor(PixelStyles.BORDER)
            .borderStyle(BorderStyle.Solid)
            .borderRadius(PixelStyles.RADIUS_SM)
            .margin({ bottom: 12 })
          }, (item: SourceItem, idx?: number) => item.id + String(idx))
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor(PixelStyles.SCREEN_BG)
    }
    .width('100%').height('100%').backgroundColor(PixelStyles.SCREEN_BG)
  }
}

function truncateTitle(text: string): string {
  let idx = text.indexOf('\n');
  let firstLine = idx >= 0 ? text.substring(0, idx) : text;
  return firstLine.length > 40 ? firstLine.substring(0, 40) + '...' : firstLine;
}

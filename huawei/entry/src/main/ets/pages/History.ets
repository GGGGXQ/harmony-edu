import http from '@ohos.net.http';
import router from '@ohos.router';
import { ApiClient, ResponseData } from '../service/ApiClient';
import { PixelStyles } from '../common/PixelStyles';
import { IconChevronLeft, IconTrash, IconClock, IconBookOpen } from '../common/Icons';

interface SessionItem {
  id: string;
  courseId: string;
  courseName: string;
  title: string;
  createdAt: string;
  updatedAt: string;
}

interface HeaderItem { type: 'header'; courseName: string; }
interface SessionEntryItem { type: 'session'; courseName: string; session: SessionItem; }
type GroupedItem = HeaderItem | SessionEntryItem;

const REFRESH_DEBOUNCE_MS: number = 800;

@Entry
@Component
struct HistoryPage {
  @State sessions: SessionItem[] = []
  @State courseId: string = ''
  @State loading: boolean = true
  @State loadingMore: boolean = false
  @State hasMore: boolean = true
  @State currentPage: number = 1
  @State totalPages: number = 1
  private listController: Scroller = new Scroller()
  private lastRefreshAt: number = 0;

  aboutToAppear() {
    let params = router.getParams() as Record<string, string> | null;
    this.courseId = params ? params['courseId'] : '';
    this.loadSessions(1);
  }

  async loadSessions(page: number) {
    if (page === 1) { this.loading = true; } else { this.loadingMore = true; }
    try {
      let path: string = this.courseId
        ? '/sessions/' + this.courseId + '?page=' + String(page) + '&size=20'
        : '/sessions?page=' + String(page) + '&size=20';
      let res: ResponseData = await ApiClient.request(http.RequestMethod.GET, path);
      if (res.code === 200) {
        let pageData: Record<string, Object> = res.data as Record<string, Object>;
        let list: SessionItem[] = pageData['records'] as SessionItem[];
        if (page === 1) { this.sessions = list; } else { this.sessions = this.sessions.concat(list); }
        this.currentPage = Number(pageData['page']);
        this.totalPages = Number(pageData['pages']);
        this.hasMore = this.currentPage < this.totalPages;
      }
    } catch (e) { console.error('loadSessions failed', JSON.stringify(e)); }
    this.loading = false;
    this.loadingMore = false;
  }

  onRefresh() {
    if (this.loading || this.loadingMore) return;
    let now: number = Date.now();
    if (now - this.lastRefreshAt < REFRESH_DEBOUNCE_MS) return;
    this.lastRefreshAt = now;
    this.loadSessions(1);
  }

  onLoadMore() {
    if (!this.hasMore || this.loadingMore || this.loading) return;
    this.loadSessions(this.currentPage + 1);
  }

  async confirmDelete(sessionId: string) {
    AlertDialog.show({
      title: '删除记录',
      message: '确定要删除这条会话记录吗？',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '删除',
        fontColor: PixelStyles.DANGER,
        action: async () => {
          try { await ApiClient.request(http.RequestMethod.DELETE, '/sessions/' + sessionId); }
          catch (e) { console.error('delete session failed', JSON.stringify(e)); }
          this.onRefresh();
        }
      }
    })
  }

  private buildGroupedItems(): GroupedItem[] {
    let result: GroupedItem[] = [];
    let seen: string[] = [];
    for (let i: number = 0; i < this.sessions.length; i++) {
      let s: SessionItem = this.sessions[i];
      let key: string = s.courseName ? s.courseName : '未分类';
      if (seen.indexOf(key) === -1) {
        seen.push(key);
        result.push({ type: 'header', courseName: key });
      }
      result.push({ type: 'session', courseName: key, session: s });
    }
    return result;
  }

  private formatDate(iso: string): string {
    if (!iso) return '';
    let y: string = iso.substring(2, 4);
    let md: string = iso.substring(5, 10);
    let t: string = iso.substring(11, 16);
    return y + '.' + md + '  ' + t;
  }

  build() {
    Column() {
        Row() {
          Row() { IconChevronLeft(24, PixelStyles.INK) }
            .width(36).height(36)
          .justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
          .onClick(() => router.back())

        Text('历史记录')
          .fontSize(18)
          .fontColor(PixelStyles.INK)
          .fontFamily(PixelStyles.FONT_DISPLAY)
          .fontWeight(600)
          .margin({ left: 6 })
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 12, right: 16, top: 10, bottom: 10 })
      .backgroundColor(PixelStyles.SURFACE)
      .borderWidth({ bottom: PixelStyles.BORDER_WIDTH })
      .borderColor({ bottom: PixelStyles.BORDER_LIGHT })
      .borderStyle({ bottom: BorderStyle.Solid })

      if (this.loading) {
        Column() { LoadingProgress().width(24).height(24).color(PixelStyles.ACCENT) }
          .layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.sessions.length === 0) {
        Column() {
          IconClock(56, PixelStyles.INK_MUTED)
          Text('暂无提问记录')
            .fontSize(18).fontColor(PixelStyles.INK).fontFamily(PixelStyles.FONT_DISPLAY).fontWeight(600)
            .margin({ top: 20, bottom: 8 })
          Text('在课程中提问后，记录会显示在这里')
            .fontSize(15).fontColor(PixelStyles.INK_SECONDARY).fontFamily(PixelStyles.FONT_BODY)
        }
        .layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List({ scroller: this.listController }) {
          ForEach(this.buildGroupedItems(), (item: GroupedItem) => {
            if (item.type === 'header') {
              ListItem() {
                Column() {
                  Row() {
                    Row({ space: 8 }) {
                      Column()
                        .width(3).height(14)
                        .backgroundColor(PixelStyles.ACCENT).borderRadius(PixelStyles.RADIUS_FULL)
                      Text(item.courseName)
                        .fontSize(15)
                        .fontColor(PixelStyles.INK)
                        .fontFamily(PixelStyles.FONT_DISPLAY)
                        .fontWeight(600)
                    }
                    Blank()
                    Text(String(this.sessions.filter((s: SessionItem) => (s.courseName || '未分类') === item.courseName).length) + ' 条')
                      .fontSize(11)
                      .fontColor(PixelStyles.INK_MUTED)
                      .fontFamily(PixelStyles.FONT_LABEL)
                      .fontWeight(500)
                  }
                  .width('100%')

                }
                .width('100%')
                .padding({ left: 24, right: 24, top: 28, bottom: 8 })
                .backgroundColor(PixelStyles.SCREEN_BG)
              }
            } else {
              ListItem() {
                Row() {
                  Column() {
                    Text(item.session.title || item.courseName)
                      .fontSize(17)
                      .fontColor(PixelStyles.INK)
                      .fontFamily(PixelStyles.FONT_BODY)
                      .fontWeight(600)
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%')

                    Row({ space: 6 }) {
                      Text(this.formatDate(item.session.updatedAt || item.session.createdAt))
                        .fontSize(12)
                        .fontColor(PixelStyles.INK_MUTED)
                        .fontFamily(PixelStyles.FONT_LABEL)
                        .fontWeight(500)
                    }
                    .margin({ top: 10 })
                    .width('100%')
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)

                  Row() { IconTrash(22, PixelStyles.DANGER) }
                    .width(40).height(40)
                    .borderRadius(PixelStyles.RADIUS_SM)
                    .backgroundColor(PixelStyles.SURFACE_SECONDARY)
                    .justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
                    .margin({ left: 14 })
                    .onClick(() => { this.confirmDelete(item.session.id); })
                }
                .width('100%')
                .padding({ left: 18, right: 18, top: 20, bottom: 20 })
                .alignItems(VerticalAlign.Top)
                .backgroundColor(PixelStyles.SURFACE)
                .borderWidth(PixelStyles.BORDER_WIDTH)
                .borderColor(PixelStyles.BORDER)
                .borderStyle(BorderStyle.Solid)
                .borderRadius(PixelStyles.RADIUS_SM)
                .shadow({ radius: 10, color: '#2C2C2C20', offsetX: 3, offsetY: 3 })
              }
              .padding({ left: 20, right: 20, top: 3, bottom: 3 })
              .onClick(() => {
                let s: SessionItem = item.session;
                router.pushUrl({
                  url: 'pages/QaChat',
                  params: { 'courseId': String(s.courseId), 'courseName': s.courseName, 'sessionId': s.id } as Record<string, string>
                })
              })
            }
          }, (item: GroupedItem) => {
            return item.type === 'header' ? 'h_' + item.courseName : 's_' + item.session.id;
          })

          if (this.hasMore) {
            ListItem() {
              Row() {
                if (this.loadingMore) { LoadingProgress().width(14).height(14).color(PixelStyles.ACCENT).margin({ right: 8 }) }
                Text(this.loadingMore ? '加载中...' : '-- 上拉翻阅更多 --')
                  .fontSize(13).fontColor(PixelStyles.INK_MUTED).fontFamily(PixelStyles.FONT_LABEL)
              }
              .width('100%').justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
              .padding({ top: 16, bottom: 32 })
            }
          }
        }
        .width('100%')
        .layoutWeight(1)
        .margin({ top: 8 })
        .onReachStart(() => { this.onRefresh(); })
        .onReachEnd(() => { this.onLoadMore(); })
      }
    }
    .width('100%').height('100%').backgroundColor(PixelStyles.SCREEN_BG)
  }
}

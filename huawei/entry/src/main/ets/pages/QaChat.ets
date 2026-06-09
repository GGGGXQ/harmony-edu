import http from '@ohos.net.http';
import router from '@ohos.router';
import emitter from '@ohos.events.emitter';
import { ApiClient, StreamHandle, ResponseData, SSEEventMsg, SSE_EVENT_ID, SSE_KIND_EVENT, SSE_KIND_COMPLETE, SSE_KIND_ERROR } from '../service/ApiClient';
import { PixelStyles } from '../common/PixelStyles';
import { IconChevronLeft, IconSparkle, IconSend, IconAlertCircle, IconMessageCircle } from '../common/Icons';
import {
  Markdown, EMarkdownMode,
  BaseEngine, type ITheme,
} from 'fluid-markdown';
import { MDLength } from 'fluid-markdown';

interface QaRequestBody { courseId: string; question: string; sessionId?: string; }

@Observed
class QaSource { id: string = ''; content: string = ''; }

@Observed
class ChatMessage {
  role: string = '';
  content: string = '';
  sources: QaSource[] = [];
  loading: boolean = false;
  error: boolean = false;
  pendingQuestion: string = '';
}

const SUGGESTED_QUESTIONS: string[] = [
  '这个课程主要讲什么？',
  '有什么重点内容需要掌握？',
  '考试会涉及哪些知识点？'
];

@Builder
function suggestedQuestionItem(q: string, index: number, onPick: (q: string) => void) {
  Row() {
    Text(String(index + 1) + '.')
      .fontSize(14)
      .fontColor(PixelStyles.INK_MUTED)
      .fontFamily(PixelStyles.FONT_LABEL)
      .fontWeight(500)
      .margin({ right: 12 })

    Text(q)
      .fontSize(15)
      .fontColor(PixelStyles.INK)
      .fontFamily(PixelStyles.FONT_BODY)
      .fontWeight(500)
      .maxLines(2)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .layoutWeight(1)
  }
  .width('88%')
  .padding(14)
  .backgroundColor(PixelStyles.SURFACE)
  .borderWidth(PixelStyles.BORDER_WIDTH)
  .borderColor(PixelStyles.BORDER)
  .borderStyle(BorderStyle.Solid)
  .borderRadius(PixelStyles.RADIUS_MD)
  .margin({ bottom: 10 })
  .onClick(() => onPick(q))
}

let fluidEngine: BaseEngine = new BaseEngine();
function initFluidTheme(): void {
  let theme: ITheme = fluidEngine.theme!.theme!;
  theme.document!.font!.fontColor = PixelStyles.INK;
  theme.document!.font!.fontSize = MDLength.vp(15);
  theme.document!.lineHeight = { height: MDLength.vp(24) };
  theme.document!.blockSpace = MDLength.vp(8);
  theme.heading!.h1!.font = { fontSize: MDLength.vp(18), fontWeight: FontWeight.Bold, fontColor: PixelStyles.INK };
  theme.heading!.h2!.font = { fontSize: MDLength.vp(16), fontWeight: FontWeight.Bold, fontColor: PixelStyles.INK };
  theme.heading!.h3!.font = { fontSize: MDLength.vp(15), fontWeight: FontWeight.Bold, fontColor: PixelStyles.INK };
  theme.heading!.h4!.font = { fontSize: MDLength.vp(14), fontWeight: FontWeight.Bold, fontColor: PixelStyles.INK };
  theme.heading!.h5!.font = { fontSize: MDLength.vp(13), fontWeight: FontWeight.Bold, fontColor: PixelStyles.INK };
  theme.heading!.h6!.font = { fontSize: MDLength.vp(12), fontWeight: FontWeight.Bold, fontColor: PixelStyles.INK };
  theme.link!.font = { fontColor: PixelStyles.ACCENT };
  theme.strong!.font = { fontWeight: FontWeight.Bold };
  theme.emphasis!.font = { fontStyle: FontStyle.Italic };
  theme.strikeThrough!.decoration = { type: TextDecorationType.LineThrough };
  theme.inlineCode!.background = { color: 0xF0EBE6, radius: MDLength.vp(3) };
  theme.listItem!.contentTopBoxFont = { fontColor: PixelStyles.ACCENT };
  theme.quote!.edgeColor = 0xCCCCCC;
  theme.quote!.edgeWidth = MDLength.vp(3);
  theme.quote!.font = { fontColor: PixelStyles.INK_SECONDARY };
}
{ let _ = initFluidTheme(); }

@Component
struct MessageItemView {
  @ObjectLink message: ChatMessage
  public onRetry: (q: string) => void = () => {}
  build() {
    if (this.message.role === 'user') {
      Row() {
        Blank()
        Text(this.message.content)
          .fontSize(15)
          .fontColor('#FFFFFF')
          .fontFamily(PixelStyles.FONT_BODY)
          .lineHeight(22)
          .padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .backgroundColor(PixelStyles.ACCENT)
          .borderRadius(PixelStyles.RADIUS_MD)
          .constraintSize({ maxWidth: '72%' })
      }
      .width('100%')
      .padding({ left: 64, right: 16, top: 8, bottom: 4 })
    } else {
      Column() {
        Row({ space: 6 }) {
          IconSparkle(16, PixelStyles.ACCENT)
          Text('AI 智能助教')
            .fontSize(11)
            .fontColor(PixelStyles.INK_MUTED)
            .fontFamily(PixelStyles.FONT_LABEL)
            .fontWeight(600)
        }
        .margin({ left: 4, bottom: 8 })

        if (this.message.sources && this.message.sources.length > 0) {
          Row() {
            Column()
              .width(3).height(11)
              .backgroundColor(PixelStyles.ACCENT)
              .borderRadius(PixelStyles.RADIUS_FULL)
              .margin({ right: 8 })
            Text('参考来源')
              .fontSize(12)
              .fontColor(PixelStyles.INK)
              .fontFamily(PixelStyles.FONT_LABEL)
              .fontWeight(600)
            Text(' ' + String(this.message.sources.length))
              .fontSize(12)
              .fontColor(PixelStyles.INK_MUTED)
              .fontFamily(PixelStyles.FONT_LABEL)

            Blank()

            Text('查看')
              .fontSize(12)
              .fontColor(PixelStyles.ACCENT)
              .fontFamily(PixelStyles.FONT_LABEL)
              .fontWeight(500)
          }
          .width('100%')
          .backgroundColor(PixelStyles.SURFACE_SECONDARY)
          .borderRadius(PixelStyles.RADIUS_SM)
          .padding({ left: 12, right: 12, top: 10, bottom: 10 })
          .margin({ bottom: 10 })
          .onClick(() => {
            router.pushUrl({
              url: 'pages/SourceDetail',
              params: { 'sources': JSON.stringify(this.message.sources) }
            })
          })
        }

        if (this.message.loading) {
          Row() {
            LoadingProgress().width(14).height(14).color(PixelStyles.ACCENT).margin({ right: 10 })
            Text('思考中...')
              .fontSize(14)
              .fontColor(PixelStyles.INK_SECONDARY)
              .fontFamily(PixelStyles.FONT_BODY)
          }
          .alignItems(VerticalAlign.Center)
          .width('100%')
          .padding(14)
          .backgroundColor(PixelStyles.SURFACE)
          .borderWidth(PixelStyles.BORDER_WIDTH)
          .borderColor(PixelStyles.BORDER_LIGHT)
          .borderStyle(BorderStyle.Solid)
          .borderRadius(PixelStyles.RADIUS_MD)
        } else if (this.message.error) {
          Column() {
            Row({ space: 8 }) {
              IconAlertCircle(20, PixelStyles.DANGER)
              Text('回答生成失败')
                .fontSize(14)
                .fontColor(PixelStyles.DANGER)
                .fontFamily(PixelStyles.FONT_LABEL)
                .fontWeight(600)
            }
            .alignItems(VerticalAlign.Center)
            .margin({ bottom: 8 })

            Text(this.message.content)
              .fontSize(13)
              .fontColor(PixelStyles.INK_SECONDARY)
              .fontFamily(PixelStyles.FONT_BODY)
              .lineHeight(20)

            Row({ space: 12 }) {
              Text('重试')
                .fontSize(14)
                .fontColor('#FFFFFF')
                .fontFamily(PixelStyles.FONT_LABEL)
                .fontWeight(600)
                .padding({ left: 16, right: 16, top: 7, bottom: 7 })
                .backgroundColor(PixelStyles.ACCENT)
                .borderRadius(PixelStyles.RADIUS_SM)
                .onClick(() => {
                  if (this.message.pendingQuestion) { this.onRetry(this.message.pendingQuestion); }
                })

              Text('忽略')
                .fontSize(13)
                .fontColor(PixelStyles.INK_MUTED)
                .fontFamily(PixelStyles.FONT_LABEL)
                .padding({ left: 4, right: 4 })
                .onClick(() => {})
            }
            .margin({ top: 10 })
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding(14)
          .backgroundColor('#FFF5F5')
          .borderWidth(PixelStyles.BORDER_WIDTH)
          .borderColor(PixelStyles.DANGER)
          .borderStyle(BorderStyle.Solid)
          .borderRadius(PixelStyles.RADIUS_MD)
        } else {
          Column() {
            Markdown({
              content: this.message.content,
              mode: EMarkdownMode.Normal,
              engine: fluidEngine,
              onMarkdownNodeClick: () => {},
              onMarkdownAreaChange: () => {},
            })
          }
          .width('100%')
          .backgroundColor(PixelStyles.SURFACE)
          .borderWidth(PixelStyles.BORDER_WIDTH)
          .borderColor(PixelStyles.BORDER)
          .borderStyle(BorderStyle.Solid)
          .borderRadius(PixelStyles.RADIUS_SM)
          .padding({ left: 16, right: 16, top: 14, bottom: 14 })
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 16, right: 64, top: 8, bottom: 4 })
    }
  }
}

@Entry
@Component
struct QaChatPage {
  @State courseId: string = ''
  @State courseName: string = ''
  @State sessionId: string = ''
  @State question: string = ''
  @State messages: ChatMessage[] = []
  @State loading: boolean = false
  @State loadingHistory: boolean = false
  @State sendBtnShake: boolean = false
  private streamHandle: StreamHandle | null = null
  listController: Scroller = new Scroller()
  private pendingIdx: number = -1
  private pendingQ: string = ''

  aboutToAppear() {
    let params = router.getParams() as Record<string, string> | null;
    this.courseId = params ? params['courseId'] : '';
    this.courseName = params ? params['courseName'] : '';
    this.sessionId = params && params['sessionId'] ? params['sessionId'] : '';
    if (this.sessionId) { this.loadHistory(); }
    emitter.on(SSE_EVENT_ID, (event: emitter.EventData): void => {
      let msg: SSEEventMsg = event.data as SSEEventMsg;
      if (!msg) { return; }
      if (msg.kind === SSE_KIND_EVENT && msg.body) { this.processSSEEvent(msg.body); }
      else if (msg.kind === SSE_KIND_COMPLETE) { this.processSSEComplete(); }
      else if (msg.kind === SSE_KIND_ERROR && msg.body) { this.processSSEError(msg.body); }
    });
  }

  aboutToDisappear() {
    if (this.streamHandle) { this.streamHandle.close(); this.streamHandle = null; }
    ApiClient.closePersistentWs();
    emitter.off(SSE_EVENT_ID);
  }

  processSSEEvent(jsonStr: string): void {
    let idx: number = this.pendingIdx;
    if (idx < 0) return;
    try {
      let event: Record<string, Object> = JSON.parse(jsonStr) as Record<string, Object>;
      let type: string = event['type'] as string;
      if (type === 'start') { this.loading = false; }
      else if (type === 'sources') {
        let arr: Object[] = event['data'] as Object[];
        let msg: ChatMessage | undefined = this.messages[idx];
        if (msg) {
          let newSources: QaSource[] = [];
          for (let i: number = 0; i < arr.length; i++) {
            let r: Record<string, Object> = arr[i] as Record<string, Object>;
            let src: QaSource = new QaSource();
            src.id = r['id'] as string; src.content = r['content'] as string;
            newSources.push(src);
          }
          msg.sources = [...msg.sources, ...newSources];
        }
      } else if (type === 'token') {
        let token: string = event['content'] as string;
        if (token) {
          let msg: ChatMessage | undefined = this.messages[idx];
          if (msg) { msg.content += token; msg.loading = false; }
          this.scrollToBottom();
        }
      } else if (type === 'done') {
        let data: Record<string, Object> = event['data'] as Record<string, Object>;
        let sid: string = data['sessionId'] as string;
        if (sid) { this.sessionId = sid; }
        let msg: ChatMessage | undefined = this.messages[idx];
        if (msg) { msg.loading = false; }
        this.pendingIdx = -1; this.scrollToBottom();
      } else if (type === 'error') {
        let errContent: string = (event['content'] as string) || '服务异常，请重试';
        let sid: string = event['sessionId'] as string;
        if (sid) { this.sessionId = sid; }
        this.loading = false; this.pendingIdx = -1;
        let msg: ChatMessage | undefined = this.messages[idx];
        if (msg) {
          msg.loading = false; msg.error = true;
          msg.content = errContent; msg.pendingQuestion = this.pendingQ;
        }
        this.scrollToBottom();
      }
    } catch (e) { console.error('[EVENT] process event error', JSON.stringify(e)); }
  }

  processSSEComplete(): void {
    this.streamHandle = null;
    let idx: number = this.pendingIdx;
    if (idx < 0) return;
    this.loading = false; this.pendingIdx = -1;
    let msg: ChatMessage | undefined = this.messages[idx];
    if (msg) { msg.loading = false; }
    this.scrollToBottom();
  }

  processSSEError(errMsg: string): void {
    this.streamHandle = null;
    let idx: number = this.pendingIdx;
    if (idx < 0) return;
    this.loading = false; this.pendingIdx = -1;
    let errContent: string = errMsg && errMsg.length > 0 ? errMsg : '请求失败，请重试';
    let msg: ChatMessage | undefined = this.messages[idx];
    if (msg) { msg.loading = false; msg.error = true; msg.content = errContent; msg.pendingQuestion = this.pendingQ; }
    this.scrollToBottom();
  }

  scrollToBottom() { setTimeout(() => { this.listController.scrollEdge(Edge.Bottom); }, 150); }
  shakeSendBtn() { this.sendBtnShake = true; setTimeout(() => { this.sendBtnShake = false; }, 400); }

  async loadHistory() {
    this.loadingHistory = true;
    try {
      let res: ResponseData = await ApiClient.request(http.RequestMethod.GET, '/sessions/' + this.sessionId + '/history');
      if (res.code === 200) {
        let list: Object[] = res.data as Object[];
        let loaded: ChatMessage[] = [];
        for (let i: number = 0; i < list.length; i++) {
          let item: Record<string, Object> = list[i] as Record<string, Object>;
          let sources: QaSource[] = [];
          if (item['sources']) {
            let raw: Object[] = item['sources'] as Object[];
            for (let j: number = 0; j < raw.length; j++) {
              let s: Record<string, Object> = raw[j] as Record<string, Object>;
              let src: QaSource = new QaSource();
              src.id = s['id'] as string; src.content = s['content'] as string;
              sources.push(src);
            }
          }
          let msg: ChatMessage = new ChatMessage();
          msg.role = item['role'] as string;
          msg.content = item['content'] as string;
          msg.sources = sources;
          if (msg.role === 'assistant' && !msg.content) {
            msg.error = true; msg.content = '该回答生成失败，请重试'; msg.pendingQuestion = '';
          }
          loaded.push(msg);
        }
        this.messages = loaded; this.scrollToBottom();
      }
    } catch (e) { console.error('loadHistory failed', JSON.stringify(e)); }
    this.loadingHistory = false;
  }

  ask() {
    if (!this.question.trim()) { this.shakeSendBtn(); return; }
    let q: string = this.question; this.question = '';
    let userMsg: ChatMessage = new ChatMessage();
    userMsg.role = 'user'; userMsg.content = q;
    let placeholder: ChatMessage = new ChatMessage();
    placeholder.role = 'assistant'; placeholder.loading = true;
    this.messages = [...this.messages, userMsg, placeholder];
    this.pendingIdx = this.messages.length - 1;
    this.pendingQ = q; this.loading = true;
    this.scrollToBottom();

    let reqBody: QaRequestBody = { courseId: this.courseId, question: q };
    if (this.sessionId) { reqBody.sessionId = this.sessionId; }
    let body: string = JSON.stringify(reqBody);
    if (this.streamHandle) { this.streamHandle.close(); this.streamHandle = null; }
    this.streamHandle = ApiClient.requestStream(http.RequestMethod.POST, '/qa/ask/stream', body);
  }

  retryQuestion(pendingQ: string) {
    let idx: number = -1;
    for (let i: number = 0; i < this.messages.length; i++) {
      if (this.messages[i].error && this.messages[i].pendingQuestion === pendingQ) { idx = i; break; }
    }
    if (idx < 0) return;
    let msg: ChatMessage = this.messages[idx];
    msg.loading = true; msg.error = false; msg.content = '';
    this.pendingIdx = idx; this.pendingQ = pendingQ; this.loading = true;
    this.scrollToBottom();

    let reqBody: QaRequestBody = { courseId: this.courseId, question: pendingQ };
    if (this.sessionId) { reqBody.sessionId = this.sessionId; }
    let body: string = JSON.stringify(reqBody);
    if (this.streamHandle) { this.streamHandle.close(); this.streamHandle = null; }
    this.streamHandle = ApiClient.requestStream(http.RequestMethod.POST, '/qa/ask/stream', body);
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

        Column() {
          Text(this.courseName)
            .fontSize(17)
            .fontColor(PixelStyles.INK)
            .fontFamily(PixelStyles.FONT_DISPLAY)
            .fontWeight(600)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)

        Column() {
          Text('历史')
            .fontSize(13)
            .fontColor(PixelStyles.INK)
            .fontFamily(PixelStyles.FONT_LABEL)
            .fontWeight(500)
        }
        .height(32)
        .padding({ left: 12, right: 12 })
        .backgroundColor(PixelStyles.SURFACE)
        .borderWidth(PixelStyles.BORDER_WIDTH)
        .borderColor(PixelStyles.BORDER)
        .borderStyle(BorderStyle.Solid)
        .borderRadius(PixelStyles.RADIUS_SM)
        .shadow({ radius: 6, color: '#2C2C2C15', offsetX: 2, offsetY: 2 })
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          router.pushUrl({
            url: 'pages/History',
            params: { 'courseId': String(this.courseId) } as Record<string, string>
          })
        })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
      .backgroundColor(PixelStyles.SURFACE)
      .borderWidth({ bottom: PixelStyles.BORDER_WIDTH })
      .borderColor({ bottom: PixelStyles.BORDER_LIGHT })
      .borderStyle({ bottom: BorderStyle.Solid })

      if (this.loadingHistory) {
        Column() { LoadingProgress().width(24).height(24).color(PixelStyles.ACCENT) }
          .layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.messages.length === 0) {
        Column() {
          IconMessageCircle(64, PixelStyles.INK_MUTED)
          Text('AI 智能助教')
            .fontSize(20)
            .fontColor(PixelStyles.INK)
            .fontFamily(PixelStyles.FONT_DISPLAY)
            .fontWeight(700)
            .margin({ top: 20, bottom: 8 })

          Text('基于课程资料，AI 将为你解答问题')
            .fontSize(15)
            .fontColor(PixelStyles.INK_SECONDARY)
            .fontFamily(PixelStyles.FONT_BODY)
            .margin({ bottom: 40 })

          ForEach(SUGGESTED_QUESTIONS, (q: string, idx: number) => {
            suggestedQuestionItem(q, idx, (picked: string) => {
              this.question = picked; this.ask();
            })
          }, (q: string) => q)
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: 24, right: 24, top: 48 })
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ scroller: this.listController }) {
          ForEach(this.messages, (msg: ChatMessage) => {
            ListItem() {
              MessageItemView({
                message: msg,
                onRetry: (q: string) => { this.retryQuestion(q); }
              })
            }
          }, (item: ChatMessage, i?: number) => String(i))
        }
        .layoutWeight(1).width('100%')
      }

      Row({ space: 10 }) {
        TextInput({ placeholder: '输入课程相关问题...', text: this.question })
          .onChange((v: string) => this.question = v)
          .onSubmit(() => this.ask())
          .height(44)
          .layoutWeight(1)
          .backgroundColor(PixelStyles.INPUT_BG)
          .fontColor(PixelStyles.INK)
          .fontFamily(PixelStyles.FONT_BODY)
          .fontSize(15)
          .borderWidth(PixelStyles.BORDER_WIDTH)
          .borderColor(this.sendBtnShake ? PixelStyles.DANGER : PixelStyles.BORDER)
          .borderStyle(BorderStyle.Solid)
          .borderRadius(PixelStyles.RADIUS_MD)
          .padding({ left: 16, right: 16 })
          .placeholderColor(PixelStyles.INK_MUTED)
          .enabled(!this.loading)

        Column() {
          if (this.loading) {
            LoadingProgress().width(18).height(18).color('#FFFFFF')
          } else {
            IconSend(22, '#FFFFFF')
          }
        }
        .width(44).height(44)
        .backgroundColor(this.loading ? PixelStyles.ACCENT_LIGHT : PixelStyles.ACCENT)
        .borderRadius(PixelStyles.RADIUS_MD)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .opacity(this.question.trim().length > 0 || this.loading ? 1 : 0.4)
        .onClick(() => this.ask())
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 10, bottom: 14 })
      .backgroundColor(PixelStyles.SURFACE)
      .borderWidth({ top: PixelStyles.BORDER_WIDTH })
      .borderColor({ top: PixelStyles.BORDER_LIGHT })
      .borderStyle({ top: BorderStyle.Solid })
    }
    .width('100%').height('100%').backgroundColor(PixelStyles.SCREEN_BG)
  }
}

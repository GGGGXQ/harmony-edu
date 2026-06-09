import { http, webSocket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import util from '@ohos.util';
import emitter from '@ohos.events.emitter';
import { Constants } from '../common/Constants';
import { AuthStorage } from './AuthStorage';
import { MockData } from './MockData';

export const SSE_EVENT_ID: string = 'sse_event';
export const SSE_KIND_EVENT: string = 'event';
export const SSE_KIND_COMPLETE: string = 'complete';
export const SSE_KIND_ERROR: string = 'error';

export class StreamHandle {
  private closeImpl: (() => void) | null = null;

  constructor(closeImpl: () => void) {
    this.closeImpl = closeImpl;
  }

  close(): void {
    if (this.closeImpl) {
      this.closeImpl();
      this.closeImpl = null;
    }
  }
}

export class SSEEventMsg {
  kind: string = '';
  body: string = '';
}

export class ResponseData {
  code: number = 0;
  message: string = '';
  data: Object = new Object();
}

function emitSSE(kind: string, body: string): void {
  let msg: SSEEventMsg = new SSEEventMsg();
  msg.kind = kind;
  msg.body = body;
  emitter.emit(SSE_EVENT_ID, { data: msg });
}

export class ApiClient {
  static useMock: boolean = false;

  private static persistentWs: webSocket.WebSocket | null = null;
  private static persistentWsUrl: string = '';
  private static wsConnected: boolean = false;
  private static cancelled: boolean = false;
  private static pendingBody: string | null = null;

  static request(
    method: http.RequestMethod,
    path: string,
    body?: string
  ): Promise<ResponseData> {
    if (ApiClient.useMock) {
      return MockData.mockRequest(method, path, body);
    }

    let httpRequest = http.createHttp();
    let url = Constants.BASE_URL + path;
    let token = AuthStorage.getToken();

    let header: Record<string, string> = {} as Record<string, string>;
    header['Content-Type'] = 'application/json';
    if (token) {
      header['Authorization'] = 'Bearer ' + token;
    }

    return httpRequest.request(url, {
      method: method,
      header: header,
      extraData: body,
      connectTimeout: 30000,
      readTimeout: 30000,
    }).then((response: http.HttpResponse) => {
      httpRequest.destroy();
      try {
        return JSON.parse(response.result as string) as ResponseData;
      } catch (e) {
        let r: ResponseData = new ResponseData();
        r.code = -1;
        r.message = '响应解析失败';
        return r;
      }
    }).catch((err: BusinessError) => {
      httpRequest.destroy();
      let r: ResponseData = new ResponseData();
      r.code = -1;
      r.message = err.message || '网络请求失败';
      return r;
    });
  }

  static requestStream(
    method: http.RequestMethod,
    path: string,
    body: string | undefined
  ): StreamHandle {
    if (ApiClient.useMock) {
      MockData.mockStreamRequest(method, path, body,
        (json: string) => emitSSE(SSE_KIND_EVENT, json),
        () => emitSSE(SSE_KIND_COMPLETE, ''),
        (msg: string) => emitSSE(SSE_KIND_ERROR, msg)
      );
      return new StreamHandle(() => {});
    }

    let cleanPath: string = path.replace('/stream', '');
    let wsUrl: string = 'ws://10.0.2.2:8080/ws' + cleanPath;
    let token: string | null = AuthStorage.getToken();

    ApiClient.cancelled = true;

    if (!ApiClient.persistentWs || ApiClient.persistentWsUrl !== wsUrl || !ApiClient.wsConnected) {
      ApiClient.closePersistentWs();
      ApiClient.createPersistentWs(wsUrl, token);
    }

    ApiClient.cancelled = false;
    if (ApiClient.wsConnected && ApiClient.persistentWs && body) {
      ApiClient.persistentWs.send(body).catch((sendErr: BusinessError) => {
        console.info('[WS] send error: ' + sendErr.message);
      });
    } else if (body) {
      ApiClient.pendingBody = body;
    }

    return new StreamHandle(() => {
      ApiClient.cancelled = true;
    });
  }

  private static createPersistentWs(wsUrl: string, token: string | null): void {
    console.info('[WS] createPersistentWs: ' + wsUrl);
    let ws: webSocket.WebSocket = webSocket.createWebSocket();
    ApiClient.persistentWs = ws;
    ApiClient.persistentWsUrl = wsUrl;
    ApiClient.wsConnected = false;

    ws.on('open', (openErr: BusinessError, openData: Object) => {
      console.info('[WS] persistent open');
      ApiClient.wsConnected = true;
      if (ApiClient.pendingBody && ws === ApiClient.persistentWs) {
        ws.send(ApiClient.pendingBody).catch(() => {});
        ApiClient.pendingBody = null;
      }
    });

    ws.on('message', (msgErr: BusinessError, data: string | ArrayBuffer) => {
      if (ApiClient.cancelled) { return; }
      let text: string = '';
      if (typeof data === 'string') {
        text = data;
      } else if (data instanceof ArrayBuffer) {
        let decoder: util.TextDecoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
        text = decoder.decodeToString(new Uint8Array(data));
      }
      if (text.length > 0) {
        console.info('[WS] message len=' + text.length + ', preview=' + text.substring(0, 60));
        emitSSE(SSE_KIND_EVENT, text);
      }
    });

    ws.on('close', (closeErr: BusinessError, closeData: webSocket.CloseResult) => {
      console.info('[WS] persistent close code=' + closeData.code + ' reason=' + closeData.reason);
      if (ws === ApiClient.persistentWs) {
        ApiClient.persistentWs = null;
        ApiClient.persistentWsUrl = '';
        ApiClient.wsConnected = false;
      }
      if (!ApiClient.cancelled) {
        emitSSE(SSE_KIND_COMPLETE, '');
      }
    });

    ws.on('error', (err: BusinessError) => {
      console.info('[WS] persistent error: ' + err.message);
      if (ws === ApiClient.persistentWs) {
        ApiClient.persistentWs = null;
        ApiClient.persistentWsUrl = '';
        ApiClient.wsConnected = false;
      }
      if (!ApiClient.cancelled) {
        ApiClient.cancelled = true;
        emitSSE(SSE_KIND_ERROR, err.message || 'WebSocket连接失败');
      }
    });

    let wsOptions: webSocket.WebSocketRequestOptions = {} as webSocket.WebSocketRequestOptions;
    if (token) {
      wsOptions.header = { 'Authorization': 'Bearer ' + token } as Record<string, string>;
    }

    ws.connect(wsUrl, wsOptions).catch((connectErr: BusinessError) => {
      console.info('[WS] connect error: ' + connectErr.message);
      if (ws === ApiClient.persistentWs) {
        ApiClient.persistentWs = null;
        ApiClient.persistentWsUrl = '';
        ApiClient.wsConnected = false;
      }
      if (!ApiClient.cancelled) {
        ApiClient.cancelled = true;
        emitSSE(SSE_KIND_ERROR, connectErr.message || 'WebSocket连接失败');
      }
    });
  }

  static closePersistentWs(): void {
    ApiClient.cancelled = true;
    ApiClient.pendingBody = null;
    if (ApiClient.persistentWs) {
      try {
        ApiClient.persistentWs.off('open');
        ApiClient.persistentWs.off('message');
        ApiClient.persistentWs.off('close');
        ApiClient.persistentWs.off('error');
        ApiClient.persistentWs.close();
      } catch (e) {}
      ApiClient.persistentWs = null;
    }
    ApiClient.persistentWsUrl = '';
    ApiClient.wsConnected = false;
  }
}

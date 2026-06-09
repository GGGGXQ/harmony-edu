import http from '@ohos.net.http';

interface MockUserData {
  id: string;
  username: string;
  email: string;
  createdAt: string;
}

export class MockResponse {
  code: number = 0;
  message: string = '';
  data: Object = new Object();
}

interface MockTokenData {
  token: string;
  userId: string;
}

interface MockCourseData {
  id: string;
  name: string;
  description: string;
  createdAt: string;
}

interface MockHistoryData {
  id: string;
  userId: string;
  courseId: string;
  question: string;
  answer: string;
  sources: string;
  createdAt: string;
}

interface MockAnswerData {
  answer: string;
}

interface QaSource {
  id: string;
  content: string;
}

interface MockDoneData {
  role: string;
  content: string;
  sessionId: string;
  sources: QaSource[];
}

interface MockTokenEvent {
  type: string;
  content: string;
}

export class MockData {
  static mockRequest(method: http.RequestMethod, path: string, body?: string): Promise<MockResponse> {
    return new Promise<MockResponse>((resolve: (value: MockResponse) => void) => {
      setTimeout(() => {
        let result: MockResponse = MockData.route(method, path, body);
        resolve(result);
      }, 300);
    });
  }

  static mockStreamRequest(
    method: http.RequestMethod,
    path: string,
    body: string | undefined,
    onEvent: (jsonStr: string) => void,
    onComplete: () => void,
    onError: (msg: string) => void
  ): void {
    let q: string = '';
    if (body) {
      try {
        let parsed: Record<string, string> = JSON.parse(body) as Record<string, string>;
        q = parsed['question'] || '';
      } catch (e) {
      }
    }
    let answer: string = MockData.getMockAnswer(q);
    let sources: QaSource[] = [
      { id: 'mock_src_1', content: '教材示例片段 — 来自 mock 数据集' },
      { id: 'mock_src_2', content: '补充讲义片段 — 来自 mock 数据集' }
    ];
    let sourcesJson: string = JSON.stringify(sources);

    onEvent('{"type":"start","role":"assistant"}');
    setTimeout(() => {
      onEvent('{"type":"sources","data":' + sourcesJson + '}');
      let i: number = 0;
      let interval: number = setInterval(() => {
        if (i >= answer.length) {
          clearInterval(interval);
          let doneData: MockDoneData = {
            role: 'assistant',
            content: answer,
            sessionId: 'mock_session_' + Date.now(),
            sources: sources
          };
          onEvent('{"type":"done","data":' + JSON.stringify(doneData) + '}');
          onComplete();
          return;
        }
        let ch: string = answer.charAt(i);
        let tokenJson: MockTokenEvent = { type: 'token', content: ch };
        onEvent(JSON.stringify(tokenJson));
        i += 1;
      }, 30);
    }, 100);
  }

  private static makeRes(code: number, message: string, data: Object): MockResponse {
    let r: MockResponse = new MockResponse();
    r.code = code;
    r.message = message;
    r.data = data;
    return r;
  }

  private static route(method: http.RequestMethod, path: string, body?: string): MockResponse {
    if (path === '/auth/login/password' || path === '/auth/login/code') {
      let d: MockTokenData = { token: 'mock_token_' + Date.now(), userId: 'mock_user_1' };
      return MockData.makeRes(200, 'success', d);
    }
    if (path === '/auth/register') {
      let d: MockTokenData = { token: 'mock_token_' + Date.now(), userId: 'mock_user_1' };
      return MockData.makeRes(200, 'success', d);
    }
    if (path === '/auth/logout') {
      return MockData.makeRes(200, 'success', new Object());
    }
    if (path === '/auth/code/send') {
      return MockData.makeRes(200, 'success', new Object());
    }
    if (path === '/auth/code/verify') {
      return MockData.makeRes(200, 'success', new Object());
    }
    if (path === '/courses' && method === http.RequestMethod.GET) {
      return MockData.makeRes(200, 'success', MockData.mockCourses);
    }
    if (path.startsWith('/qa/history')) {
      return MockData.makeRes(200, 'success', MockData.mockHistory);
    }
    if (path === '/qa/ask') {
      let q: string = '';
      try {
        if (body) {
          let parsed: Record<string, string> = JSON.parse(body) as Record<string, string>;
          q = parsed['question'] || '';
        }
      } catch (e) {}
      let a: MockAnswerData = { answer: MockData.getMockAnswer(q) };
      return MockData.makeRes(200, 'success', a);
    }
    if (path === '/users/me') {
      let d: MockUserData = { id: 'mock_user_1', username: 'PixelHero', email: 'hero@pixel.com', createdAt: '2026-01-15T08:00:00' };
      return MockData.makeRes(200, 'success', d);
    }
    return MockData.makeRes(404, 'not found', new Object());
  }

  private static readonly mockCourses: MockCourseData[] = [
    { id: 'c1', name: '数据结构', description: '数组、链表、树、图 — 计算机科学的基石', createdAt: '2026-01-01' },
    { id: 'c2', name: '操作系统', description: '进程管理、内存管理、文件系统与 I/O', createdAt: '2026-01-02' },
    { id: 'c3', name: '计算机网络', description: 'TCP/IP 协议栈、HTTP、DNS、网络安全', createdAt: '2026-01-03' },
    { id: 'c4', name: '数据库原理', description: '关系模型、SQL、索引、事务与并发控制', createdAt: '2026-01-04' }
  ];

  private static readonly mockHistory: MockHistoryData[] = [
    { id: 'h1', userId: 'mock_user_1', courseId: 'c1', question: '什么是时间复杂度？', answer: '时间复杂度是衡量算法执行时间随输入规模增长而变化的量度，通常用大O表示法表示，如 O(n)、O(log n) 等。', sources: '', createdAt: '2026-05-29T10:00:00' },
    { id: 'h2', userId: 'mock_user_1', courseId: 'c1', question: '数组和链表的区别？', answer: '数组是连续内存空间，支持随机访问 O(1)；链表是离散的节点通过指针连接，插入删除 O(1) 但查找 O(n)。', sources: '', createdAt: '2026-05-29T11:00:00' },
    { id: 'h3', userId: 'mock_user_1', courseId: 'c2', question: '什么是死锁？', answer: '死锁是指两个或多个进程互相等待对方释放资源，导致所有进程都无法继续执行的状态。产生死锁需要四个必要条件：互斥、持有并等待、不可剥夺、循环等待。', sources: '', createdAt: '2026-05-28T09:00:00' }
  ];

  private static getMockAnswer(question: string): string {
    let q = question.toLowerCase();
    if (q.includes('时间') || q.includes('complex')) {
      return '时间复杂度是衡量算法执行效率的重要指标。常见的有：\n• O(1) — 常数时间\n• O(log n) — 对数时间\n• O(n) — 线性时间\n• O(n log n) — 线性对数时间\n• O(n²) — 平方时间';
    }
    if (q.includes('数组') || q.includes('链表') || q.includes('array') || q.includes('list')) {
      return '数组和链表是两种基础数据结构：\n\n数组：连续内存，随机访问 O(1)，插入删除 O(n)\n链表：离散节点，随机访问 O(n)，插入删除 O(1)\n\n选择依据取决于你的操作场景 — 频繁访问选数组，频繁增删选链表。';
    }
    if (q.includes('死锁') || q.includes('deadlock')) {
      return '死锁的四个必要条件（Coffman 条件）：\n1. 互斥 — 资源一次只能被一个进程使用\n2. 持有并等待 — 进程持有资源同时等待其他资源\n3. 不可剥夺 — 资源不能被强制剥夺\n4. 循环等待 — 存在进程循环等待链\n\n预防策略：破坏上述任一条件即可。';
    }
    return `关于「${question}」这个问题，在教材中有相关讨论。\n\n简单来说，这是一个计算机科学中的重要概念。建议你查看课程资料中的对应章节获取更详细的解释。\n\n如果有更具体的问题，欢迎继续提问！`;
  }
}

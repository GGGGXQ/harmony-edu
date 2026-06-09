import { Context } from '@kit.AbilityKit';
import preferences from '@ohos.data.preferences';
import { Constants } from '../common/Constants';

export class AuthStorage {
  private static token: string = '';
  private static userId: string = '';
  private static username: string = '';
  private static abilityContext: Context | null = null;

  static setContext(ctx: Context) {
    AuthStorage.abilityContext = ctx;
  }

  private static getContext(): Context {
    return AuthStorage.abilityContext as Context;
  }

  static async init(context?: Context) {
    const ctx = context || AuthStorage.abilityContext;
    if (!ctx) return;
    const prefs = await preferences.getPreferences(ctx, 'edu_rag_prefs');
    AuthStorage.token = await prefs.get(Constants.TOKEN_KEY, '') as string;
    AuthStorage.userId = await prefs.get('userId', '') as string;
    AuthStorage.username = await prefs.get('username', '') as string;
  }

  static async saveLogin(context: Context | null, token: string, userId: string, username: string = '') {
    AuthStorage.token = token;
    AuthStorage.userId = userId;
    AuthStorage.username = username;
    const ctx = context || AuthStorage.abilityContext;
    if (!ctx) return;
    const prefs = await preferences.getPreferences(ctx, 'edu_rag_prefs');
    await prefs.put(Constants.TOKEN_KEY, token);
    await prefs.put('userId', userId);
    await prefs.put('username', username);
    await prefs.flush();
  }

  static getToken(): string { return AuthStorage.token; }
  static getUserId(): string { return AuthStorage.userId; }
  static getUsername(): string { return AuthStorage.username; }
  static isLoggedIn(): boolean { return AuthStorage.token !== ''; }

  static async logout(context: Context | null) {
    AuthStorage.token = '';
    AuthStorage.userId = '';
    AuthStorage.username = '';
    const ctx = context || AuthStorage.abilityContext;
    if (!ctx) return;
    const prefs = await preferences.getPreferences(ctx, 'edu_rag_prefs');
    await prefs.clear();
    await prefs.flush();
  }
}

// Copyright 2025 The FluidMarkdown Authors. All rights reserved.
// Use of this source code is governed by a Apache 2.0 license that can be
// found in the LICENSE file.

import { Plugin } from '../../engine/plugin';
import { EService, Service } from '../../engine/service';
import Image from '@ohos.multimedia.image';
import { getLatex, initLatex } from 'liblatexentry.so';
import { image } from '@kit.ImageKit';

export class MathService extends Service {
  readonly type: EService = EService.Math;
  private store: Map<string, Image.ImageSource> = new Map();
  private isResLoaded: boolean = false;

  add<T extends Plugin>(_plugin: T): void {}

  private cacheKey(request: IMathServiceRequest): string {
    return `${request.hash}_${request.fontSize}_${request.fontColor}_${request.backgroundColor}`;
  }

  private loadRes() {
    if (!this.isResLoaded) {
      const context = this.engine?.deref()?.ctx?.ctx?.getHostContext()
      initLatex(context ? context.resourceDir + "/res" : "")
      this.isResLoaded = true
    }
  }

  cache(request: IMathServiceRequest): Image.ImageSource | undefined {
    return this.store.get(this.cacheKey(request));
  }

  async generate(request: IMathServiceRequest): Promise<IMathServiceResponse> {
    this.loadRes()

    let response: IMathServiceResponse = {
      success: false,
    }

    let buf: ArrayBuffer = getLatex(request.content, 2000, request.fontSize, 10.0, request.fontColor)
    let imageSource = image.createImageSource(buf)

    this.store.set(this.cacheKey(request), imageSource);

    response.image = imageSource
    response.success = true

    return response
  }
}

export interface IMathServiceRequest {
  content: string;
  hash?: string;
  fontSize?: number;   //  px
  fontColor?: number;
  backgroundColor?: number;
}

export interface IMathServiceResponse {
  success: boolean;
  image?: Image.ImageSource;
  errorMessage?: string;
}
<div align="center">
<h1>formula-ffi</h1>
</div>

<p align="center">
<img alt="" src="https://img.shields.io/badge/release-v1.0.1-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/build-pass-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/cjc-v1.0.0-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/cjcov-NA-red" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/project-open-brightgreen" style="display: inline-block;" />
</p>

## 介绍

formula 主要目的是显示用 LaTeX 编写的数学公式。

### 特性

- 🚀 特性1

  提供生成解析数学公式接口

- 🚀 特性2

  提供生成bitmap接口

- 💪 特性3

  提供生成图片资源接口

## 软件架构

### 源码目录

```shell
formula
├─ doc
│  ├─ assets
│  ├─ design.md
│  └─ feature_api.md
├─ ffi
│  ├─ CMakeLists.txt
│  ├─ ffi
│  │  ├─ graphic_ohos.cpp
│  │  ├─ graphic_ohos.h
│  │  ├─ graphic_ohos_ffi.cpp
│  │  ├─ latex_ffi.cpp
│  │  ├─ render_ffi.cpp
│  │  └─ utils.h
│  └─ latex
├─ README.md
├─ src
│  ├─ ffi.cj
│  ├─ graphic2D.cj
│  ├─ LaTex.cj
│  └─ render.cj
└─ test
   ├─ HLT
   └─ LLT

```

- `doc`  文档目录，用于存放设计、API接口等文档
- `ffi` `ffi`接口
- `src`  源码目录
- `test` 测试目录

### 接口说明

主要类和函数接口说明详见 [API](./doc/feature_api.md)

## 使用说明

### 编译构建

1. 代码下载：

   ```shell
   git clone --recursive https://gitcode.com/Cangjie-TPC/formula-ffi.git
   ```

2. 编译

   1. 下载安装msys2和mingw64

      msys2：https://github.com/msys2/msys2-installer/releases/download/2023-03-18/msys2-x86_64-20230318.exe

      mingw64：https://github.com/niXman/mingw-builds-binaries/releases/download/8.5.0-rt_v10-rev0/x86_64-8.5.0-release-posix-seh-rt_v10-rev0.7z

      将`x86_64-8.5.0-release-posix-seh-rt_v10-rev0.7z`解压到msys2的根目录

   2. 下载cmake：https://github.com/Kitware/CMake/releases/download/v3.26.3/cmake-3.26.3-windows-x86_64.zip

      将`cmake-3.26.3-windows-x86_64.zip`解压，将`cmake-3.26.3-windows-x86_64`目录下的所有文件夹拷贝到`msys2/usr/`目录

      将 msys2\mingw64\bin目录下的 mingw32-make.exe 复制一份改成 make.exe

   3. 下载安装DevecoStuido

      DevecoStuido：https://developer.huawei.com/consumer/cn/download/

      修改build-ohos.sh中的路径。ohos环境在DevEco Studio安装目录下sdk -> HarmonyOS-NEXT-DB3（有可能是DB2其他内容） -> openharmony下面

   4. 仓颉交叉编译环境

      修改cjpm.toml中${DEVECO_CANGJIE_HOME}变量。一般DevecoStuido安装仓颉插件之后仓颉SDK在C盘用户目录.cangjie-sdk下面。

   5. 用mingw64进入项目根目录，执行`build-ohos.sh`

      ```shell
      ./build-ohos.sh
      ```

### 功能示例

#### 生成bitmap功能示例

功能示例描述:

示例代码如下：

```cangjie
import formula.*
import std.fs.*

main(): Int64 {

    var latex = LaTeX("res")
    var str = ###"
\sideset{^\backprime}{'}\sum_{x=1}^{\infty} x\sideset{a_1^2}{}\sum_{x=1}^\infty x_0
\\
\sideset{_\text{left bottom}'''}{_{\text{right bottom}}'''}\sum_{\text{quite long text}}^\infty x
\\
\sideset{}{'}
\sum_{n<k,\;\text{$n$ odd}} nE_n
\\
\sideset{}{'}
\sum^{n<k,\;\text{$n$ odd}} nE_n
\\
M_x''' M'''_x M^{'''}_x M_x{'''} M^{\prime\backprime}
"###
    var r = latex.parse(str, 2000, 40.0, 10.0, 0xFF000000)
    var w = r.getWidth()
    var h = r.getHeight()
    var g2 = Graphic2D(r, COLOR_FORMAT_RGB_565)
    r.draw(g2, 0xFFFFFFFF)

    var arr = r.toBitmap(g2)

    var file: File = File("test.bmp", OpenOption.CreateOrTruncate(false))
    file.write(arr)
    file.close()

    return 0
}
```

执行结果如下：

![test](./doc/assets/test.bmp)

## 约束与限制

只适用ohos环境

## 开源协议

本项目基于 [MIT License](./LICENSE)，请自由的享受和参与开源。

## 参与贡献

欢迎给我们提交PR，欢迎给我们提交Issue，欢迎参与任何形式的贡献。

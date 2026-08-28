# OpenCV + C++ 环境配置教程（Windows · VS Code · MinGW）

> 一个**从零到能跑**的完整教程：在 Windows 上配好 C++ 编译器 → 编译 OpenCV → 用 VS Code 写代码、一键编译、调试、运行。
> 教程中的所有步骤**都可在你自己的电脑上逐步复现**，每一步都给了"如何确认成功"的方法。

---

## ⚡ 快速开始（新手一键版 · 先做这个）

适合：电脑上**什么都没有、只装了 VS Code** 的纯新手。照着做，最快 5~15 分钟就能跑起来。

**第 0 步：装 VS Code 和 C/C++ 插件（只做一次）**
1. 下载安装 VS Code：<https://code.visualstudio.com>
2. 打开 VS Code → 左侧「扩展」图标 → 搜索 `C/C++` → 安装（作者 **Microsoft**）

**第 1 步：拿到本教程的文件夹**
- 方式 A：GitHub 上这个仓库点 **Code → Download ZIP**，解压
- 方式 B（有 Git 的话）：`git clone <仓库地址>`

**第 2 步：双击一键脚本 `setup.bat`**
> 脚本会**全自动**做四件事，每步会打印进度：
> 1. 检测 g++ / cmake / git，缺的用 Windows 自带的 **winget** 自动安装
> 2. 找 OpenCV（MinGW 版）：没有就自动下载 OpenCV 4.13 源码并编译安装
>    （首次约 30~60 分钟，**只需做一次**；已有就直接复用）
> 3. 自动把 `.vscode` 里的配置改成你电脑的路径
> 4. 自动编译 3 个示例程序
>
> 看到 **`[OK] 示例已全部编译成功`** 就说明环境 OK 了！
> 如果双击没反应或被拦截，也可以打开 PowerShell 手动执行：
> ```powershell
> powershell -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1
> ```

**第 3 步：在 VS Code 里运行你的第一个程序**
1. VS Code → 文件 → 打开文件夹 → 选择这个文件夹
2. 打开 `src/01_display_image.cpp`
3. 菜单「终端 → 新建终端」，输入：
   ```powershell
   .\build\01_display_image.exe
   ```
   会弹出一个窗口显示测试图 → **按任意键关闭** ✅
4. 以后写代码：`Ctrl+Shift+B` 一键编译，`F5` 调试

> 💡 想弄懂"每一步到底装了什么、为什么"，往下看 **1~11 节**的手动详细版。

---

## 目录

0. [快速开始（新手一键版）](#-快速开始新手一键版--先做这个)
1. [这套教程让你学会什么](#1-这套教程让你学会什么)
2. [整体原理（先看懂再动手）](#2-整体原理先看懂再动手)
3. [第一步：安装工具链（只做一次）](#3-第一步安装工具链只做一次)
4. [第二步：获得 OpenCV](#4-第二步获得-opencv)
5. [第三步：编译 OpenCV（MinGW 版）](#5-第三步编译-opencvmingw-版)
6. [第四步：编译并运行本仓库示例](#6-第四步编译并运行本仓库示例)
7. [第五步：VS Code 日常使用](#7-第五步vscode-日常使用)
8. [验证清单](#8-验证清单)
9. [常见问题 FAQ](#9-常见问题-faq)
10. [上传到 GitHub / Gitee 给别人用](#10-上传到-github--gitee-给别人用)
11. [仓库目录结构](#11-仓库目录结构)

---

## 1. 这套教程让你学会什么

- ✅ 看懂 **C++ → 可执行程序** 的完整链路（源码 → 编译 → 链接 → 运行）
- ✅ 在 Windows 上安装并验证 **MinGW-w64 编译器 + CMake**
- ✅ 理解 **预编译 OpenCV** 与 **从源码编译 OpenCV** 的区别与选择
- ✅ 亲手把 OpenCV 编译出一套 **MinGW 可用的库**
- ✅ 用 VS Code 配置好 **智能提示 / 一键编译 / 调试**
- ✅ 运行 3 个示例程序（读图显示 / 灰度转换 / 摄像头）
- ✅ 把这个环境做成**可上传 GitHub、别人可复现**的工程

---

## 2. 整体原理（先看懂再动手）

### 2.1 C++ 程序是怎么跑起来的

```
你的源码 main.cpp
      │  ① 编译 (g++ / cl)      —— 把代码翻译成机器指令
      ▼
   目标文件 main.obj
      │  ② 链接 (ld)            —— 把目标文件 + 库打包成程序
      ▼
   可执行程序 main.exe
      │  ③ 运行                 —— 系统加载 exe + 它依赖的 .dll
      ▼
   看到结果
```

**关键点**：
- **编译**：把 C++ 源码变成机器码（`.obj`）。
- **链接**：把目标文件和我们用到的**库**（比如 OpenCV）合并成 exe。
- **运行**：exe 运行时还要用到一些**动态库（DLL）**，系统找不到就会报"找不到 xxx.dll"。

### 2.2 什么是 OpenCV？为什么它不是一个文件？

OpenCV 是一大套图像/视频处理**函数库**（读图、滤波、人脸识别、摄像头采集……）。
它"安装"到你的电脑上之后，其实是这样一堆东西：

```
OpenCV 安装目录/
├── include/     ← 头文件（.hpp）：告诉编译器"有哪些函数可以用"
├── lib/         ← 链接库（.a/.lib）：链接阶段告诉链接器函数在哪
└── bin/         ← 动态库（.dll）：运行阶段真正被加载的代码
```

写代码 → 看 `include/`（智能提示）；编译 → 用 `lib/`（链接）；运行 → 靠 `bin/`（加载 DLL）。**三者缺一不可**，教程里会一一对应。

### 2.3 预编译版 vs 源码编译版（重要！）

Windows 上 OpenCV 有两种拿法：

| | 官方预编译版 | 从源码编译 |
|---|---|---|
| 获取 | 官网下载 `opencv-xxx-windows.exe` | 下载源码，自己用 CMake 编译 |
| 配套编译器 | **只能配 MSVC（Visual Studio）** | 想配什么配什么（本教程用 MinGW g++） |
| 难度 | 简单 | 中等（但一劳永逸，还能裁剪模块） |
| 优点 | 下载即用 | 免费、跨编译器、可裁剪、懂原理 |
| 缺点 | 体积大、绑定 MSVC | 首次编译 30~60 分钟 |

> ⚠️ **最常见的坑**：官网下载的预编译 OpenCV 是 **MSVC 专用**的（目录名如 `vc15/vc16`）。
> 如果你的编译器是 **MinGW g++**，链接时会报一堆莫名其妙的错。
> **本仓库采用「源码编译」，就是为了让 MinGW 用户也能用上 OpenCV。**

---

## 3. 第一步：安装工具链（只做一次）

> 💡 如果你已经用了上面的「快速开始」，工具链已被脚本自动装好，本节**可以直接跳过**。
> 以下是给想手动安装/想搞懂原理的同学看的。

### 3.1 MinGW-w64 编译器（C/C++ 编译器本体）

- 推荐下载 [winlibs.com](https://winlibs.com/) 的 **UCRT runtime + POSIX threads + SEH** 版本（解压即用，无需安装）
- 解压后记住路径，比如 `C:\mingw64`
- **把 `C:\mingw64\bin` 加进系统环境变量 PATH**：
  - 按 `Win` → 搜"环境变量" → 编辑系统环境变量 → 环境变量 → 双击 `Path` → 新建 → 粘贴 `C:\mingw64\bin`
- **验证**（新开一个终端）：
  ```bat
  g++ --version
  ```
  能看到类似 `g++.exe (x86_64-posix-seh-rev0, Built by MinGW-W64 project) 8.1.0` 即成功。

> 💡 如果 `g++` 找不到，说明 PATH 没配好或没重开终端。

### 3.2 CMake（构建工具：管理"编译哪些文件、怎么链接"）

- 官网下载安装：[cmake.org/download](https://cmake.org/download/)（选 Windows x64 Installer）
- 安装时勾选 **Add CMake to the system PATH**（这样终端能直接用 `cmake`）
- **验证**：
  ```bat
  cmake --version
  ```

### 3.3 Git（版本管理 / 从 GitHub 拉代码）

- 官网：[git-scm.com/download/win](https://git-scm.com/download/win)，一路下一步
- **验证**：
  ```bat
  git --version
  ```

### 3.4 VS Code 与 C/C++ 扩展

- VS Code：[code.visualstudio.com](https://code.visualstudio.com/)
- 在 VS Code 扩展商店安装 **C/C++**（作者 Microsoft，标识 `ms-vscode.cpptools`）
- 它会提供：语法高亮、代码补全（IntelliSense）、调试器支持

---

## 4. 第二步：获得 OpenCV

### 4.1 选择源码版本

- 本教程使用 **OpenCV 4.13.0**（较新的稳定版）
- 源码获取方式（二选一）：

**方式 A：从 GitHub 下载源码压缩包（推荐）**
```
https://github.com/opencv/opencv/archive/refs/tags/4.13.0.zip
```
解压到某个目录，例如 `C:\dev\opencv\opencv\sources`
（里面应能看到 `modules/`、`CMakeLists.txt` 等）

**方式 B：git clone**
```bat
git clone --branch 4.13.0 https://github.com/opencv/opencv.git C:\dev\opencv\opencv\sources
```

> 💡 也可以直接下载官方 Windows 包（`opencv-4.13.0-windows.exe`），解压后**自带 `sources/` 完整源码**，同样可以用来编译 MinGW 版。

### 4.2 本仓库使用的目录约定

| 内容 | 路径 |
|---|---|
| OpenCV 源码 | `C:\dev\opencv\opencv\sources` |
| 编译目录（产物） | `C:\dev\opencv\opencv\build_mingw` |
| 最终安装目录 | `C:\dev\opencv\opencv\build_mingw\install` |

> 编译目录和安装目录**不要放进 git 仓库**（体积巨大，见 [第 10 节](#10-上传到-github-给别人用)）。

---

## 5. 第三步：编译 OpenCV（MinGW 版）

> 这一步是整个教程里最花时间的一步（30~60 分钟，取决于 CPU），**只需要做一次**。

### 5.1 配置（CMake Configure）

在**任意终端**执行（路径换成你自己的）：

```bat
cmake -S C:\dev\opencv\opencv\sources ^
      -B C:\dev\opencv\opencv\build_mingw ^
      -G "MinGW Makefiles" ^
      -DCMAKE_MAKE_PROGRAM=C:/mingw64/bin/mingw32-make.exe ^
      -DCMAKE_C_COMPILER=gcc ^
      -DCMAKE_CXX_COMPILER=g++ ^
      -DCMAKE_BUILD_TYPE=Release ^
      -DBUILD_SHARED_LIBS=ON ^
      -DBUILD_opencv_world=ON ^
      -DBUILD_EXAMPLES=OFF ^
      -DBUILD_TESTS=OFF ^
      -DBUILD_PERF_TESTS=OFF ^
      -DBUILD_opencv_python2=OFF ^
      -DBUILD_opencv_python3=OFF ^
      -DWITH_FFMPEG=OFF ^
      -DWITH_OPENCL=OFF ^
      "-DBUILD_LIST=core,imgproc,imgcodecs,highgui,videoio,flann,features2d,calib3d,objdetect,photo" ^
      -DCMAKE_INSTALL_PREFIX=C:/dev/opencv/opencv/build_mingw/install
```

**这些选项是什么意思**（新手挑重点看）：

| 选项 | 含义 |
|---|---|
| `-G "MinGW Makefiles"` | 用 MinGW 的 make 来驱动编译（配合 g++） |
| `-DCMAKE_CXX_COMPILER=g++` | 指定 C++ 编译器为 MinGW 的 g++ |
| `-DBUILD_SHARED_LIBS=ON` | 编译成 DLL（动态库），比静态库好上手 |
| `-DBUILD_opencv_world=ON` | 把所有模块合成**一个** `opencv_world` 库，链接时只写一个库名 |
| `-DBUILD_LIST=core,imgproc,...` | **只编译这些模块**，大幅缩短编译时间（本仓库示例用到的） |
| `-DWITH_FFMPEG=OFF` | 跳过 FFmpeg（本教程不需要读视频文件，摄像头用 DirectShow） |
| `-DCMAKE_INSTALL_PREFIX=...` | 指定最终"安装"位置 |

**如何确认成功**：终端最后几行应出现
```
Configuring done
Generating done
Build files have been written to: C:/dev/opencv/opencv/build_mingw
```
且 `build_mingw/` 里出现 `Makefile`、`CMakeCache.txt`。

### 5.2 编译（Build）

```bat
cmake --build C:\dev\opencv\opencv\build_mingw -j 8
```
- `-j 8` 表示 8 个任务并行（改成你 CPU 核数，如 `-j 16`）
- 期间能看到大量 `[ xx%] Building CXX object ...` 的进度
- **如何确认成功**：最后出现 `Built target opencv_world` 之类的字样，无 `error`。

### 5.3 安装（Install，把库整理到 install 目录）

```bat
cmake --install C:\dev\opencv\opencv\build_mingw
```

**如何确认成功**：`install/` 下应有：
```
install/
├── include/          ← 头文件
└── x64/mingw/
    ├── lib/          ← 链接库（libopencv_world4130.dll.a 等）+ OpenCVConfig.cmake
    └── bin/          ← DLL（libopencv_world4130.dll 等）
```

> 💡 **注意**：MinGW 生成器把库装到 `install/x64/mingw/` 子目录。
> `find_package` 要找的 `OpenCVConfig.cmake` 在 **`x64/mingw/lib`** 里，
> 所以后面所有 `-DOpenCV_DIR` 都要指向 `.../install/x64/mingw/lib`。

### 5.4 快速自检

```bat
C:\dev\opencv\opencv\build_mingw\install\x64\mingw\bin\opencv_version.exe
```
能打印出 `4.13.0` 就说明整套 OpenCV 编译成功 ✅

---

## 6. 第四步：编译并运行本仓库示例

### 6.1 克隆本仓库

```bat
git clone <你的仓库地址> opencv
cd opencv
```
> 也可以直接把整个文件夹下载下来用。

### 6.2 配置 + 编译

```bat
cmake -S . -B build -G "MinGW Makefiles" ^
      -DCMAKE_MAKE_PROGRAM=C:/mingw64/bin/mingw32-make.exe ^
      -DCMAKE_BUILD_TYPE=Release ^
      -DOpenCV_DIR=C:/dev/opencv/opencv/build_mingw/install/x64/mingw/lib

cmake --build build -j 8
```

> ⚠️ **`-DOpenCV_DIR` 要指向你 OpenCV 的 `x64/mingw/lib` 目录**（里面要有 `OpenCVConfig.cmake`），
> 这是告诉 CMake"去这里找 OpenCV"的关键。路径错了会报
> `Could not find a package configuration file provided by OpenCV`。

**如何确认成功**：`build/` 下出现三个 exe：
```
build/01_display_image.exe
build/02_grayscale.exe
build/03_camera.exe
```
同时每个 exe 旁边自动复制了 `opencv_world413.dll` 和 MinGW 运行时 DLL（这是 `CMakeLists.txt` 里的 POST_BUILD 步骤干的）。

### 6.3 运行示例

在项目根目录执行（注意：图片路径默认相对 `images/`）：

```bat
build\01_display_image.exe        # 弹出窗口显示测试图，按任意键关闭
build\02_grayscale.exe            # 生成 result_gray.png 灰度图
build\03_camera.exe               # 打开摄像头实时画面，按 q 退出
```

- **01**：应弹出一个窗口，显示一张渐变测试图，控制台打印图片尺寸。
- **02**：应在项目根目录生成 `result_gray.png`（灰色版测试图）。
- **03**：应弹出摄像头画面窗口（需要电脑有摄像头/USB 摄像头），按 `q` 退出。

---

## 7. 第五步：VS Code 日常使用

### 7.1 打开项目

VS Code → `文件` → `打开文件夹` → 选择本仓库目录（含 `CMakeLists.txt` 的那个）。

### 7.2 智能提示（代码补全）

- 打开任意 `src/*.cpp`，把鼠标放到 `cv::imread` 上应能弹出说明。
- 如果没反应：看右下角是否提示选择编译器，或在命令面板（`Ctrl+Shift+P`）执行
  `C/C++: 选择 IntelliSense 配置` → 选 `Win32 (MinGW + OpenCV)`。
- 配置在 `.vscode/c_cpp_properties.json`，**路径要改成你自己的**：
  - `mingwBin` → 你的 MinGW 路径
  - `opencvInstall` → 你的 OpenCV install 目录

### 7.3 一键编译

- 按 `Ctrl+Shift+B` → 自动配置 + 编译，产物在 `build/`。
- 配置在 `.vscode/tasks.json`，同样要把 `OpenCV_DIR` 改成你自己的。

### 7.4 调试

- 打开 `src/01_display_image.cpp`，在代码左侧点行号**打断点**，按 `F5`。
- 会先自动编译，再用 gdb 启动调试，可单步、看变量。
- 想调试别的示例：改 `.vscode/launch.json` 里 `program` 的 exe 名。

### 7.5 手动在终端跑

```bat
# 在项目根目录
cmake --build build -j 8
.\build\01_display_image.exe
```

---

## 8. 验证清单

| 检查项 | 命令 | 预期结果 |
|---|---|---|
| 编译器 | `g++ --version` | 打印 MinGW g++ 版本 |
| 构建工具 | `cmake --version` | 打印 CMake 版本 |
| 版本管理 | `git --version` | 打印 Git 版本 |
| OpenCV 库 | `install\x64\mingw\bin\opencv_version.exe` | 打印 `4.13.0` |
| 示例编译 | `cmake --build build -j 8` | 生成 3 个 exe，无 error |
| 示例 1 | `build\01_display_image.exe` | 弹窗显示测试图 |
| 示例 2 | `build\02_grayscale.exe` | 生成 `result_gray.png` |
| 示例 3 | `build\03_camera.exe` | 摄像头画面，按 q 退出 |

---

## 9. 常见问题 FAQ

> 💡 以下 **Q0~Q2 是"全新电脑第一次跑脚本"最容易遇到的 3 个坑**，都是历史踩坑后已修复的。
> 如果你 clone 的仓库是**旧版**，请先更新到最新再试。

**Q0：双击 setup.bat 弹出一堆乱码 / "×× 不是内部或外部命令，也不是可运行的程序"**
现象：窗口里出现 `'疆'不是内部或外部命令`、`'++'不是内部或外部命令` 等乱码报错。
原因：旧版 `setup.bat` 里带中文，而 cmd 用系统 ANSI 码页（中文 Windows = GBK）解析批处理文件，
      UTF-8 的中文被读成乱码后，命令被切断导致报错。
解决：
- ✅ 新版脚本已把 `setup.bat` 改成**纯英文**，任何系统都不会再乱码，直接更新仓库重下即可；
- 若你手上还是旧版：把 `setup.bat` 里的中文提示全删掉（只保留 ASCII），或用 VS Code 以 **GBK 编码**另存。

**Q1：报错"找不到与参数名称 and 匹配的参数"**
现象：跑到"解压源码…"后报 `setup.ps1：找不到与参数名称"and"匹配的参数`。
原因：旧版脚本有一行 `Test-Path xxx -and -not (...) `——在 **Windows PowerShell 5.1** 里，
      cmdlet 后面直接跟 `-and` 会被当成参数名解析而报错。这行只在"本机没有现成 OpenCV、
      需要解压源码"时才会执行，所以有环境的机器测不出来。
解决：
- ✅ 新版已改为 `(Test-Path xxx) -and (-not (...))`（加括号），已修复，更新仓库即可；
- 遇到时也可把源码手动放进 `C:\dev\opencv\opencv\sources`（含 `CMakeLists.txt`），脚本会自动复用跳过下载解压。

**Q2：下载 OpenCV 源码失败 / 卡住 / 超时（国内网络常见）**
现象：卡在"下载 OpenCV 4.13.0 源码"很久，或提示下载失败。
原因：脚本默认从 **GitHub** 下载约 100MB 源码，国内网络访问 GitHub 经常很慢或超时。
解决：
- ✅ 新版脚本会**自动依次尝试**：GitHub 官方 → **Gitee 镜像**（国内快）→ Gitee 备用格式，一般能自动成功；
- 若仍失败：手动到 `https://gitee.com/mirrors/opencv` 下载 4.13.0 的 zip，
  解压后把内容放进 `C:\dev\opencv\opencv\sources`（要包含 `CMakeLists.txt`），再重跑脚本。

**Q3：运行 exe 报"找不到 opencv_world413.dll"**
原因：exe 找不到动态库。
解决：
- 本仓库的 CMakeLists 会自动把 DLL 复制到 exe 旁边，若还报错，手动把
  `install\x64\mingw\bin\*.dll` 复制到 `build\` 下；
- 或临时加 PATH：`set PATH=C:\dev\opencv\opencv\build_mingw\install\x64\mingw\bin;%PATH%` 再运行。

**Q4：用官方预编译 OpenCV + MinGW 报一堆链接错误**
原因：官方预编译是 MSVC 版，ABI 不兼容 MinGW。
解决：用本教程"源码编译"方式生成 MinGW 版；或改用 Visual Studio（MSVC）。

**Q5：`g++` 不是内部或外部命令**
原因：MinGW 的 `bin` 没加进 PATH，或没重开终端。
解决：检查环境变量 `Path`，重开终端。

**Q6：摄像头打不开（`无法打开摄像头`）**
可能原因：
- 摄像头被其他软件（微信/Teams）占用 → 关掉再试；
- 设备号不是 0 → 把代码里的 `VideoCapture(0)` 改成 `1` 或 `2`；
- 笔记本需在系统设置里允许应用使用摄像头。

**Q7：终端中文乱码**
Windows 控制台默认 GBK。两种办法：
- 在 VS Code 里运行（VS Code 终端默认 UTF-8）；
- 或在控制台执行 `chcp 65001` 切到 UTF-8。

**Q8：每次改 OpenCV 都要重新编译吗？**
不用。OpenCV 编译一次即可，之后你的示例项目只是**链接**它。

**Q9：编译很慢怎么办？**
- 用 `-j` 加大并行数（CPU 核数）；
- 缩小 `BUILD_LIST`（只留需要的模块）；
- 只编译一次，之后就快了。

---

## 10. 上传到 GitHub / Gitee 给别人用

你的仓库**只应该包含源码和配置**，不要包含编译产物（几百 MB ~ 几 GB）。
本仓库 `.gitignore` 已把 `build/`、`*.exe`、`*.dll`、`result_*.png` 排除，放心 `git add .`。

**核心概念**：一个仓库可以同时挂多个「远程」（remote），推 GitHub 和推 Gitee 互不影响。

```bat
# 1. 本地初始化 + 提交（只做一次）
git init
git add .
git commit -m "OpenCV + C++ 入门示例（MinGW 版）"

# 2a. 推送到 GitHub
#     在 github.com 新建空仓库（不要勾选 README/.gitignore），拿到地址后：
git remote add origin https://github.com/<用户名>/<仓库名>.git
git push -u origin main

# 2b. 推送到 Gitee（码云）
#     在 gitee.com 新建空仓库（不要勾选 README/.gitignore），拿到地址后：
git remote add gitee https://gitee.com/<用户名>/<仓库名>.git
git push -u gitee main
```

以后每次改完代码，两个平台各推一次（首次可能要输入账号密码/私人令牌）：

```bat
git push origin main     # 推 GitHub
git push gitee main      # 推 Gitee
```

**别人拿到之后**：
1. 装好工具链（第 3 节）并编译好 OpenCV（第 5 节）；**或直接双击 `setup.bat` 一键搞定**；
2. 跑一次脚本（或手动把 `.vscode/tasks.json`、`c_cpp_properties.json` 里的路径改成自己的）；
3. 按第 6 节编译运行即可。

> 💡 国内同学访问 GitHub 可能较慢，用 **Gitee 镜像**更顺。两边代码保持一致即可。

---

## 11. 仓库目录结构

```
opencv/
├── CMakeLists.txt            # 示例项目的构建脚本（含自动复制 DLL 步骤）
├── README.md                 # 本教程
├── setup.bat                 # 一键脚本入口（双击它）
├── setup.ps1                 # 一键脚本本体（自动装工具链/OpenCV、写配置）
├── .gitignore                # 排除编译产物
├── .vscode/
│   ├── c_cpp_properties.json # 智能提示配置（改路径）
│   ├── tasks.json            # Ctrl+Shift+B 一键编译（改路径）
│   └── launch.json           # F5 调试配置
├── images/
│   └── test_image.png        # 示例 1/2 用的测试图
└── src/
    ├── 01_display_image.cpp  # 读图 + 显示
    ├── 02_grayscale.cpp      # 彩色转灰度 + 保存
    └── 03_camera.cpp         # 摄像头实时画面
```

**不在仓库里**（本地生成）：
- `build/`：示例项目的编译产物
- OpenCV 的 `sources/`、`build_mingw/`：体积巨大，各自在本机独立存在

---

## 附：这套环境的"为什么"

- **为什么用 MinGW 而不是 MSVC？** 免费、开源、命令行友好，配 VS Code 最顺，本教程围绕它展开。
- **为什么编译 OpenCV？** 官方预编译只支持 MSVC；MinGW 用户想用 OpenCV 就必须自己编译（或装 MSYS2 的包）。
- **为什么用 CMake？** 跨编译器、自动处理 include/lib 路径，比手写 `g++ -I... -L...` 可靠得多，也是 OpenCV 官方推荐的构建方式。
- **为什么 opencv_world？** 把所有模块合成一个库，新手链接时只写 `-lopencv_world413`，不用记十几个库名。

祝学习愉快！如果卡在某个步骤，对照 [FAQ](#9-常见问题-faq) 或查看编译日志里的具体报错。

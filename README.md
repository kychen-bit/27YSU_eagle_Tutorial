# OpenCV + C++ 环境配置教程（Windows · VS Code · MinGW）

> 一个**从零到能跑**的完整教程：在 Windows 上配好 C++ 编译器 → 编译 OpenCV → 用 VS Code 写代码、一键编译、调试、运行。
> 教程中的所有步骤**都可在你自己的电脑上逐步复现**，每一步都给了"如何确认成功"的方法。

---

## ⚡ 快速开始（新手一键版 · 先做这个）

适合：电脑上**什么都没有、只装了 VS Code** 的纯新手。照着做，最快 5~15 分钟就能跑起来。

**第 0 步：装 VS Code 和 C/C++ 插件（只做一次）**

1. 下载安装 VS Code：[https://code.visualstudio.com](https://code.visualstudio.com)
2. 打开 VS Code → 左侧「扩展」图标 → 搜索 `C/C++` → 安装（作者 **Microsoft**）

**第 1 步：拿到本教程的文件夹**

- 方式 A：GitHub 上这个仓库点 **Code → Download ZIP**，解压
- 方式 B（有 Git 的话）：`git clone <仓库地址>`

**第 2 步：双击一键脚本 `setup.bat`**

> 脚本会**全自动**做四件事，每步会打印进度：
>
> 1. 检测 g++ / cmake / git，缺的用 Windows 自带的 **winget** 自动安装
> 2. 找 OpenCV（MinGW 版）：没有就自动下载 OpenCV 4.13 源码并编译安装
>    （首次约 30~60 分钟，**只需做一次**；已有就直接复用）
> 3. 自动把 `.vscode` 里的配置改成你电脑的路径
> 4. 自动编译 3 个示例程序
>
> 看到 **`[OK] 示例已全部编译成功`** 就说明环境 OK 了！
> 如果双击没反应或被拦截，也可以打开 PowerShell 手动执行：
>
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

   会弹出一个窗口显示测试图 → **先点击图片窗口**（让它获得焦点），再按任意键关闭 ✅
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

|            | 官方预编译版                           | 从源码编译                           |
| ---------- | -------------------------------------- | ------------------------------------ |
| 获取       | 官网下载 `opencv-xxx-windows.exe`    | 下载源码，自己用 CMake 编译          |
| 配套编译器 | **只能配 MSVC（Visual Studio）** | 想配什么配什么（本教程用 MinGW g++） |
| 难度       | 简单                                   | 中等（但一劳永逸，还能裁剪模块）     |
| 优点       | 下载即用                               | 免费、跨编译器、可裁剪、懂原理       |
| 缺点       | 体积大、绑定 MSVC                      | 首次编译 30~60 分钟                  |

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

| 内容             | 路径                                         |
| ---------------- | -------------------------------------------- |
| OpenCV 源码      | `C:\dev\opencv\opencv\sources`             |
| 编译目录（产物） | `C:\dev\opencv\opencv\build_mingw`         |
| 最终安装目录     | `C:\dev\opencv\opencv\build_mingw\install` |

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

| 选项                              | 含义                                                                 |
| --------------------------------- | -------------------------------------------------------------------- |
| `-G "MinGW Makefiles"`          | 用 MinGW 的 make 来驱动编译（配合 g++）                              |
| `-DCMAKE_CXX_COMPILER=g++`      | 指定 C++ 编译器为 MinGW 的 g++                                       |
| `-DBUILD_SHARED_LIBS=ON`        | 编译成 DLL（动态库），比静态库好上手                                 |
| `-DBUILD_opencv_world=ON`       | 把所有模块合成**一个** `opencv_world` 库，链接时只写一个库名 |
| `-DBUILD_LIST=core,imgproc,...` | **只编译这些模块**，大幅缩短编译时间（本仓库示例用到的）       |
| `-DWITH_FFMPEG=OFF`             | 跳过 FFmpeg（本教程不需要读视频文件，摄像头用 DirectShow）           |
| `-DCMAKE_INSTALL_PREFIX=...`    | 指定最终"安装"位置                                                   |

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

> 🧭 **先搞懂两套东西，别搞混（新手 80% 的困惑都在这）**：
>
> | 目录 | 是什么 | 在不在你的 git 仓库 | 什么时候用 |
> |---|---|---|---|
> | `C:\dev\opencv\opencv\sources` | **OpenCV 源码**（下载来的别人的代码） | 不在 | 只在第一次编译 OpenCV 时用（第 5 节） |
> | `C:\dev\opencv\opencv\build_mingw` | **OpenCV 库的编译产物**（含 `install\`） | 不在 | 只在第一次编译 OpenCV 时用；编好就不用再碰 |
> | 你的仓库根目录（有 `CMakeLists.txt`） | **你的示例项目** | ✅ 在 | 日常开发全在这 |
> | 你仓库下的 `build\` | **你示例项目的产物**（exe/dll） | 不在（`.gitignore` 已排除） | 每次改代码在这编译 |
>
> ❓ **那 `cmake --build C:\dev\opencv\opencv\build_mingw -j 8` 是干嘛的？**
> 那是**编译 OpenCV 库本身**（第 5 节），**只需做一次**，产物是 OpenCV 的 `libopencv_world4130.dll`
> 等库文件，**不是**你的示例 exe。你日常编译示例用的命令是 `cmake --build build`（在**你项目根目录**），
> 产物是 `build\01_display_image.exe` 等。
>
> ❓ **别人 clone 你的仓库后有这些文件吗？**
> 没有。`C:\dev\opencv\...` 体积巨大（几百 MB），**不进 git 仓库**。别人拿到你仓库后，
> 需要自己先拿到 OpenCV——方法见 [第 10.1 节](#101-给同学分发编译好的-install跳过-3060-分钟编译)：
> 要么跑 `setup.bat` 自动编译（30~60 分钟），要么找你要一份编译好的 `install` 文件夹（约 20MB zip），
> 再把自己电脑上的 OpenCV 路径填进第 6.2 命令和 `.vscode` 三个配置文件里。

### 6.1 克隆本仓库

```bat
git clone <你的仓库地址> opencv
cd opencv
```

> 也可以直接把整个文件夹下载下来用。

### 6.2 方法一：命令行编译（手把手 · 每条命令都标了「在哪个目录」）

> 📍 **先记一条铁律**：下面所有命令都必须在**【项目根目录】**执行——就是有 `CMakeLists.txt` 的那个文件夹
> （例如 `C:\Users\你\...\opencv`）。**不要** `cd build` 进去再敲命令。

**第 1 步：配置**（只在第一次、或删过 `build/` 之后做一次；成功后会生成 `build/`）

【项目根目录】执行，任选一种你终端能用的写法：

写法 A —— cmd（`^` 是换行符，多行版）：

```bat
cmake -S . -B build -G Ninja ^
      -DCMAKE_MAKE_PROGRAM=<你的项目绝对路径>/tools/ninja.exe ^
      -DCMAKE_CXX_COMPILER=C:/mingw64/bin/g++.exe ^
      -DCMAKE_BUILD_TYPE=Release ^
      -DOpenCV_DIR=C:/dev/opencv/opencv/build_mingw/install/x64/mingw/lib
```

写法 B —— PowerShell（**推荐**：一整行直接复制粘贴回车，最不容易出错）：

```powershell
cmake -S . -B build -G Ninja '-DCMAKE_MAKE_PROGRAM=<你的项目绝对路径>/tools/ninja.exe' '-DCMAKE_CXX_COMPILER=C:/mingw64/bin/g++.exe' '-DCMAKE_BUILD_TYPE=Release' '-DOpenCV_DIR=C:/dev/opencv/opencv/build_mingw/install/x64/mingw/lib'
```

> ⚠️ 这一整段是**一行命令**，直接复制粘贴回车即可。**别**自己拆成多行，也别只复制后半段
> （多行粘贴很容易丢第一行，报"意外的标记"；详见 FAQ Q16）。

> 这些参数是什么意思（新手知道大概即可）：
>
> | 参数                                                | 含义                                                          |
> | --------------------------------------------------- | ------------------------------------------------------------- |
> | `-S . -B build`                                   | 源码在当前目录，编译产物放 `build/`                         |
> | `-G Ninja`                                        | 用 Ninja 生成器（仓库自带 `tools/ninja.exe`，支持中文路径） |
> | `-DCMAKE_MAKE_PROGRAM=<绝对路径>/tools/ninja.exe` | 指定构建工具 ninja（**要绝对路径**）                    |
> | `-DCMAKE_CXX_COMPILER=C:/mingw64/bin/g++.exe`     | 指定编译器为 MinGW 的 g++                                     |
> | `-DCMAKE_BUILD_TYPE=Release`                      | 发布版（开了优化）                                            |
> | `-DOpenCV_DIR=.../x64/mingw/lib`                  | 告诉 CMake 到哪找 OpenCV（`OpenCVConfig.cmake` 在那里）     |

**第 2 步：编译**（每次改完代码都执行这一条）

【项目根目录】执行：

```bat
cmake --build build -j
```

> ⚠️ 前提是**第 1 步配置成功过**（生成了 `build/CMakeCache.txt`）。如果报
> `Error: could not load cache`，说明 `build/` 里没有缓存（刚克隆/刚删过 build），
> **先回去执行第 1 步的配置命令，再回来编译**（见 FAQ Q16）。

→ 产物就在你【项目根目录】的 `build\` 里：`build\01_display_image.exe`、`build\02_grayscale.exe`、`build\03_camera.exe`。
（注意：`build` 后面**不要**跟 `C:\dev\...` 那一大串——那是编译 OpenCV 本身用的，跟你的示例无关，见 6.0 节的表格。）

**第 3 步：运行**（想传命令行参数就加在 exe 后面，见 6.4）

【项目根目录】执行：

```bat
build\01_display_image.exe
build\02_grayscale.exe
build\03_camera.exe
```

（01/02 弹出图片窗口后，先**点击图片窗口**再按任意键才能关闭，见 FAQ Q15。）

**如何确认成功**：`build/` 下出现 3 个 exe，且每个 exe 旁边已自动复制
`libopencv_world4130.dll` 和 MinGW 运行时 DLL（CMakeLists.txt 自动干的，不用手动拷贝）。

> ⚠️⚠️ **两个最容易踩的坑（都是真实踩过的，别再踩）**：
>
> **坑 1：不要"裸跑 `cmake ..`"！** Windows 上 CMake 默认会用 **Visual Studio** 生成器
> （终端会打印 `Building for: Visual Studio 17 2022`），而我们这份 OpenCV 是 **MinGW 编译**的，
> VS 不兼容也找不到它，于是报错。**删过 `build/` 之后必须用上面第 1 步的完整命令**（或 `Ctrl+Shift+B`）。
> 若曾裸跑过 `cmake ..` 失败，`build/` 里会残留 VS 缓存，导致 `Ctrl+Shift+B` 也失败——
> 这时**把 `build/` 整个删掉**再重新配置即可。
>
> **坑 2：PowerShell 5.1 会把 `-D...=...exe` 的 `.exe` 拆掉。** 实测：
> PowerShell 传 `-DCMAKE_MAKE_PROGRAM=tools/ninja.exe` 会变成 `tools/ninja` + `.exe`，
> cmake 找不到 ninja 就报错。所以 PowerShell 里 `-D` 的值**必须加引号**（如 `'-D...=...'`）。
> cmd 没有这个问题。

### 6.3 方法二：VS Code 图形操作（新手推荐，基本不用敲命令）

1. **打开项目**：VS Code → `文件` → `打开文件夹` → 选中本仓库目录（含 `CMakeLists.txt` 的那个）。
2. **一键编译**：按 `Ctrl+Shift+B`（或菜单 `终端 → 运行生成任务…`）。
   - 底层就是替你执行了 6.2 的"配置 + 编译"两条命令（参数写在 `.vscode/tasks.json` 里，已填好）。
   - 第一次按，顶部会弹"选择生成任务"，选 **cmake-build** 即可；以后直接编译。
3. **运行**：菜单 `终端 → 新建终端`，输入（想带参数就加在 exe 后面，见 6.4）：
   ```powershell
   .\build\01_display_image.exe
   ```
4. **调试**：打开 `src/01_display_image.cpp`，在代码左侧点行号**打断点**，按 `F5`。
   - 会自动先编译，再用 gdb 启动；想调试别的示例，改 `.vscode/launch.json` 里的 exe 名。
5. **写新代码**：往 `src/` 里放一个新 `.cpp` 文件 → 再按 `Ctrl+Shift+B` → 自动编译出同名 exe。

> 智能提示（写代码时弹说明/补全）：打开任意 `src/*.cpp`，若右下角提示"选择编译器"，
> 按 `Ctrl+Shift+P` → `C/C++: 选择 IntelliSense 配置` → 选 `Win32 (MinGW + OpenCV)`。
> 如果没反应，检查 `.vscode/c_cpp_properties.json` 里的 `opencvInstall` 路径是否是你的。

### 6.4 运行示例 & 命令行参数

三个程序都支持**一个命令行参数**，一句话规律：**`exe 后面跟一个参数 = 路径或编号`**。

**示例 1：读图显示**（默认显示 `images/test_image.png`；参数 = 图片路径）

```bat
build\01_display_image.exe
build\01_display_image.exe C:\some\photo.png     REM 显示你自己的图
```

**示例 2：转灰度**（默认处理 `images/test_image.png`，输出 `result_gray.png`；参数 = 图片路径）

```bat
build\02_grayscale.exe
build\02_grayscale.exe D:\my\color.jpg           REM 处理你自己的图
```

**示例 3：摄像头**（默认 0 号摄像头；参数 = 摄像头编号）

```bat
build\03_camera.exe
build\03_camera.exe 1                            REM 用 1 号摄像头（如 USB 外接）
```

| 示例                     | 参数含义     | 默认值                    |
| ------------------------ | ------------ | ------------------------- |
| `01_display_image.exe` | 图片文件路径 | `images/test_image.png` |
| `02_grayscale.exe`     | 图片文件路径 | `images/test_image.png` |
| `03_camera.exe`        | 摄像头编号   | `0`                     |

**在 VS Code 里想传命令行参数怎么办？**（两种方式）

- **方式 A（简单）**：在 VS Code 终端直接写全：
  ```powershell
  .\build\01_display_image.exe images\test_image.png
  ```
- **方式 B（F5 调试时传参）**：`.vscode/launch.json` 里已内置一个
  `调试（带命令行参数）` 配置，把 `args` 改成你要的参数：
  ```json
  "args": ["images/test_image.png"]
  ```

  然后在"运行和调试"面板（`Ctrl+Shift+D`）里选中它，按 F5。

### 6.5 写你自己的第一个程序（超级简单）

这个仓库本身就是一个**可开发的工程模板**，你不用新建任何东西，直接在 `src/` 里加文件就行：

1. 在 `src/` 文件夹里**新建一个 `.cpp` 文件**，比如 `src/my_first.cpp`
   （可以复制 `01_display_image.cpp` 改，也可以照下面抄）：
   ```cpp
   #include <opencv2/opencv.hpp>
   #include <iostream>
   int main()
   {
       cv::Mat img = cv::imread("images/test_image.png");
       if (img.empty()) { std::cout << "没读到图" << std::endl; return -1; }
       cv::imshow("my first program", img);   // 窗口标题用英文（中文标题在 Windows 上会乱码）
       cv::waitKey(0);
       return 0;
   }
   ```
2. 按 `Ctrl+Shift+B` 编译（会自动重新配置）
3. 在终端运行：`.\build\my_first.exe`

> ✅ `CMakeLists.txt` 会**自动发现 `src/` 下所有 `.cpp`**，每个编译成同名 exe，
> 你**完全不需要改 CMakeLists**。删掉文件再编译，对应的 exe 也会消失。

**代码放哪、产物放哪：**

| 内容                | 位置                                                   |
| ------------------- | ------------------------------------------------------ |
| 你的源码（.cpp）    | `src/`                                               |
| 图片素材            | `images/`（`imread` 用相对路径 `images/xx.png`） |
| 编译产物（exe/dll） | `build/`（不用管，也不要提交到 git）                 |
| 程序输出的文件      | 项目根目录（如 `result_xx.png`）                     |

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
- 想带命令行参数调试：改用 `.vscode/launch.json` 里的 `调试（带命令行参数）` 配置，改 `args`。

### 7.5 手动在终端跑

```bat
# 在项目根目录
cmake --build build -j 8
.\build\01_display_image.exe
```

---

## 8. 验证清单

| 检查项    | 命令                                         | 预期结果                 |
| --------- | -------------------------------------------- | ------------------------ |
| 编译器    | `g++ --version`                            | 打印 MinGW g++ 版本      |
| 构建工具  | `cmake --version`                          | 打印 CMake 版本          |
| 版本管理  | `git --version`                            | 打印 Git 版本            |
| OpenCV 库 | `install\x64\mingw\bin\opencv_version.exe` | 打印 `4.13.0`          |
| 示例编译  | `cmake --build build -j 8`                 | 生成 3 个 exe，无 error  |
| 示例 1    | `build\01_display_image.exe`               | 弹窗显示测试图           |
| 示例 2    | `build\02_grayscale.exe`                   | 生成 `result_gray.png` |
| 示例 3    | `build\03_camera.exe`                      | 摄像头画面，按 q 退出    |

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
原因：源码约 100MB，默认从 **GitHub** 下载，国内网络访问 GitHub 经常很慢或超时。
解决：

- ✅ 新版脚本会**自动依次尝试**：GitHub 官方 zip → GitHub 直连 → `git clone`，一般能成功；
- 若仍失败（脚本会打印详细提示），三选一：
  1) 浏览器打开 `https://github.com/opencv/opencv/archive/refs/tags/4.13.0.zip` 手动下载，
     解压后把内容放进 `C:\dev\opencv\opencv\sources`（要包含 `CMakeLists.txt`），再重跑脚本；
  2) 命令行执行
     `git clone --depth 1 --branch 4.13.0 https://github.com/opencv/opencv.git C:\dev\opencv\opencv\sources`
  3) 问学长要一份**编译好的 install 文件夹**，用 `setup.ps1 -OpenCVDir 路径` 跳过编译（秒过）。

**Q3：仓库路径里含中文（如 `过渡时期`、`作业`），编译报错
`CMake Error: Target DependInfo.cmake file not found` / `No rule to make target`**
现象：`setup.bat` 能跑，但最后编译示例时报上面的错（配置阶段可能正常）。
原因：CMake 的 **MinGW Makefiles** 生成器**不支持非 ASCII 路径**，生成的 Makefile 里中文路径会编码错乱。
解决：

- ✅ 新版仓库**自带 `tools/ninja.exe`**，脚本检测到中文路径会自动改用 **Ninja 生成器**，已修复，直接更新仓库重下即可；
- 也可把整个项目移到**纯英文路径**（如 `C:\opencv`）再跑；
- 手动用 Ninja 编译：`cmake -S . -B build -G Ninja -DCMAKE_MAKE_PROGRAM=tools/ninja.exe ...`。

**Q4：运行 exe 报"找不到 opencv_world413.dll"**
原因：exe 找不到动态库。
解决：

- 本仓库的 CMakeLists 会自动把 DLL 复制到 exe 旁边，若还报错，手动把
  `install\x64\mingw\bin\*.dll` 复制到 `build\` 下；
- 或临时加 PATH：`set PATH=C:\dev\opencv\opencv\build_mingw\install\x64\mingw\bin;%PATH%` 再运行。

**Q5：编译报错 `'recursive_mutex' in namespace 'std' does not name a type` / `'Mutex' does not name a type`**
现象：编译时头文件报
      `utility.hpp: typedef std::recursive_mutex Mutex; 'recursive_mutex' does not name a type`、
      `typedef std::lock_guard<cv::Mutex> AutoLock; 模板参数 1 无效`、
      `'Mutex' in namespace 'cv' does not name a type`。
原因：OpenCV 4.x 头文件里的 `cv::Mutex` 依赖 C++11 的 `std::recursive_mutex`。报这个错，**头号原因是
      你的 MinGW 是 win32 线程模型**（`g++ -v` 里 `Thread model: win32`）：
      win32 线程模型的 libstdc++ **天生没有** `std::recursive_mutex`，没有任何编译参数能救，
      必须换成 **posix 线程模型**的 MinGW-w64。
      次要原因：用了不匹配的 OpenCV（MSVC 版/别的编译器编的/损坏）、或编译器太旧（gcc 4/5/6）。
检查方法：

```bat
g++ -v
```

看 `Thread model:` 是 `posix`（✅ 能用）还是 `win32`（❌ 必须换）。
解决（**路线 A，推荐，根治**）：

- 换成 posix 线程模型、较新的 MinGW-w64（如 `x86_64-8.1.0-release-posix-seh-rt_v6-rev0`，
  或 winlibs 的 POSIX UCRT 版）；
- 换编译器后，**之前用旧编译器编的 OpenCV install 不要再直接复用**（ABI 可能不匹配），
  建议让脚本从源码重新编译一份（回车不填 install 路径即可，30~60 分钟）；
- ✅ 新版脚本会自动识别：检测到 win32 线程模型/太旧的编译器会明确提示，
  并尝试用 winget 自动装 posix 版 MinGW-w64；找到的 OpenCV 也会先**自检**再使用。
  解决（**路线 B，不推荐**）：保留 win32 线程 MinGW，把 OpenCV 降到 **3.4.x**（早期版本不依赖
  `std::recursive_mutex`）。缺点：新 API/部分算法/相机模块缺失，能用但落后。

> ⚠️ 别浪费时间：在 cpp 里 `#include <mutex>`、加 `-pthread`、改 `-std`、改 tasks.json、
> 反复清理 build——这些对 win32 线程模型**都没用**，问题在编译器本身。

**Q6：用官方预编译 OpenCV + MinGW 报一堆链接错误**
原因：官方预编译是 MSVC 版，ABI 不兼容 MinGW。
解决：用本教程"源码编译"方式生成 MinGW 版；或改用 Visual Studio（MSVC）。

**Q7：`g++` 不是内部或外部命令**
原因：MinGW 的 `bin` 没加进 PATH，或没重开终端。
解决：检查环境变量 `Path`，重开终端。

**Q8：摄像头打不开（`无法打开摄像头`）**
可能原因：

- 摄像头被其他软件（微信/Teams）占用 → 关掉再试；
- 设备号不是 0 → 把代码里的 `VideoCapture(0)` 改成 `1` 或 `2`；
- 笔记本需在系统设置里允许应用使用摄像头。

**Q9：终端中文乱码（控制台文字）**
现象：程序里 `cout`/`printf` 输出的中文变成 `鎴愬姛`、`涓枃` 之类。
原因：源码是 UTF-8，而中文 Windows 控制台默认按 GBK 解码，两边对不上。
解决：本仓库每个示例第一行都调用了 `enable_utf8_console()`（见 `src/console_utf8.h`），
      会自动把控制台切到 UTF-8，**正常不会再乱码**。若个别环境仍乱码：

- 运行前先执行 `chcp 65001` 切到 UTF-8；
- 或确认用的是**最新代码**：删掉 `build/` 后按第 6.2 节完整命令重新配置编译。

**Q9.5：OpenCV 弹窗的【窗口标题】是乱码？**
现象：`cv::imshow("01 - 显示图片", ...)` 的**窗口标题**显示成乱码，但控制台文字正常。
原因：OpenCV 在 Windows 上创建窗口用的是 **ANSI 版 Windows API**（`CreateWindowA`），
      中文标题会被按系统 GBK 码页解码，UTF-8 的中文就乱了。这是 OpenCV 对中文标题
      的老毛病，不是你的代码问题。
解决：窗口标题**用英文**。示例代码已全部改成英文标题（如 `"01 - display image"`、
      `"Original"`、`"Grayscale"`、`"Camera - press q to quit"`），控制台中文不受影响。

**Q10：每次改 OpenCV 都要重新编译吗？**
不用。OpenCV 编译一次即可，之后你的示例项目只是**链接**它。

**Q11：编译很慢怎么办？**

- 用 `-j` 加大并行数（CPU 核数）；
- 缩小 `BUILD_LIST`（只留需要的模块）；
- 只编译一次，之后就快了。

**Q12：删掉 build 后执行 `cmake ..` 报错 `Could not find a package configuration file provided by "OpenCV"`**
现象：终端打印 `-- Building for: Visual Studio 17 2022`，然后 find_package 找不到 OpenCV。
原因：Windows 上**裸跑 `cmake ..`**，CMake 默认选 **Visual Studio** 生成器；
      而仓库用的是 **MinGW 编译的 OpenCV**（装在含 `x64/mingw` 的目录），
      VS 不兼容也找不到它的配置，所以报错。
解决：**不要裸跑 `cmake ..`**。删过 build 后，用第 6.2 节的完整命令配置
      （带 `-G Ninja -DCMAKE_CXX_COMPILER -DOpenCV_DIR` 那一段），
      或直接在 VS Code 按 `Ctrl+Shift+B`，让 tasks.json 替你配置。

**Q13：PowerShell 里敲 cmake 命令报错（`-D` 被拆 / `^` 不认 / ninja 找不到）**
现象：

- 把 README 的多行命令复制进 **PowerShell**，每行报 `无法将 '-DXXX' 识别为 cmdlet…`；
- 或 `-DCMAKE_MAKE_PROGRAM=tools/ninja.exe` 报 `Running 'tools/ninja' '--version' failed`；
- 或 `cmake -S . -B build -G Ninja ^` 提示 `Ignoring extra path: ^`。
  原因：
- **`^` 是 cmd 的换行符，PowerShell 不认**（PowerShell 用反引号 `` ` ``）。多行命令贴进
  PowerShell 后，每行被当成独立命令执行 → 报"无法识别"。
- **PowerShell 5.1 传参 bug**：`-DXXX=tools/ninja.exe` 里的 `.exe` 会被拆成单独参数 → cmake 找不到 ninja。
- `-DCMAKE_MAKE_PROGRAM=tools/ninja.exe` 是**相对路径**，cmake 在 `build\` 目录里执行它时找不到。
  解决（任选）：
- 在 **cmd** 里按第 6.2 节写法 A 敲（`^` 换行）；
- 或在 **PowerShell** 里用第 6.2 节写法 B：`-D` 的值加引号，且 ninja 用**项目绝对路径**。

**Q14：`cmake --build C:\dev\opencv\opencv\build_mingw -j 8` 是干嘛的？build 完了怎么什么都没有？**
原因：这条命令是**编译 OpenCV 库本身**（第 5 节，只需做一次），输出是 OpenCV 的
      `libopencv_world4130.dll` 等库文件（在 `C:\dev\opencv\opencv\build_mingw` 里），
      **不是**你的示例 exe。你的示例 exe 要编译的是**你自己的工程**。
解决：日常开发只敲 `cmake --build build -j`（在你【项目根目录】执行），
      产物在 `build\01_display_image.exe` 等。那条 `C:\dev\opencv\...` 的命令**不用再碰**。

**Q15：程序打印"请先点击图片窗口…"，可我在控制台狂按键盘，窗口就是关不掉？**
原因：`cv::waitKey(0)` 监听的是**图片窗口**的按键，**不是控制台的按键**。
      你的按键都被控制台（PowerShell）窗口吃掉了，OpenCV 图片窗口收不到。
解决：**用鼠标先点击图片窗口**，让它成为当前窗口，再按任意键就关了。
      示例代码的提示文字已改成"请先点击图片窗口使其获得焦点，再按任意键关闭"。

**Q16：`cmake --build build -j` 报 `could not load cache` / 配置时报 `0xc0000139`（坏的 ninja）**
现象：
- `cmake --build build -j` 直接报 `Error: could not load cache`；
- 或 `cmake -S . -B build -G Ninja`（**漏了 -D 参数**）报
  `Running 'C:/msys64/mingw64/bin/ninja.exe' '--version' failed`（0xc0000139）；
- 或把多行命令粘进 PowerShell，从第二行开始粘，报"意外的标记"。
原因：
- `could not load cache` = `build/` 里没有 CMake 配置缓存。**必须先"配置"再"编译"**：
  配置成功会生成 `build/CMakeCache.txt`，编译命令（`cmake --build build`）读它才知道怎么编。
  删过 `build/` 或刚克隆下来时，都要**先跑配置那一条**。
- `0xc0000139` = 你机器上有个 **MSYS2 装的 ninja**（`C:\msys64\mingw64\bin\ninja.exe`）是坏的（缺 DLL）。
  当你**漏掉 `-DCMAKE_MAKE_PROGRAM`** 时，CMake 会去 PATH 里找 ninja，正好找到这个坏的。
- 多行命令粘贴时容易**丢第一行**，PowerShell 把后半段当独立表达式解析 → 报"意外的标记"。
解决：
- 用第 6.2 节**单行版**完整命令（它用 `-DCMAKE_MAKE_PROGRAM` 明确指定仓库自带的
  `tools/ninja.exe`，不会去 PATH 找坏的 ninja，也不会丢行）。
- 每次流程固定为：**配置（一行）→ 编译 → 运行**。

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

### 10.1 给同学分发编译好的 install（跳过 30~60 分钟编译）

如果你已经把 OpenCV 编译好了，可以**只发一个约 54MB 的文件夹**，同学就不用等编译了。

**你在自己电脑上（打包）：**

1. 找到 `C:\dev\opencv\opencv\build_mingw\install`
2. 右键 → **压缩成 zip**（压完约 20MB）
3. 用 QQ / 微信 / 网盘 / Gitee Release 发给同学

**同学拿到后（使用）：**

1. 解压到任意位置，例如 `D:\opencv-install`
2. 双击 `setup.bat`，当脚本提示
   「有没有别人给你的 OpenCV install 文件夹？有就输入它的路径」时，
   **输入 `D:\opencv-install` 回车**
   → 脚本直接使用它，**跳过编译，几十秒就配好**
3. 或者把解压后的 install 放到 `C:\dev\opencv\opencv\build_mingw\install`，脚本会自动找到

> ✅ 这个 install 文件夹**可以随便移动位置**（实测过：复制到别的盘、别的路径后
> `find_package`、编译、运行都正常），因为 `OpenCVConfig.cmake` 用的是**相对路径**，不写死。

---

## 11. 仓库目录结构

```
opencv/
├── CMakeLists.txt            # 示例项目的构建脚本（含自动复制 DLL 步骤）
├── README.md                 # 本教程
├── setup.bat                 # 一键脚本入口（双击它，纯英文防乱码）
├── setup.ps1                 # 一键脚本本体（自动装工具链/OpenCV、写配置）
├── .gitignore                # 排除编译产物
├── tools/
│   └── ninja.exe             # 内置构建工具（免安装、支持中文路径，随仓库分发）
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

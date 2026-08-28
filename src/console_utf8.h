// ============================================================
// 小工具：修复 Windows 控制台中文乱码（本仓库自带）
// ------------------------------------------------------------
// 为什么会乱码？
//   源码文件是 UTF-8 编码，g++ 把字符串原样（UTF-8 字节）放进 exe；
//   而中文版 Windows 的控制台默认按 GBK 解码，
//   UTF-8 的中文被当成 GBK 显示 → 乱码（比如"成功"变成"鎴愬姛"）。
//
// 解决办法：
//   程序一启动就把控制台输出切到 UTF-8（代码页 65001）。
//   这样双击 exe、cmd、PowerShell、F5 调试窗口都不会乱码。
//
// ⚠️ 注意：这个只修"控制台文字"。OpenCV 弹窗的【窗口标题】
//   （cv::imshow 的第一个参数）在 Windows 上是用 ANSI 窗口 API 创建
//   的，中文标题会乱码 —— 所以示例代码里窗口标题都用英文
//   （如 "01 - display image"、"Original"、"Grayscale"）。
//
// 用法（照抄即可）：
//   #include "console_utf8.h"
//   int main() {
//       enable_utf8_console();   // main 第一行调用
//       ...
//   }
// ============================================================
#pragma once

#ifdef _WIN32
#ifndef NOMINMAX            // 防止 windows.h 的 min/max 宏和 std::min/max 打架
#define NOMINMAX            // （OpenCV 头文件可能已定义过，加保护避免重定义警告）
#endif
#include <windows.h>        // SetConsoleOutputCP / SetConsoleCP 声明在这个头文件里

// 把控制台【输出】和【输入】都切到 UTF-8（代码页 65001），
// 让 cout/printf 显示中文、cin 读中文都不乱码
inline void enable_utf8_console()
{
    SetConsoleOutputCP(65001);  // 输出：printf/cout 的中文按 UTF-8 显示
    SetConsoleCP(65001);        // 输入：cin 按 UTF-8 读取
}
#else
// Linux / Mac 的终端本来就是 UTF-8，什么都不用做
inline void enable_utf8_console() {}
#endif

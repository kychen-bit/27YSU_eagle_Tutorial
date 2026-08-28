// ============================================================
// 示例 3：打开摄像头，实时显示画面，按 q 退出
// ------------------------------------------------------------
// 学习点：
//   cv::VideoCapture(0)    打开设备 0（默认摄像头）
//   cap >> frame           抓取一帧画面到 cv::Mat
//   cap.isOpened()         检查摄像头是否成功打开
//   waitKey(30)            每 30ms 刷新（约 33 FPS）
// ============================================================
#include <opencv2/opencv.hpp>
#include <iostream>
#include "console_utf8.h"       // 修复 Windows 控制台中文乱码
#include <cstdlib>              // std::atoi

int main(int argc, char** argv)
{
    enable_utf8_console();      // 切控制台到 UTF-8，中文不乱码

    // 1. 摄像头编号：可命令行传参，缺省 0
    //    用法示例:  build/03_camera.exe        （用 0 号摄像头）
    //              build/03_camera.exe 1      （用 1 号摄像头，如 USB 外接）
    int cam_id = (argc >= 2) ? std::atoi(argv[1]) : 0;

    // 打开摄像头。参数是设备编号（有多个摄像头时可试 0、1、2...）
    cv::VideoCapture cap(cam_id);
    if (!cap.isOpened())
    {
        std::cerr << "[错误] 无法打开摄像头 " << cam_id
                  << "，请检查设备是否被占用" << std::endl;
        return -1;
    }

    cv::Mat frame;
    // 先点击视频窗口使其获得焦点，再按 q 或 ESC 退出（waitKey 只接收视频窗口的按键）
    std::cout << "摄像头 " << cam_id << " 已开启！先点击视频窗口，按 q 或 ESC 退出..." << std::endl;

    while (true)
    {
        cap >> frame;                       // 抓取一帧
        if (frame.empty()) break;           // 抓取失败则退出

        cv::imshow("Camera - press q to quit", frame);   // 标题用英文，避免中文乱码

        // waitKey(30): 等待 30ms 并返回按键值
        // 'q' / 'Q' / ESC(27) 都表示退出
        int key = cv::waitKey(30);
        if (key == 'q' || key == 'Q' || key == 27)
            break;
    }

    cap.release();                          // 释放摄像头
    cv::destroyAllWindows();
    std::cout << "已退出。" << std::endl;
    return 0;
}

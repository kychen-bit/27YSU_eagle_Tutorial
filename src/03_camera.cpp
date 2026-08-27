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

int main()
{
    // 打开默认摄像头。参数 0 是设备编号（有多个摄像头时可试 1、2...）
    cv::VideoCapture cap(0);
    if (!cap.isOpened())
    {
        std::cerr << "[错误] 无法打开摄像头，请检查设备是否被占用" << std::endl;
        return -1;
    }

    cv::Mat frame;
    std::cout << "摄像头已开启！按 q 或 ESC 退出..." << std::endl;

    while (true)
    {
        cap >> frame;                       // 抓取一帧
        if (frame.empty()) break;           // 抓取失败则退出

        cv::imshow("摄像头 - 按 q 退出", frame);

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

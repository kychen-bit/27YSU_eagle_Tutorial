// ============================================================
// 示例 1：读取一张图片并在窗口中显示
// ------------------------------------------------------------
// 学习点：
//   cv::imread(path, flag)  读取图片，返回 cv::Mat（图像矩阵）
//   cv::imshow(title, mat)  在窗口中显示图像
//   cv::waitKey(ms)         等待按键（0 = 无限等待）
//   cv::destroyAllWindows() 关闭所有窗口
// ============================================================
#include <opencv2/opencv.hpp>   // OpenCV 总头文件（包含了常用模块）
#include <iostream>             // std::cout / std::cerr
#include "console_utf8.h"       // 修复 Windows 控制台中文乱码

int main(int argc, char** argv)
{
    enable_utf8_console();      // 切控制台到 UTF-8，中文不乱码（main 第一行）

    // 1. 图片路径：可命令行传参，缺省用仓库里的测试图
    //    用法示例:  build/01_display_image.exe  或
    //              build/01_display_image.exe C:/some/photo.png
    std::string path = (argc >= 2) ? argv[1] : "images/test_image.png";

    // 2. 读取图片。IMREAD_COLOR = 以 3 通道 BGR 彩色读入（默认值）
    cv::Mat image = cv::imread(path, cv::IMREAD_COLOR);
    if (image.empty())          // 读不到文件时 image 为空
    {
        std::cerr << "[错误] 无法读取图片: " << path << std::endl;
        return -1;
    }

    // 3. 打印图片基本信息（验证读取成功）
    std::cout << "成功读取图片: " << path << std::endl;
    std::cout << "  宽(列数)   : " << image.cols  << " 像素" << std::endl;
    std::cout << "  高(行数)   : " << image.rows  << " 像素" << std::endl;
    std::cout << "  通道数     : " << image.channels() << " (BGR 彩色为 3)" << std::endl;

    // 4. 在窗口中显示（第一个参数是窗口标题）
    //    ⚠️ 窗口标题用英文：OpenCV 在 Windows 上创建窗口用的是 ANSI API，
    //    中文标题会乱码（见 console_utf8.h 的说明）。控制台中文不受影响。
    cv::imshow("01 - display image", image);

    // 5. 等待按键。waitKey(0) 表示一直等，直到有按键输入才继续。
    //    ⚠️ 注意：waitKey 接收的是【图片窗口】的按键，不是控制台的按键！
    //    所以一定要先用鼠标点一下图片窗口（让它获得焦点），再按任意键，否则关不掉。
    std::cout << "请先点击图片窗口使其获得焦点，再按任意键关闭..." << std::endl;
    cv::waitKey(0);

    // 6. 程序结束前释放所有窗口
    cv::destroyAllWindows();
    return 0;
}

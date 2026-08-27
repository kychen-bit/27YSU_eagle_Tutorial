// ============================================================
// 示例 2：把彩色图转成灰度图，并保存到磁盘
// ------------------------------------------------------------
// 学习点：
//   cv::cvtColor(src, dst, code)  颜色空间转换
//       COLOR_BGR2GRAY = 彩色(BGR) → 灰度
//   cv::imwrite(path, mat)         把图像保存成文件（png/jpg）
//   灰度图 = 单通道，每个像素一个 0~255 的亮度值
// ============================================================
#include <opencv2/opencv.hpp>
#include <iostream>

int main(int argc, char** argv)
{
    std::string path = (argc >= 2) ? argv[1] : "images/test_image.png";
    cv::Mat color = cv::imread(path, cv::IMREAD_COLOR);
    if (color.empty())
    {
        std::cerr << "[错误] 无法读取图片: " << path << std::endl;
        return -1;
    }

    // ---- 核心：彩色 → 灰度 ----
    cv::Mat gray;
    cv::cvtColor(color, gray, cv::COLOR_BGR2GRAY);

    // 保存结果（扩展名决定格式；jpg 默认有损压缩，png 无损）
    const std::string out = "result_gray.png";
    if (cv::imwrite(out, gray))
        std::cout << "灰度图已保存: " << out << std::endl;
    else
        std::cerr << "[错误] 保存失败" << std::endl;

    // 并排显示原图与灰度图，方便对比
    cv::imshow("原图", color);
    cv::imshow("灰度图", gray);
    std::cout << "按任意键关闭窗口..." << std::endl;
    cv::waitKey(0);
    cv::destroyAllWindows();
    return 0;
}

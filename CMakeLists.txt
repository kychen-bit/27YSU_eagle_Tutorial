# ============================================================
# OpenCV + VS Code 入门示例项目 —— CMake 构建脚本
# ------------------------------------------------------------
# 用法（在项目根目录执行，或直接用 VS Code 的 Ctrl+Shift+B）:
#   1) 配置:  cmake -S . -B build -G "MinGW Makefiles" ^
#                -DCMAKE_MAKE_PROGRAM=C:/mingw64/bin/mingw32-make.exe ^
#                -DCMAKE_BUILD_TYPE=Release ^
#                -DOpenCV_DIR=C:/dev/opencv/opencv/build_mingw/install
#   2) 编译:  cmake --build build -j
#   3) 运行:  build/01_display_image.exe
# ============================================================

cmake_minimum_required(VERSION 3.16)
project(OpenCV_Examples CXX)

# ---- C++ 标准（OpenCV 4.x 需要 C++11+，这里用 17 更现代）----
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ---- 关闭调试版/发布版符号混淆的默认行为（新手不用改）----
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# ---- 找到 OpenCV ----
# 原理：OpenCV 安装目录里有 OpenCVConfig.cmake。
# CMake 按顺序在以下位置找它：
#   1) 命令行 -DOpenCV_DIR=...
#   2) 环境变量 OpenCV_DIR
#   3) 系统默认路径
# 找不到就报错，并提示你设置 OpenCV_DIR。
find_package(OpenCV REQUIRED)

# 把 OpenCV 版本等信息打印出来，方便确认找对版本了
message(STATUS "OpenCV version : ${OpenCV_VERSION}")
message(STATUS "OpenCV include : ${OpenCV_INCLUDE_DIRS}")
message(STATUS "OpenCV libs    : ${OpenCV_LIBS}")

# ---- 三个示例可执行程序 ----
add_executable(01_display_image src/01_display_image.cpp)
add_executable(02_grayscale      src/02_grayscale.cpp)
add_executable(03_camera         src/03_camera.cpp)

# ---- 给每个示例链接 OpenCV ----
foreach(tgt 01_display_image 02_grayscale 03_camera)
    target_link_libraries(${tgt} PRIVATE ${OpenCV_LIBS})
    target_include_directories(${tgt} PRIVATE ${OpenCV_INCLUDE_DIRS})
endforeach()

# ============================================================
# 新手省心一步：把运行需要的 DLL 自动复制到 exe 旁边
# ------------------------------------------------------------
# 原因：Windows 上运行程序时，系统按顺序找 DLL：
#   exe 所在目录 → 系统目录 → PATH
# 不复制的话，直接双击 exe 会报 "找不到 opencv_world413.dll"。
# 下面这段在每次编译后自动把 OpenCV 的 DLL 和 MinGW 运行时 DLL
# 复制到每个 exe 旁边，双击就能跑。
# ============================================================

# OpenCV 的 DLL 目录。OpenCV_DIR 可能指向 install 根目录，
# 也可能指向 x64/mingw/lib（本教程实际布局），几个候选都试一遍
set(_opencv_dll_dirs
    "${OpenCV_DIR}/../bin"
    "${OpenCV_DIR}/x64/mingw/bin"
    "${OpenCV_DIR}/bin"
)
set(_opencv_dll_dir "")
foreach(_d ${_opencv_dll_dirs})
    if(EXISTS "${_d}")
        set(_opencv_dll_dir "${_d}")
        break()
    endif()
endforeach()
# 关键：cmake -E copy_directory 不接受带 ../ 的路径，必须先归一化成绝对路径
get_filename_component(_opencv_dll_dir "${_opencv_dll_dir}" ABSOLUTE)
message(STATUS "OpenCV DLL 目录: ${_opencv_dll_dir}")

# MinGW 运行时 DLL（g++ 编译的程序都需要这三兄弟）
set(_mingw_bin "C:/mingw64/bin")
set(_mingw_runtime_dlls
    "${_mingw_bin}/libgcc_s_seh-1.dll"
    "${_mingw_bin}/libstdc++-6.dll"
    "${_mingw_bin}/libwinpthread-1.dll"
)

foreach(tgt 01_display_image 02_grayscale 03_camera)
    add_custom_command(TARGET ${tgt} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
                "${_opencv_dll_dir}" "$<TARGET_FILE_DIR:${tgt}>"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
                ${_mingw_runtime_dlls} "$<TARGET_FILE_DIR:${tgt}>"
        COMMENT "复制 OpenCV/MinGW DLL 到 exe 旁边..."
    )
endforeach()

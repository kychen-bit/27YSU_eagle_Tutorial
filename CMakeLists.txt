# ============================================================
# OpenCV + VS Code 入门示例项目 —— CMake 构建脚本
# ------------------------------------------------------------
# 用法（在项目根目录执行，或直接用 VS Code 的 Ctrl+Shift+B）:
#   1) 配置:  cmake -S . -B build -G Ninja ^
#                -DCMAKE_MAKE_PROGRAM=<你的项目绝对路径>/tools/ninja.exe ^
#                -DCMAKE_CXX_COMPILER=C:/mingw64/bin/g++.exe ^
#                -DCMAKE_BUILD_TYPE=Release ^
#                -DOpenCV_DIR=C:/dev/opencv/opencv/build_mingw/install/x64/mingw/lib
#   2) 编译:  cmake --build build -j
#   3) 运行:  build/01_display_image.exe
#
# ⚠️ 两个必踩的坑：
#   1) 千万别"裸跑 cmake .."：Windows 上 CMake 默认会用 Visual Studio 生成器，
#      而我们这份 OpenCV 是 MinGW 编的，VS 找不到它就会报错。
#      删过 build/ 之后，一定要用上面 1) 的完整命令（或直接用 Ctrl+Shift+B）。
#   2) -DCMAKE_MAKE_PROGRAM 必须写【绝对路径】（cmake 在 build/ 目录里执行 ninja，
#      相对路径 tools/ninja.exe 会找不到）。另外在 PowerShell 5.1 里 -D 的值要加引号
#      （如 '-DCMAKE_MAKE_PROGRAM=...'），否则 tools/ninja.exe 会被拆成 tools/ninja+.exe 报错。
# ============================================================

cmake_minimum_required(VERSION 3.16)
project(OpenCV_Examples CXX)

# ---- C++ 标准（OpenCV 4.x 需要 C++11+，这里用 17 更现代）----
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ---- 源码统一按 UTF-8 处理（避免中文乱码）----
# g++ 默认就把字符串存成 UTF-8；这两行再强制"读源码=UTF-8、写进 exe=UTF-8"，
# 保证任何电脑 / 任何 g++ 版本下，控制台中文输出都不乱码。
# （只对 GCC/Clang 生效；本项目用 MinGW g++，MSVC 不受影响）
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    add_compile_options(-finput-charset=UTF-8 -fexec-charset=UTF-8)
endif()

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

# ---- 自动发现 src/ 下所有 .cpp，每个编成一个同名 exe ----
# 新手友好：只要把 .cpp 放进 src/，Ctrl+Shift+B 就会自动编译成同名 exe，
# 不用手动改任何配置。
file(GLOB APP_SOURCES CONFIGURE_DEPENDS ${CMAKE_SOURCE_DIR}/src/*.cpp)
set(APP_TARGETS "")
foreach(src ${APP_SOURCES})
    get_filename_component(name ${src} NAME_WE)
    add_executable(${name} ${src})
    target_link_libraries(${name} PRIVATE ${OpenCV_LIBS})
    target_include_directories(${name} PRIVATE ${OpenCV_INCLUDE_DIRS})
    list(APPEND APP_TARGETS ${name})
endforeach()
message(STATUS "发现的源码文件: ${APP_SOURCES}")

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

# MinGW 运行时 DLL（g++ 编译的程序通常需要这三兄弟）
# 关键：不写死路径，按实际编译器所在目录找（不同机器 MinGW 位置不同，
# 比如别人的可能装在 D:\MinGW）
get_filename_component(_mingw_bin "${CMAKE_CXX_COMPILER}" DIRECTORY)
set(_mingw_runtime_dlls
    "${_mingw_bin}/libgcc_s_seh-1.dll"
    "${_mingw_bin}/libstdc++-6.dll"
    "${_mingw_bin}/libwinpthread-1.dll"
)

# ============================================================
# 只用 ONE 个独立 target 复制 DLL（copy_runtime_dlls），
# 所有 exe 都依赖它 —— 而不是每个 exe 的 POST_BUILD 各自复制。
# 原因（踩坑记录）：
#   1) cmake --build -j 并行编译时，多个 POST_BUILD 同时往同一个
#      build/ 目录复制同一批 DLL 会"撞车"（copy_if_different 报
#      Error copying file），串行编译测不出来。
#   2) copy_directory 会把 opencv_annotation.exe 等 OpenCV 自带
#      工具也复制进来，把 build 目录弄乱。
# 所以改成：只复制明确需要的 DLL 文件（OpenCV world DLL + MinGW 三件套）。
# ============================================================
set(_all_runtime_dlls "${_opencv_dll_dir}/libopencv_world${OpenCV_VERSION_MAJOR}${OpenCV_VERSION_MINOR}${OpenCV_VERSION_PATCH}.dll")
foreach(_dll ${_mingw_runtime_dlls})
    if(EXISTS "${_dll}")
        list(APPEND _all_runtime_dlls "${_dll}")
    endif()
endforeach()

add_custom_target(copy_runtime_dlls ALL
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${_all_runtime_dlls}
            ${CMAKE_BINARY_DIR}
    COMMENT "复制运行时 DLL（OpenCV + MinGW）到 build/ ..."
    DEPENDS ${_all_runtime_dlls}
)
# 每个 exe 都等 DLL 复制完再链接，保证依赖顺序（也顺带解决并行撞车）
foreach(tgt ${APP_TARGETS})
    add_dependencies(${tgt} copy_runtime_dlls)
endforeach()

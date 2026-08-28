#Requires -Version 5.1
<#
============================================================
 OpenCV + C++ (MinGW) 一键环境配置脚本（傻瓜式）
------------------------------------------------------------
 作用（全自动）：
   1. 检测 g++ / cmake / git 是否已装，缺的用 winget 自动安装
   2. 检测是否已有可用的 OpenCV(4.x, MinGW 版)
      没有 → 自动下载 OpenCV 4.13 源码并编译、安装
   3. 自动把 .vscode 里的三个配置文件路径改成你机器的
   4. 自动编译本仓库示例并验证
 用法：
   方法1（推荐，双击即可）:  双击 setup.bat
   方法2（命令行）:  powershell -NoProfile -ExecutionPolicy Bypass -File setup.ps1
 可选参数：
   -SkipTools          跳过工具安装（只做检测）
   -SkipOpenCVBuild    跳过 OpenCV 源码编译（仅当已存在可用 OpenCV 时）
   -OpenCVDir <路径>    指定一个已有的 OpenCV install 目录，跳过编译
------------------------------------------------------------
#>
[CmdletBinding()]
param(
    [switch]$SkipTools,
    [switch]$SkipOpenCVBuild,
    [string]$OpenCVDir = "",
    [switch]$NoPause            # 自动验证用：不等待按键
)

$ErrorActionPreference = 'Stop'
$repo            = $PSScriptRoot
$OpenCV_VER      = "4.13.0"
$OpenCV_TAG_URL  = "https://github.com/opencv/opencv/archive/refs/tags/$OpenCV_VER.zip"
$opencvBase      = "C:\dev\opencv"          # OpenCV 源码/编译放这里（习惯约定）
$opencvInstall   = ""                        # 最终：install 根目录（含 include）
$opencvLibDir    = ""                        # 最终：含 OpenCVConfig.cmake 的目录
$opencvDllDir    = ""                        # 最终：含 libopencv_world*.dll 的目录
$gppBin          = ""                        # 最终：g++.exe 所在目录
$script:needTools = @()

# ---------------- 小工具函数 ----------------
function Say ($m)  { Write-Host "  $m" -ForegroundColor Cyan }
function Info($m)  { Write-Host "  $m" -ForegroundColor Gray }
function Ok  ($m)  { Write-Host "  [OK] $m" -ForegroundColor Green }
function Warn($m)  { Write-Host "  [!] $m" -ForegroundColor Yellow }
function Err ($m)  { Write-Host "  [x] $m" -ForegroundColor Red }
function Step($m)  {
    Write-Host ""
    Write-Host "==================== $m ====================" -ForegroundColor Magenta
}

function Pause-IfNeeded([string]$msg = "按回车退出") {
    if (-not $NoPause) { Read-Host $msg }
}

function Refresh-Path {
    $m = [Environment]::GetEnvironmentVariable('Path','Machine')
    $u = [Environment]::GetEnvironmentVariable('Path','User')
    $env:Path = "$m;$u"
}

function Find-Exe([string]$name) {
    $c = Get-Command $name -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    return $null
}

function Resolve-Ninja {
    # 优先用仓库自带的 tools/ninja.exe（已随仓库分发，免安装、无需网络）
    $local = Join-Path $PSScriptRoot "tools\ninja.exe"
    if (Test-Path $local) { return $local }
    $c = Find-Exe "ninja"
    if ($c) { return $c }
    return $null
}

function Add-UserPath([string]$dir) {
    if (-not (Test-Path $dir)) { return }
    $u = [Environment]::GetEnvironmentVariable('Path','User')
    if (($u -split ';') -notcontains $dir) {
        [Environment]::SetEnvironmentVariable('Path', "$u;$dir", 'User')
        Say "已把 $dir 加入【用户】PATH（新的终端才会生效）"
        Refresh-Path
    }
}

function Find-FileRecursive([string]$root, [string]$file, [int]$depth = 5) {
    if (-not (Test-Path $root)) { return $null }
    $hit = Get-ChildItem $root -Recurse -Depth $depth -Filter $file -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($hit) { return $hit.FullName }
    return $null
}

function Get-CPUCount { return [int]$env:NUMBER_OF_PROCESSORS }

# 把路径里的 \ 换成 /（VS Code 配置里统一用 /）
function To-Forward([string]$p) { return $p.Replace('\','/') }

# ---------------- 第 0 步：欢迎 ----------------
Write-Host ""
Write-Host "  ==================================================" -ForegroundColor Cyan
Write-Host "   OpenCV + C++ (MinGW) 一键环境配置" -ForegroundColor Cyan
Write-Host "   版本: OpenCV $OpenCV_VER | 目标: VS Code" -ForegroundColor Cyan
Write-Host "  ==================================================" -ForegroundColor Cyan

# ---------------- 第 1 步：检测 / 安装工具 ----------------
Step "1/4 检测工具链 (g++ / cmake / git)"

$gpp = Find-Exe "g++"
$cmake = Find-Exe "cmake"
$git = Find-Exe "git"

if ($gpp) { Ok "g++    -> $gpp" }  else { Warn "g++    未找到（需要安装 MinGW-w64）"; $script:needTools += 'g++' }
if ($cmake){ Ok "cmake  -> $cmake" } else { Warn "cmake  未找到"; $script:needTools += 'cmake' }
if ($git)  { Ok "git    -> $git" }  else { Warn "git    未找到（可选，上传 GitHub 才需要）"; $script:needTools += 'git' }

if (-not $SkipTools -and $script:needTools.Count -gt 0) {
    $wget = Find-Exe "winget"
    if (-not $wget) {
        Err "检测到缺少工具，但本机没有 winget，无法自动安装。"
        Err "请手动安装后重新运行本脚本："
        Err "  MinGW-w64:  https://winlibs.com  （下载后把 bin 目录加入 PATH）"
        Err "  CMake:      https://cmake.org/download"
        Pause-IfNeeded
        exit 1
    }

    foreach ($t in $script:needTools) {
        switch ($t) {
            'g++' {
                Say "用 winget 安装 MinGW-w64 (WinLibs POSIX UCRT) ..."
                winget install --id BrechtSanders.WinLibs.POSIX.UCRT -e --silent `
                    --accept-package-agreements --accept-source-agreements
                if ($LASTEXITCODE -ne 0) { Warn "winget 安装失败，稍后请手动装 MinGW"; break }
                Refresh-Path
                # winget 装完可能不在 PATH，递归找一下
                $gpp = Find-Exe "g++"
                if (-not $gpp) {
                    $found = Find-FileRecursive "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" "g++.exe"
                    if ($found) { $gpp = $found }
                }
            }
            'cmake' {
                Say "用 winget 安装 CMake ..."
                winget install --id Kitware.CMake -e --silent `
                    --accept-package-agreements --accept-source-agreements
                if ($LASTEXITCODE -ne 0) { Warn "winget 安装失败，稍后请手动装 CMake"; break }
                Refresh-Path
                $cmake = Find-Exe "cmake"
                if (-not $cmake -and (Test-Path "C:\Program Files\CMake\bin\cmake.exe")) {
                    $cmake = "C:\Program Files\CMake\bin\cmake.exe"
                }
            }
            'git' {
                Say "用 winget 安装 Git ..."
                winget install --id Git.Git -e --silent `
                    --accept-package-agreements --accept-source-agreements
                if ($LASTEXITCODE -ne 0) { Warn "winget 安装失败，Git 可选，跳过"; }
                Refresh-Path
                $git = Find-Exe "git"
            }
        }
    }
    # 再检查一遍
    if (-not $gpp)   { $gpp = Find-Exe "g++" }
    if (-not $cmake) { $cmake = Find-Exe "cmake" }
}

if (-not $gpp)   { Err "没有找到 g++，无法继续。请手动安装 MinGW-w64 后重跑。"; Pause-IfNeeded; exit 1 }
if (-not $cmake) { Err "没有找到 cmake，无法继续。请手动安装后重跑。"; Pause-IfNeeded; exit 1 }

$gppBin = Split-Path $gpp -Parent
$make   = Join-Path $gppBin "mingw32-make.exe"
if (-not (Test-Path $make)) { $make = Find-Exe "mingw32-make"; if (-not $make) { $make = "$gppBin\mingw32-make.exe" } }
# ==================== 编译器检查：win32 线程模型 / 太旧 都不能用 OpenCV 4.x ====================
# win32 线程模型的 libstdc++ 没有 std::recursive_mutex（_GLIBCXX_HAS_GTHREADS 未定义），
# OpenCV 4.x 头文件用到它，会报 'recursive_mutex' does not name a type，任何参数都救不了。
function Get-GccInfo([string]$compiler) {
    if (-not $compiler -or -not (Test-Path $compiler)) { return $null }
    # 用 cmd 把 stderr 并入 stdout（g++ -v 输出在 stderr；直接 2>&1 在 EAP=Stop 下会抛错）
    $v = (& cmd /c "`"$compiler`" -v 2>&1")
    $tm = $null; $m = ($v | Select-String 'Thread model:\s*(\S+)' | Select-Object -First 1)
    if ($m) { $tm = $m.Matches[0].Groups[1].Value }
    $vm = ($v | Select-String 'gcc version (\d+)' | Select-Object -First 1)
    $maj = 0; if ($vm) { $maj = [int]$vm.Matches[0].Groups[1].Value }
    return @{ Thread = $tm; Major = $maj }
}
function Find-PosixGpp {
    # 在 winget 装过的 WinLibs 里找一个 posix + 较新的 g++
    $wg = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages"
    if (-not (Test-Path $wg)) { return $null }
    foreach ($g in (Get-ChildItem $wg -Recurse -Filter g++.exe -ErrorAction SilentlyContinue)) {
        $info = Get-GccInfo $g.FullName
        if ($info -and $info.Thread -eq 'posix' -and $info.Major -ge 8) { return $g.FullName }
    }
    return $null
}

$gppInfo = Get-GccInfo $gpp
$gppBad  = $false
if ($gppInfo) {
    if ($gppInfo.Thread -eq 'win32') {
        $gppBad = $true
        Warn "你的 MinGW 是 win32 线程模型（--threads=win32）："
        Warn "  OpenCV 4.x 头文件依赖 std::recursive_mutex，win32 线程模型的 libstdc++ 没有它，"
        Warn "  无论怎么配都无法使用 OpenCV 4.x，必须换成 posix 线程模型的 MinGW-w64。"
    }
    if ($gppInfo.Major -lt 8) {
        $gppBad = $true
        Warn "你的编译器较旧（gcc $($gppInfo.Major)）：OpenCV 4.x 需要较新的编译器。"
    }
}
if ($gppBad -and -not $SkipTools) {
    $newGpp = Find-PosixGpp
    if (-not $newGpp) {
        $w = Find-Exe "winget"
        if ($w) {
            Warn "正在自动安装 posix 线程模型的最新 MinGW-w64（约 200MB，需几分钟）..."
            winget install --id BrechtSanders.WinLibs.POSIX.UCRT -e --silent `
                --accept-package-agreements --accept-source-agreements | Out-Null
            Refresh-Path
            $newGpp = Find-PosixGpp
        }
    }
    if ($newGpp) {
        $gpp = $newGpp
        Add-UserPath (Split-Path $gpp -Parent)
        Ok "已改用兼容的编译器: $gpp"
        $gppBad = $false
    }
}
if ($gppBad) {
    Err "你的 MinGW 是 win32 线程模型或版本过旧，无法使用 OpenCV 4.x。"
    Err "请安装 posix 线程模型的 MinGW-w64 后重跑（README 常见问题 Q5 有详细步骤）。"
    Pause-IfNeeded; exit 1
}
$gppBin = Split-Path $gpp -Parent
$make   = Join-Path $gppBin "mingw32-make.exe"
if (-not (Test-Path $make)) { $make = Find-Exe "mingw32-make"; if (-not $make) { $make = "$gppBin\mingw32-make.exe" } }
Ok "编译器: $gpp"
Ok "make  : $make"

# ---------------- 第 2 步：找 / 编译 OpenCV ----------------
Step "2/4 OpenCV (MinGW 版)"

function Test-OpenCVInstall([string]$root) {
    # 返回 @{Install=;Lib=;Dll=} 或 $null
    if (-not $root -or -not (Test-Path $root)) { return $null }
    if (-not (Test-Path (Join-Path $root "include\opencv2\opencv.hpp"))) { return $null }
    $libCandidates = @(
        (Join-Path $root "x64\mingw\lib"),
        (Join-Path $root "lib")
    )
    $dllCandidates = @(
        (Join-Path $root "x64\mingw\bin"),
        (Join-Path $root "bin")
    )
    $lib = $null; $dll = $null
    foreach ($d in $libCandidates) {
        if (Test-Path (Join-Path $d "OpenCVConfig.cmake")) { $lib = $d; break }
    }
    foreach ($d in $dllCandidates) {
        if (@(Get-ChildItem $d -Filter "libopencv_world*.dll" -ErrorAction SilentlyContinue).Count -gt 0) { $dll = $d; break }
    }
    if (-not $lib) { return $null }
    return @{ Install = $root; Lib = $lib; Dll = $dll }
}

function Test-OpenCVCompiles([string]$libDir, [string]$incDir, [string]$dllDir, [string]$compiler) {
    # 自检：用当前编译器编译+运行一个 5 秒的小程序，
    # 验证这个 OpenCV 真的能用（防捡到 MSVC版/损坏/ABI不匹配/编译器太旧的 OpenCV）
    if (-not $compiler -or -not (Test-Path $compiler)) { return $false }
    $world = Get-ChildItem $libDir -Filter "libopencv_world*.dll.a" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $world) { return $false }   # 没有 MinGW 的 .dll.a 导入库 → 不是 MinGW 版 → 不可用
    $libname = ($world.BaseName -replace '^lib','') -replace '\.dll$',''   # opencv_world4130
    $tmp = Join-Path $env:TEMP "opencv_selftest"
    New-Item -ItemType Directory -Force -Path $tmp | Out-Null
    $src = Join-Path $tmp "t.cpp"
    $exe = Join-Path $tmp "t.exe"
    Remove-Item $exe -Force -ErrorAction SilentlyContinue
    @'
#include <opencv2/opencv.hpp>
#include <iostream>
int main(){ cv::Mat m(10, 10, CV_8UC1, cv::Scalar(0)); std::cout << CV_VERSION; return m.empty() ? 1 : 0; }
'@ | Set-Content $src -Encoding UTF8
    & $compiler -std=c++17 $src -I"$incDir" -L"$libDir" "-l$libname" -o $exe 2>$null
    if ($LASTEXITCODE -ne 0) { return $false }
    $oldPath = $env:PATH
    $env:PATH = "$dllDir;$env:PATH"
    & $exe *> $null
    $ok = ($LASTEXITCODE -eq 0)
    $env:PATH = $oldPath
    Remove-Item $exe -Force -ErrorAction SilentlyContinue
    return $ok
}

$candidate = $null
if ($OpenCVDir) { $candidate = Test-OpenCVInstall $OpenCVDir }
if (-not $candidate -and $env:OpenCV_DIR) { $candidate = Test-OpenCVInstall $env:OpenCV_DIR }
if (-not $candidate) {
    foreach ($p in @("$opencvBase\opencv\build_mingw\install", "C:\opencv\build_mingw\install", "C:\opencv\install")) {
        $candidate = Test-OpenCVInstall $p
        if ($candidate) { break }
    }
}
if (-not $candidate) {
    # 在常见盘符上广撒网找（仅当上面没找到）
    foreach ($drive in @("C:\","D:\")) {
        foreach ($sub in @("dev\opencv\opencv\build_mingw\install","opencv\build_mingw\install","opencv\install","tools\opencv\build_mingw\install")) {
            $p = $drive + $sub
            $candidate = Test-OpenCVInstall $p
            if ($candidate) { break }
        }
        if ($candidate) { break }
    }
}

$candidateOk = $false
if ($candidate) {
    $opencvInstall = $candidate.Install
    $opencvLibDir  = $candidate.Lib
    $opencvDllDir  = if ($candidate.Dll) { $candidate.Dll } else { Join-Path $opencvInstall "x64\mingw\bin" }
    Ok "找到一个 OpenCV: $opencvInstall"
    Info "自检中：编译+运行一个 5 秒的小程序，确认它能用当前编译器..."
    $candidateOk = Test-OpenCVCompiles $opencvLibDir (Join-Path $opencvInstall "include") $opencvDllDir $gpp
    if ($candidateOk) {
        Ok "自检通过，该 OpenCV 可用！"
    } else {
        Warn "自检失败：这个 OpenCV 与当前编译器不兼容（可能是 MSVC 版、损坏，或编译器太旧）。"
        Warn "改为从源码重新编译一份适合本机的 OpenCV。"
        $opencvInstall = ""; $opencvLibDir = ""; $opencvDllDir = ""
    }
}
if ($candidateOk) {
    Ok "使用 OpenCV:"
    Ok "  install   : $opencvInstall"
    Ok "  OpenCV_DIR: $opencvLibDir"
    if (-not $opencvDllDir) { Warn "没找到 OpenCV 的 DLL 目录，运行 exe 时可能报缺 dll" }
} elseif ($SkipOpenCVBuild) {
    Err "-SkipOpenCVBuild 已指定，但本机没有可用的 OpenCV，无法继续。"
    Pause-IfNeeded; exit 1
} else {
    # ---------- 处理：本机没有现成 OpenCV ----------
    # 先问一句：有没有别人（学长）给的 install 文件夹？有就跳过编译，几十秒搞定
    $script:haveInstall = $false
    if (-not $NoPause) {
        Write-Host ""
        $ans = Read-Host "  有没有别人给你的 OpenCV install 文件夹？有就输入它的路径（直接回车则从源码编译，约30~60分钟）"
        $ans = $ans.Trim().Trim('"')
        if ($ans) {
            $c = Test-OpenCVInstall $ans
            if ($c) {
                $opencvInstall = $c.Install
                $opencvLibDir  = $c.Lib
                $opencvDllDir  = if ($c.Dll) { $c.Dll } else { Join-Path $c.Install "x64\mingw\bin" }
                Info "自检中：确认这个 install 能用当前编译器..."
                if (Test-OpenCVCompiles $opencvLibDir (Join-Path $opencvInstall "include") $opencvDllDir $gpp) {
                    $script:haveInstall = $true
                    Ok "自检通过，直接使用该 install 文件夹，跳过编译！"
                } else {
                    Warn "这个 install 与当前编译器不兼容（可能是 MSVC 版/损坏），改为从源码编译。"
                }
            } else {
                Warn "该路径不是有效的 OpenCV install 文件夹，改为从源码编译。"
            }
        }
    }

    if (-not $script:haveInstall) {
        # ---------- 需要从源码编译 ----------
        Info "没有找到可用的 MinGW 版 OpenCV，开始从源码编译（只需做一次，约 30~60 分钟）..."

    # 下载源码（若 C:\dev\opencv\opencv\sources 已存在则复用）
    $srcRoot = Join-Path $opencvBase "opencv"
    $srcDir  = Join-Path $srcRoot "sources"
    if (-not (Test-Path (Join-Path $srcDir "CMakeLists.txt"))) {
        New-Item -ItemType Directory -Force -Path $opencvBase | Out-Null
        $zip = Join-Path $opencvBase "opencv-$OpenCV_VER.zip"
        if (-not (Test-Path $zip)) {
            Info "下载 OpenCV $OpenCV_VER 源码（约 100MB）..."
            $curl = Find-Exe "curl"
            # 依次尝试：GitHub 官方 zip → GitHub 直连 → git clone（实测国内可能时好时坏，都试一遍）
            $urls = @(
                $OpenCV_TAG_URL,
                "https://codeload.github.com/opencv/opencv/zip/refs/tags/$OpenCV_VER"
            )
            $ok = $false
            foreach ($u in $urls) {
                Info "尝试下载: $u"
                try {
                    if ($curl) {
                        & $curl -L --fail --connect-timeout 15 -o $zip $u
                        if ($LASTEXITCODE -eq 0 -and (Test-Path $zip)) { $ok = $true; break }
                    } else {
                        Invoke-WebRequest -Uri $u -OutFile $zip -TimeoutSec 600
                        if (Test-Path $zip) { $ok = $true; break }
                    }
                } catch {
                    Warn "下载失败: $($_.Exception.Message)"
                    Remove-Item $zip -Force -ErrorAction SilentlyContinue
                }
            }
            # 都不行 → 再试 git clone（有时 git 能通而 curl 不行）
            if (-not $ok -and $git) {
                Info "改用 git clone 获取源码（可能更稳）..."
                if (Test-Path $srcDir) { Remove-Item $srcDir -Recurse -Force -ErrorAction SilentlyContinue }
                & git clone --depth 1 --branch $OpenCV_VER https://github.com/opencv/opencv.git $srcDir
                if ($LASTEXITCODE -eq 0 -and (Test-Path (Join-Path $srcDir "CMakeLists.txt"))) { $ok = $true }
                else { Remove-Item $srcDir -Recurse -Force -ErrorAction SilentlyContinue }
            }
            if (-not $ok) {
                Err "自动下载失败。请手动获取源码（三选一）："
                Err "  1) 浏览器打开 $OpenCV_TAG_URL 下载 zip，解压后把内容放进:"
                Err "     $srcDir"
                Err "  2) 有 git 的话执行: git clone --depth 1 --branch $OpenCV_VER https://github.com/opencv/opencv.git `"$srcDir`""
                Err "  3) 问学长要一份编译好的 install 文件夹，用 -OpenCVDir 指定路径跳过编译"
                Pause-IfNeeded; exit 1
            }
        }
        Info "解压源码..."
        try {
            Expand-Archive -Path $zip -DestinationPath $srcRoot -Force
        } catch {
            Err "解压失败，可能下载不完整。请删除 $zip 后重新运行脚本。"
            Pause-IfNeeded; exit 1
        }
        # 解压出来是 opencv-4.13.0/，改成 sources/
        $extracted = Join-Path $srcRoot "opencv-$OpenCV_VER"
        # 注意：cmdlet 后直接跟 -and 在旧版 PowerShell 会报"找不到参数 and"，务必加括号
        if ((Test-Path $extracted) -and (-not (Test-Path $srcDir))) {
            Move-Item $extracted $srcDir
        }
    }
    if (-not (Test-Path (Join-Path $srcDir "CMakeLists.txt"))) {
        Err "OpenCV 源码目录不完整: $srcDir"; Pause-IfNeeded; exit 1
    }

    # 配置
    $buildDir = Join-Path $srcRoot "build_mingw"
    $installPrefix = Join-Path $buildDir "install"
    $gppFwd = To-Forward $gpp
    $makeFwd = To-Forward $make
    Info "配置 CMake（这一步只做检查，很快）..."
    & cmake -S $srcDir -B $buildDir -G "MinGW Makefiles" `
        "-DCMAKE_MAKE_PROGRAM=$makeFwd" `
        "-DCMAKE_C_COMPILER=$gppFwd" `
        "-DCMAKE_CXX_COMPILER=$gppFwd" `
        -DCMAKE_BUILD_TYPE=Release `
        -DBUILD_SHARED_LIBS=ON `
        -DBUILD_opencv_world=ON `
        -DBUILD_EXAMPLES=OFF `
        -DBUILD_TESTS=OFF `
        -DBUILD_PERF_TESTS=OFF `
        -DBUILD_opencv_python2=OFF `
        -DBUILD_opencv_python3=OFF `
        -DWITH_FFMPEG=OFF `
        -DWITH_OPENCL=OFF `
        "-DBUILD_LIST=core,imgproc,imgcodecs,highgui,videoio,flann,features2d,calib3d,objdetect,photo" `
        "-DCMAKE_INSTALL_PREFIX=$installPrefix"
    if ($LASTEXITCODE -ne 0) { Err "CMake 配置失败"; Pause-IfNeeded; exit 1 }

    # 编译
    $jobs = Get-CPUCount
    Info "开始编译（多核并行 $jobs 任务，耐心等待，约 30~60 分钟）..."
    & cmake --build $buildDir -j $jobs
    if ($LASTEXITCODE -ne 0) { Err "编译失败，请把日志发给懂的人看看"; Pause-IfNeeded; exit 1 }

    # 安装
    Info "安装到: $installPrefix"
    & cmake --install $buildDir
    if ($LASTEXITCODE -ne 0) { Err "安装失败"; Pause-IfNeeded; exit 1 }

        $opencvInstall = $installPrefix
        $opencvLibDir  = Join-Path $installPrefix "x64\mingw\lib"
        $opencvDllDir  = Join-Path $installPrefix "x64\mingw\bin"
        Ok "OpenCV 编译并安装完成！"
    }
}

# 验证 OpenCV
$verExe = Join-Path $opencvDllDir "opencv_version.exe"
if (Test-Path $verExe) {
    $v = & $verExe
    Ok "opencv_version 输出: $v"
} else {
    Warn "未找到 opencv_version.exe（不一定是问题）"
}

# ---------------- 第 3 步：写 .vscode 配置 ----------------
Step "3/4 自动写入 VS Code 配置 (.vscode/)"

$vscodeDir = Join-Path $repo ".vscode"
New-Item -ItemType Directory -Force -Path $vscodeDir | Out-Null

$gppBinF      = To-Forward $gppBin
$opencvInsF   = To-Forward $opencvInstall
$opencvLibF   = To-Forward $opencvLibDir
$opencvDllF   = To-Forward $opencvDllDir

# --- c_cpp_properties.json ---
$cppProps = @'
{
    // ============================================================
    // VS Code 智能提示 (IntelliSense) 配置 —— 给代码补全/跳转用
    // 修改提示：把下面 "opencvInstall" 改成你自己 OpenCV 安装目录
    // （本脚本已自动填写本机路径，一般不用再改）
    // ============================================================
    "env": {
        // 你的 MinGW 编译器路径（g++ 所在目录）
        "mingwBin": "__MINGW_BIN__",
        // 你的 OpenCV install 目录（里面应有 include/ 和 lib/）
        "opencvInstall": "__OPENCV_INSTALL__"
    },
    "configurations": [
        {
            "name": "Win32 (MinGW + OpenCV)",
            "includePath": [
                "${workspaceFolder}/**",
                "${env:opencvInstall}/include",
                "${env:opencvInstall}/include/opencv2"
            ],
            "defines": ["_DEBUG", "UNICODE", "_UNICODE"],
            // 告诉 IntelliSense 用哪个编译器，语法提示才准
            "compilerPath": "${env:mingwBin}/g++.exe",
            "cStandard": "c17",
            "cppStandard": "c++17",
            "intelliSenseMode": "windows-gcc-x64"
        }
    ],
    "version": 4
}
'@
$cppProps = $cppProps.Replace('__MINGW_BIN__', $gppBinF).Replace('__OPENCV_INSTALL__', $opencvInsF)
[System.IO.File]::WriteAllText((Join-Path $vscodeDir "c_cpp_properties.json"), $cppProps + "`n", (New-Object System.Text.UTF8Encoding($false)))
Ok "已写入 c_cpp_properties.json"

# --- tasks.json ---
$tasks = @'
{
    // ============================================================
    // 编译任务：在 VS Code 里按 Ctrl+Shift+B 一键编译
    // 原理：调 cmake 配置 + 编译，产物输出到 build/ 目录
    // 说明：用 Ninja 生成器（仓库自带 tools/ninja.exe），支持中文路径
    // 修改提示：本脚本已自动填好下面几个路径，一般不用再改
    // ============================================================
    "version": "2.0.0",
    "options": {
        "cwd": "${workspaceFolder}"
    },
    "tasks": [
        {
            "label": "cmake-configure",
            "type": "shell",
            "command": "cmake",
            "args": [
                "-S", ".",
                "-B", "build",
                "-G", "Ninja",
                "-DCMAKE_MAKE_PROGRAM=${workspaceFolder}/tools/ninja.exe",
                "-DCMAKE_CXX_COMPILER=__MINGW_BIN__/g++.exe",
                "-DCMAKE_BUILD_TYPE=Release",
                "-DOpenCV_DIR=__OPENCV_LIB__"
            ],
            "problemMatcher": ["$gcc"],
            "group": "build"
        },
        {
            "label": "cmake-build",
            "type": "shell",
            "command": "cmake",
            "args": ["--build", "build", "-j"],
            "problemMatcher": ["$gcc"],
            "group": { "kind": "build", "isDefault": true },
            "dependsOn": ["cmake-configure"]
        }
    ]
}
'@
$tasks = $tasks.Replace('__MINGW_BIN__', $gppBinF).Replace('__OPENCV_LIB__', $opencvLibF)
[System.IO.File]::WriteAllText((Join-Path $vscodeDir "tasks.json"), $tasks + "`n", (New-Object System.Text.UTF8Encoding($false)))
Ok "已写入 tasks.json"

# --- launch.json ---
$launch = @'
{
    // ============================================================
    // 调试配置：F5 一键编译 + 启动调试（基于 gdb）
    // 说明：environment.PATH 里加了 OpenCV 的 DLL 目录，保证运行时
    //       能找到 opencv_world*.dll；想调试哪个示例改 program 即可
    // ============================================================
    "version": "0.2.0",
    "configurations": [
        {
            "name": "调试 01_display_image (gdb)",
            "type": "cppdbg",
            "request": "launch",
            "program": "${workspaceFolder}/build/01_display_image.exe",
            "args": [],
            "stopAtEntry": false,
            "cwd": "${workspaceFolder}",
            "environment": [
                {
                    "name": "PATH",
                    "value": "__OPENCV_DLL__;__MINGW_BIN__;${env:PATH}"
                }
            ],
            "externalConsole": true,
            "MIMode": "gdb",
            "miDebuggerPath": "__MINGW_BIN__/gdb.exe",
            "setupCommands": [
                {
                    "description": "启用 gdb 美化打印（看 cv::Mat 更直观）",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": true
                }
            ],
            "preLaunchTask": "cmake-build"
        }
    ]
}
'@
$launch = $launch.Replace('__OPENCV_DLL__', $opencvDllF).Replace('__MINGW_BIN__', $gppBinF)
[System.IO.File]::WriteAllText((Join-Path $vscodeDir "launch.json"), $launch + "`n", (New-Object System.Text.UTF8Encoding($false)))
Ok "已写入 launch.json"

# ---------------- 第 4 步：编译本仓库示例并验证 ----------------
Step "4/4 编译示例项目并验证"

# 中文/非 ASCII 路径：MinGW Makefiles 生成器不支持，用仓库自带 ninja（Ninja 生成器）即可
$script:ninja = Resolve-Ninja
if ($repo -match '[^\x00-\x7F]') {
    if ($script:ninja) {
        Info "检测到仓库路径含中文：$repo"
        Info "已自动使用内置 ninja 构建（中文路径也 OK）。"
    } else {
        Warn "检测到仓库路径含中文，且未找到 ninja。"
        Warn "MinGW Makefiles 生成器不支持中文路径，建议把项目移到纯英文路径（如 C:\opencv）后重试。"
    }
}

Push-Location $repo
# 保证全新配置：清掉旧的 build（示例很小，重编只需几秒）
if (Test-Path (Join-Path $repo "build")) {
    Info "清理旧的 build 目录（示例很小，重新编译很快）..."
    Remove-Item (Join-Path $repo "build") -Recurse -Force -ErrorAction SilentlyContinue
}
if ($script:ninja) {
    $ninjaF = To-Forward $script:ninja
    Info "使用 Ninja 构建: $script:ninja"
    & cmake -S . -B build -G Ninja `
        "-DCMAKE_MAKE_PROGRAM=$ninjaF" `
        "-DCMAKE_CXX_COMPILER=$gppBinF/g++.exe" `
        -DCMAKE_BUILD_TYPE=Release `
        "-DOpenCV_DIR=$opencvLibDir"
} else {
    & cmake -S . -B build -G "MinGW Makefiles" `
        "-DCMAKE_MAKE_PROGRAM=$gppBinF/mingw32-make.exe" `
        "-DCMAKE_CXX_COMPILER=$gppBinF/g++.exe" `
        -DCMAKE_BUILD_TYPE=Release `
        "-DOpenCV_DIR=$opencvLibDir"
}
if ($LASTEXITCODE -eq 0) {
    & cmake --build build -j (Get-CPUCount)
}
$buildOk = ($LASTEXITCODE -eq 0)
Pop-Location

# ---------------- 收尾 ----------------
Write-Host ""
Write-Host "==================== 完成！====================" -ForegroundColor Green
if ($buildOk) {
    Ok "示例已全部编译成功："
    Ok "  build\01_display_image.exe   （读图显示）"
    Ok "  build\02_grayscale.exe       （灰度转换）"
    Ok "  build\03_camera.exe          （摄像头）"
} else {
    Warn "示例编译失败。常见原因与解决办法："
    Warn "  1) 编译器太旧（gcc 4.x/5.x）：OpenCV 4.x 需要较新编译器，装最新版 MinGW-w64 后重跑"
    Warn "  2) 报错含 Mutex / recursive_mutex / template argument 1 is invalid："
    Warn "     说明 OpenCV 与编译器不匹配（用了 MSVC 版或别的编译器编的）。删掉 C:\dev\opencv 下"
    Warn "     旧的 install 文件夹后重跑，脚本会从源码编译一份适合本机的。"
    Warn "  3) 报错找不到 .dll：确认 install 目录的 bin 里有 libopencv_world*.dll"
    Warn "  请把上面的日志发给懂的人看看。"
}
Write-Host ""
Say "接下来在 VS Code 里："
Say "  1) 文件 → 打开文件夹 → 选择本目录"
Say "  2) 打开 src\\01_display_image.cpp，按 Ctrl+Shift+B 编译"
Say "  3) 在集成终端运行:  .\\build\\01_display_image.exe"
Say "  4) 想调试就按 F5"
Write-Host ""
Pause-IfNeeded

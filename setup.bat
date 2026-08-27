@echo off
chcp 65001 >nul
title OpenCV + C++ 一键环境配置
echo.
echo   即将开始配置 OpenCV + C++ (MinGW) 开发环境...
echo   请全程保持网络连接，不要关闭本窗口。
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
if errorlevel 1 pause

@echo off
chcp 65001 >nul
title OpenCV + C++ One-click Setup
echo.
echo   This script sets up OpenCV + C++ (MinGW) automatically.
echo   Keep this window open and stay online.
echo   First run may take 30-60 minutes (compiling OpenCV).
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
if errorlevel 1 pause

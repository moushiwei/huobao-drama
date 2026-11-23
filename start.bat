@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0"

echo ========================================
echo   火宝短剧  一键启动
echo ========================================
echo.

where node >nul 2>&1
if errorlevel 1 (
  echo [错误] 未找到 Node.js，请先安装 20+ 版本：https://nodejs.org
  pause
  exit /b 1
)

if not exist "backend\package.json" (
  echo [错误] 请把本脚本放在项目根目录（与 backend、frontend 文件夹同级）
  pause
  exit /b 1
)

if not exist "backend\node_modules\" (
  echo [安装] 后端依赖...
  pushd backend
  call npm install
  if errorlevel 1 (
    popd
    echo [错误] 后端 npm install 失败
    pause
    exit /b 1
  )
  popd
  echo.
)

if not exist "frontend\node_modules\" (
  echo [安装] 前端依赖...
  pushd frontend
  call npm install
  if errorlevel 1 (
    popd
    echo [错误] 前端 npm install 失败
    pause
    exit /b 1
  )
  popd
  echo.
)

call :port_in_use 5679
if errorlevel 1 (
  echo [启动] 后端  http://127.0.0.1:5679
  start "火宝短剧-后端" /D "%~dp0backend" cmd /k "chcp 65001 >nul & title 火宝短剧-后端 & npm run dev"
) else (
  echo [跳过] 后端已在 5679 端口运行
)

call :port_in_use 3013
if errorlevel 1 (
  echo [启动] 前端  http://127.0.0.1:3013
  start "火宝短剧-前端" /D "%~dp0frontend" cmd /k "chcp 65001 >nul & title 火宝短剧-前端 & set NUXT_TELEMETRY_DISABLED=1& npm run dev -- --host 127.0.0.1 --port 3013"
) else (
  echo [跳过] 前端已在 3013 端口运行
)

echo.
echo [等待] 前端就绪（最多 90 秒）...
set /a _n=0
:wait_fe
call :port_in_use 3013
if not errorlevel 1 goto ready
set /a _n+=1
if !_n! GTR 90 (
  echo [错误] 等待超时。请查看「火宝短剧-前端」窗口里的报错。
  pause
  exit /b 1
)
timeout /t 1 /nobreak >nul
goto wait_fe

:ready
echo [打开] http://127.0.0.1:3013
start "" "http://127.0.0.1:3013"
echo.
echo 启动完成。关闭「火宝短剧-后端 / 前端」两个窗口即可停止。
timeout /t 4 /nobreak >nul
exit /b 0

:port_in_use
powershell -NoProfile -Command "try { $c = New-Object Net.Sockets.TcpClient; $c.Connect('127.0.0.1', %~1); $c.Close(); exit 0 } catch { exit 1 }" >nul 2>&1
exit /b %errorlevel%

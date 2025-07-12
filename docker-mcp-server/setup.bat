@echo off
echo 🐳 Docker MCP Server Setup
echo.

REM Check if Node.js is installed
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js is not installed. Please install Node.js first.
    echo Download from: https://nodejs.org/
    pause
    exit /b 1
)

echo ✅ Node.js is installed
echo.

REM Check if Docker is running
docker version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker is not running or not installed.
    echo Please start Docker or install Docker Desktop.
    pause
    exit /b 1
)

echo ✅ Docker is running
echo.

REM Install dependencies
echo 📦 Installing dependencies...
call npm install
if %errorlevel% neq 0 (
    echo ❌ Failed to install dependencies
    pause
    exit /b 1
)

echo ✅ Dependencies installed
echo.

REM Build the project
echo 🔨 Building project...
call npm run build
if %errorlevel% neq 0 (
    echo ❌ Failed to build project
    pause
    exit /b 1
)

echo ✅ Project built successfully
echo.

REM Run basic test
echo 🧪 Running basic test...
node test.js

echo.
echo 🎉 Setup completed successfully!
echo.
echo To use with Claude Desktop, add this to your claude_desktop_config.json:
echo.
echo {
echo   "mcpServers": {
echo     "docker": {
echo       "command": "node",
echo       "args": ["%CD%\\dist\\index.js"],
echo       "env": {
echo         "DOCKER_HOST": "tcp://127.0.0.1:2375"
echo       }
echo     }
echo   }
echo }
echo.
echo Claude Desktop config location: %%APPDATA%%\Claude\claude_desktop_config.json
echo.
pause
#!/usr/bin/env pwsh

Write-Host "🐳 Docker MCP Server Setup" -ForegroundColor Cyan
Write-Host ""

# Check if Node.js is installed
try {
    $nodeVersion = node --version
    Write-Host "✅ Node.js is installed: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js is not installed. Please install Node.js first." -ForegroundColor Red
    Write-Host "Download from: https://nodejs.org/" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""

# Check if Docker is running
try {
    docker version | Out-Null
    Write-Host "✅ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not running or not installed." -ForegroundColor Red
    Write-Host "Please start Docker or install Docker Desktop." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""

# Install dependencies
Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
try {
    npm install
    Write-Host "✅ Dependencies installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""

# Build the project
Write-Host "🔨 Building project..." -ForegroundColor Yellow
try {
    npm run build
    Write-Host "✅ Project built successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to build project" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""

# Run basic test
Write-Host "🧪 Running basic test..." -ForegroundColor Yellow
node test.js

Write-Host ""
Write-Host "🎉 Setup completed successfully!" -ForegroundColor Green
Write-Host ""

$currentPath = (Get-Location).Path
$configPath = "$env:APPDATA\Claude\claude_desktop_config.json"

Write-Host "To use with Claude Desktop, add this to your claude_desktop_config.json:" -ForegroundColor Cyan
Write-Host ""
Write-Host '{' -ForegroundColor Gray
Write-Host '  "mcpServers": {' -ForegroundColor Gray
Write-Host '    "docker": {' -ForegroundColor Gray
Write-Host "      `"command`": `"node`"," -ForegroundColor Gray
Write-Host "      `"args`": [`"$currentPath\\dist\\index.js`"]," -ForegroundColor Gray
Write-Host '      "env": {' -ForegroundColor Gray
Write-Host '        "DOCKER_HOST": "tcp://127.0.0.1:2375"' -ForegroundColor Gray
Write-Host '      }' -ForegroundColor Gray
Write-Host '    }' -ForegroundColor Gray
Write-Host '  }' -ForegroundColor Gray
Write-Host '}' -ForegroundColor Gray
Write-Host ""
Write-Host "Claude Desktop config location: $configPath" -ForegroundColor Yellow
Write-Host ""

Read-Host "Press Enter to exit"
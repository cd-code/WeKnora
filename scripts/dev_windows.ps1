<#
.SYNOPSIS
    Windows 本地开发环境专属启动脚本
.DESCRIPTION
    由于 WeKnora 包含 CGO 依赖并且在 Windows 编译时需要特殊环境，
    本脚本用来检查依赖、设定环境变量、并借助 godotenv 读取 .env 启动项目。
#>

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "     WeKnora Windows Dev Starter" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. 检查项目根目录与 .env 文件
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$EnvPath = Join-Path $ProjectRoot ".env"

if (-not (Test-Path $EnvPath)) {
    Write-Host "[错误] 找不到 .env 文件！" -ForegroundColor Red
    Write-Host "请在项目根目录 ($ProjectRoot) 将 .env.example 复制为 .env，并修改好数据库等配置。" -ForegroundColor Yellow
    exit 1
}

# 2. 检查 Go 环境
if (-not (Get-Command "go" -ErrorAction SilentlyContinue)) {
    Write-Host "[错误] 找不到 'go' 命令，请确保已安装 Golang 并配置了环境变量 PATH。" -ForegroundColor Red
    exit 1
}

# 3. 检查 gcc 环境 (编译鸭子数据库 duckdb-go 需要的 CGO 基础环境)
if (-not (Get-Command "gcc" -ErrorAction SilentlyContinue)) {
    Write-Host "[警告] 没有检测到 'gcc' 编译器栈 (如 MinGW-w64)。" -ForegroundColor Yellow
    Write-Host "WeKnora 的 DuckDB 等依赖包含 CGO（C/C++）代码，在 Windows 本地直接 go run 时可能会报错失败。" -ForegroundColor Yellow
    Write-Host "建议安装 MSYS2、MinGW 等工具并将 gcc.exe 添加至 PATH 中。" -ForegroundColor Yellow
    Write-Host "如果你已经能够正常运行，可忽略此警告。" -ForegroundColor DarkGray
    Write-Host ""
}

# 4. 检查并安装第三方环境依赖 godotenv
if (-not (Get-Command "godotenv" -ErrorAction SilentlyContinue)) {
    Write-Host "[提示] 系统未检测到 'godotenv' 工具，准备自动通过 go install 获取..." -ForegroundColor Yellow
    try {
        go install github.com/joho/godotenv/cmd/godotenv@latest
        Write-Host "[成功] godotenv 安装完成！" -ForegroundColor Green
    } catch {
        Write-Host "[错误] godotenv 安装失败，请检查你的网络连接或 GOPROXY 代理设置。" -ForegroundColor Red
        exit 1
    }
}

# 5. 注入必选的启动环境变量配置
Write-Host "[配置] 正在注入 Windows 专属的编译和运行参数..." -ForegroundColor DarkGray

# 解决 duckdb 在 Windows/MinGW 下编译时缺失 pthread (POSIX 线程) 支持的问题
$env:CGO_LDFLAGS = "-lpthread"
Write-Host "  -> 已设置 `$env:CGO_LDFLAGS = '-lpthread'" -ForegroundColor DarkGray

# 解决引入的 qdrant 和 milvus 第三方库中生成了同名 protobuf 致使的原生依赖冲突 panic
$env:GOLANG_PROTOBUF_REGISTRATION_CONFLICT = "warn"
Write-Host "  -> 已设置 `$env:GOLANG_PROTOBUF_REGISTRATION_CONFLICT = 'warn'" -ForegroundColor DarkGray

# 切换到项目根目录
Set-Location $ProjectRoot

Write-Host ""
Write-Host "[启动] 正在启动后端主服务... (由于包含底层 C 库，首次编译速度可能较慢，请耐心等待)" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

# 6. 使用 godotenv 读取 .env 启动
try {
    & godotenv -f .env go run .\cmd\server\main.go
} catch {
    Write-Host "[错误] 服务因异常中断: $_" -ForegroundColor Red
    exit 1
}

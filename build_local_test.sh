#!/bin/bash

# PandoraTrader 本地构建测试脚本
# 用于在推送到 GitHub 之前验证构建是否成功

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 检查系统类型
print_header "检测系统环境"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    SYSTEM_TYPE="Linux"
    echo "检测到 Linux 系统"
    
    # 检查是否是 Ubuntu
    if command -v lsb_release >/dev/null 2>&1; then
        DISTRO=$(lsb_release -is)
        VERSION=$(lsb_release -rs)
        echo "发行版: $DISTRO $VERSION"
    fi
    
elif [[ "$OSTYPE" == "darwin"* ]]; then
    SYSTEM_TYPE="macOS"
    echo "检测到 macOS 系统"
    SW_VERS=$(sw_vers -productVersion)
    echo "版本: macOS $SW_VERS"
else
    print_error "不支持的系统类型: $OSTYPE"
    exit 1
fi

# 检查必要的工具
print_header "检查构建工具"

check_command() {
    if command -v $1 >/dev/null 2>&1; then
        print_success "$1 已安装"
        $1 --version | head -1
    else
        print_error "$1 未找到"
        return 1
    fi
}

# 检查基本工具
check_command cmake || {
    print_error "请安装 CMake (版本 >= 3.8)"
    exit 1
}

check_command gcc || check_command clang || {
    print_error "请安装 C++ 编译器"
    exit 1
}

check_command g++ || check_command clang++ || {
    print_error "请安装 C++ 编译器"
    exit 1
}

# 检查系统特定依赖
if [[ "$SYSTEM_TYPE" == "Linux" ]]; then
    print_header "检查 Linux 特定依赖"
    
    # 检查 OpenMP
    if ldconfig -p | grep -q libomp; then
        print_success "OpenMP 库已安装"
    else
        print_warning "OpenMP 库可能未安装"
        echo "在 Ubuntu/Debian 上运行: sudo apt-get install libomp-dev"
        echo "在 CentOS/RHEL 上运行: sudo yum install libomp-devel"
    fi
    
elif [[ "$SYSTEM_TYPE" == "macOS" ]]; then
    print_header "检查 macOS 特定依赖"
    
    # 检查 Homebrew
    if command -v brew >/dev/null 2>&1; then
        print_success "Homebrew 已安装"
        
        # 检查 OpenMP
        if brew list | grep -q libomp; then
            print_success "OpenMP 已通过 Homebrew 安装"
        else
            print_warning "OpenMP 可能未安装"
            echo "运行: brew install libomp"
        fi
    else
        print_warning "Homebrew 未安装，可能影响依赖管理"
    fi
fi

# 检查项目依赖文件
print_header "检查项目依赖"

check_directory() {
    if [[ -d "$1" ]]; then
        print_success "目录存在: $1"
        echo "  文件数量: $(find "$1" -type f | wc -l)"
    else
        print_warning "目录不存在: $1"
        return 1
    fi
}

check_directory "Interface/include"
check_directory "Interface/lib"

if [[ "$SYSTEM_TYPE" == "Linux" ]]; then
    check_directory "Interface/lib/Linux/Debug" || check_directory "Interface/lib/Ubuntu/Debug"
    check_directory "Interface/CTPTradeApiLinux"
elif [[ "$SYSTEM_TYPE" == "macOS" ]]; then
    check_directory "Interface/lib/MacOS/Debug"
    check_directory "Interface/CTPTradeApiMacOS"
fi

# 清理之前的构建
print_header "清理构建环境"
if [[ -d "build" ]]; then
    echo "删除旧的 build 目录..."
    rm -rf build
fi

if [[ -d "bin" ]]; then
    echo "删除旧的 bin 目录..."
    rm -rf bin
fi

# 创建构建目录
mkdir -p build
cd build

# 配置构建
print_header "配置 CMake"
BUILD_TYPE=${BUILD_TYPE:-Debug}
echo "构建类型: $BUILD_TYPE"

CMAKE_ARGS=(
    ".."
    "-DCMAKE_BUILD_TYPE=$BUILD_TYPE"
    "-DCMAKE_VERBOSE_MAKEFILE=ON"
)

# macOS 特定配置
if [[ "$SYSTEM_TYPE" == "macOS" ]]; then
    if [[ -d "/opt/homebrew" ]]; then
        # Apple Silicon Mac
        CMAKE_ARGS+=("-DCMAKE_PREFIX_PATH=/opt/homebrew")
    else
        # Intel Mac
        CMAKE_ARGS+=("-DCMAKE_PREFIX_PATH=/usr/local")
    fi
fi

echo "CMake 命令: cmake ${CMAKE_ARGS[*]}"
cmake "${CMAKE_ARGS[@]}"

# 构建项目
print_header "构建 PandoraStrategy"
cmake --build . --target PandoraStrategy --config $BUILD_TYPE -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)

print_header "构建 PandoraSimulator"
cmake --build . --target PandoraSimulator --config $BUILD_TYPE -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)

print_header "构建 PandoraTrader"
cmake --build . --target PandoraTrader --config $BUILD_TYPE -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)

# 回到项目根目录
cd ..

# 验证构建结果
print_header "验证构建结果"

check_executable() {
    local exe_path="$1"
    local exe_name="$2"
    
    if [[ -f "$exe_path" ]]; then
        print_success "$exe_name 构建成功"
        echo "  路径: $exe_path"
        echo "  大小: $(du -sh "$exe_path" | cut -f1)"
        
        # 检查可执行文件依赖（Linux）
        if [[ "$SYSTEM_TYPE" == "Linux" ]] && command -v ldd >/dev/null 2>&1; then
            echo "  依赖库:"
            ldd "$exe_path" 2>/dev/null | head -5 || echo "    无法检查依赖"
        fi
        
        # 检查可执行文件依赖（macOS）
        if [[ "$SYSTEM_TYPE" == "macOS" ]] && command -v otool >/dev/null 2>&1; then
            echo "  依赖库:"
            otool -L "$exe_path" 2>/dev/null | head -5 || echo "    无法检查依赖"
        fi
    else
        print_error "$exe_name 构建失败"
        return 1
    fi
}

# 检查可执行文件
check_executable "bin/Debug/PandoraSimulator" "PandoraSimulator"
check_executable "bin/Debug/PandoraTrader" "PandoraTrader"

# 检查库文件
if [[ -f "bin/Debug/libPandoraStrategy.a" ]]; then
    print_success "PandoraStrategy 库构建成功"
else
    print_warning "PandoraStrategy 库文件未找到"
fi

# 显示构建总结
print_header "构建总结"
echo "构建目录大小: $(du -sh build | cut -f1)"
echo "输出目录大小: $(du -sh bin | cut -f1 2>/dev/null || echo "未知")"

print_success "本地构建测试完成！"
echo ""
echo "如果所有检查都通过，你可以安全地推送代码到 GitHub。"
echo "GitHub Actions 将会在以下环境中自动构建："
echo "  - Ubuntu 20.04 LTS"
echo "  - Ubuntu 22.04 LTS" 
echo "  - macOS 12 (Monterey)"
echo "  - macOS 13 (Ventura)"
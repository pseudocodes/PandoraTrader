# GitHub Actions 构建配置

本目录包含了 PandoraTrader 项目的自动化构建配置。

## 🚀 工作流概览

### 1. 主构建流程 (`build.yml`) - Matrix 并行构建

**触发条件：**
- 推送到 `main`, `ndev`, `develop` 分支
- 对这些分支的 Pull Request

**功能特性：**
- ✅ **Matrix 并行构建**：4个构建配置同时执行
  - Ubuntu x86_64 Release + Ubuntu x86_64 Debug
  - macOS arm64 Release + macOS arm64 Debug (Apple Silicon)
- ✅ 详细的系统信息收集和依赖检查
- ✅ 按顺序构建：PandoraStrategy → PandoraSimulator → PandoraTrader
- ✅ 构建产物验证和依赖关系检查
- ✅ Matrix 构建状态汇总报告

**Matrix 配置：**
- **平台**: ubuntu-latest (x86_64), macos-latest (arm64)
- **构建类型**: Release (优化), Debug (调试)
- **并行执行**: fail-fast: false (不会因单个失败中止其他构建)

**特殊配置：**
- Ubuntu x86_64: 使用最新版本，安装 OpenMP 等必要依赖
- macOS arm64: 使用 Apple Silicon Homebrew (`/opt/homebrew/`) + 原生执行

### 2. 简化构建测试 (`build-simple.yml`)

**触发条件：**
- 手动触发 (workflow_dispatch)
- 当源代码或构建配置发生变化时

**功能特性：**
- ⚡ 快速构建验证（Matrix 并行构建）
- 🎯 仅验证构建是否成功
- 📦 更少的输出和检查
- ⏱️ 更快的反馈时间

## 🔧 构建流程详解

### 构建顺序
```
1. PandoraStrategy (静态库)
   ├── 输出: libPandoraStrategy.a
   └── 位置: bin/Release/

2. PandoraSimulator (可执行文件)
   ├── 依赖: libPandoraStrategy.a
   ├── 需要: OpenMP, pthread
   └── 输出: bin/Release/PandoraSimulator

3. PandoraTrader (可执行文件)
   ├── 依赖: libPandoraStrategy.a
   ├── 需要: CTP API, pthread
   └── 输出: bin/Release/PandoraTrader
```

### 平台特定配置

#### Ubuntu
```yaml
dependencies:
  - cmake (>= 3.8)
  - build-essential
  - libomp-dev
  - libssl-dev
  - pkg-config
  - lsb-release
```

#### macOS
```yaml
dependencies:
  - cmake (via x86_64 Homebrew)
  - libomp (via x86_64 Homebrew)
architecture: x86_64 (强制)
homebrew_path: /usr/local/bin/brew
```

## 📊 构建状态检查

### 验证项目
- ✅ 库文件存在性检查
- ✅ 可执行文件大小验证
- ✅ 动态库依赖检查（Linux: ldd, macOS: otool）
- ✅ 架构兼容性验证
- ✅ 基础运行测试

### 输出示例
```
✅ PandoraStrategy library built successfully
✅ PandoraSimulator built successfully
✅ PandoraTrader built successfully

File sizes:
  - libPandoraStrategy.a: 2.1M
  - PandoraSimulator: 8.3M  
  - PandoraTrader: 12.7M
```

## 🐛 故障排除

### 常见构建问题

#### 1. OpenMP 库未找到
**Ubuntu:**
```bash
sudo apt-get install libomp-dev
```

**macOS:**
```bash
arch -x86_64 /usr/local/bin/brew install libomp
export LDFLAGS="-L/usr/local/lib"
export CPPFLAGS="-I/usr/local/include"
```

#### 2. CTP 库缺失
确保以下文件存在：
- Linux: `Interface/CTPTradeApiLinux/*.so`
- macOS: `Interface/CTPTradeApiMacOS/*.framework`

#### 3. macOS 架构问题

**Apple Silicon 支持：**
项目现在专门针对 Apple Silicon (ARM64) 进行优化：
- 使用原生 ARM64 Homebrew (`/opt/homebrew/`)
- 原生编译，无需 Rosetta2 转换
- 充分利用 Apple Silicon 性能优势

**手动构建：**
```bash
# 在 Apple Silicon Mac 上
brew install cmake libomp
cmake .. -DCMAKE_OSX_ARCHITECTURES=arm64
```

**GitHub Actions 配置：**
工作流专门构建 Apple Silicon 版本

#### 4. 依赖顺序问题
确保按正确顺序构建：
1. PandoraStrategy (被其他组件依赖)
2. PandoraSimulator & PandoraTrader (可并行)

## 📁 构建产物

构建成功后，可执行文件会生成在项目的 `bin/` 目录下：

```
bin/
├── Release/
│   ├── libPandoraStrategy.a
│   ├── PandoraSimulator
│   └── PandoraTrader
└── Debug/
    ├── libPandoraStrategy.a
    ├── PandoraSimulator
    └── PandoraTrader
```

**注意：** GitHub Actions 只进行构建验证，不上传构建产物。如需可执行文件，请在本地环境构建。

## 🔄 本地构建对比

如果 GitHub Actions 构建失败，可以使用本地构建脚本进行对比：

```bash
# 使用项目提供的本地构建脚本
chmod +x build_local_test.sh
./build_local_test.sh
```

这个脚本执行与 GitHub Actions 相似的构建步骤，有助于在本地重现和调试问题。
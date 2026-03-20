# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

Subconverter 是一个 C++20 编写的代理订阅格式转换工具，支持 Clash、Surge、Quantumult X、Loon、SS/SSR、V2Ray、Trojan、sing-box 等格式之间的互相转换。运行时作为 HTTP 服务器监听（默认端口 25500），接收转换请求。

## 构建命令

### macOS
```bash
bash scripts/build.macos.release.sh
```

### Linux (Alpine Docker)
```bash
bash scripts/build.alpine.release.sh
```

### Windows (MSYS2)
```bash
bash scripts/build.windows.release.sh
```

### 手动 CMake 构建（需先安装依赖）
```bash
cmake -DCMAKE_BUILD_TYPE=Release .
make -j$(nproc)
```

构建脚本会从源码克隆并编译所有依赖（yaml-cpp、quickjspp、libcron、toml11），最终静态链接生成 `base/subconverter` 二进制文件。

## 依赖库

外部依赖：libcurl、rapidjson、yaml-cpp、pcre2、QuickJS（通过 quickjspp）、libcron、toml11。`include/` 目录下包含 header-only 库：httplib（HTTP 服务器）、inja（Jinja2 模板引擎）、jpcre2（PCRE2 封装）、nlohmann/json。

## 架构

### 请求处理流程
`main.cpp` 在 `WebServer`（基于 httplib，位于 `src/server/`）上注册路由 → 请求到达 `src/handler/interfaces.cpp` 中的处理函数 → 核心接口 `/sub` 调用 `subconverter()`，依次执行：
1. 通过 `webGet()`（`src/handler/webget.cpp`）获取远程订阅 URL
2. 解析各种格式的代理节点（`src/parser/subparser.cpp`）
3. 节点处理：重命名、emoji、过滤、排序（`src/generator/config/nodemanip.cpp`）
4. 导出为目标格式（`src/generator/config/subexport.cpp`）

### 核心源码目录
- **`src/handler/`** - HTTP 请求处理、配置加载（`settings.cpp`）、网络请求、文件上传
- **`src/parser/`** - 订阅解析（`subparser.cpp` 处理所有输入格式）和信息提取
- **`src/generator/config/`** - 输出生成：`subexport.cpp`（格式转换）、`nodemanip.cpp`（节点过滤/排序）、`ruleconvert.cpp`（规则格式转换）
- **`src/generator/template/`** - Inja/Jinja2 模板渲染，用于配置文件生成
- **`src/server/`** - HTTP 服务器实现（基于 httplib）
- **`src/script/`** - QuickJS 脚本引擎和定时任务支持
- **`src/config/`** - 数据结构定义：`proxygroup.h`、`ruleset.h`、`regmatch.h`、`crontask.h`
- **`src/utils/`** - 工具函数：base64、MD5、正则、字符串操作、URL 编码、日志、文件 I/O

### 全局配置
`Settings` 结构体（定义于 `src/handler/settings.h`）以全局变量 `global` 实例化，持有所有运行时配置。配置文件按 `pref.toml` → `pref.yml` → `pref.ini` 的优先顺序读取。示例配置位于 `base/pref.example.*`。

### 运行时文件
`base/` 目录包含与二进制文件一起部署的运行时资源：配置模板、规则片段、代理组定义，以及各目标格式的基础配置。

## CMake 选项
- `BUILD_STATIC_LIBRARY` - 构建为静态库（仅包含核心源码子集，无 JS 运行时和网络请求功能）
- `USING_MALLOC_TRIM` - 请求处理后调用 malloc_trim 降低内存占用（仅 Linux）

# PHP-Windows-Portable

用于在 Windows 平台编译 PHP 的可移植版本构建系统。

## 项目说明

本项目提供了一套完整的构建脚本和 GitHub Actions 工作流，用于在 Windows x64 平台上编译 PHP 及其相关依赖。

## 特性

- 支持多个 PHP 版本编译
- 自动化下载和编译所有依赖库
- 包含必要的扩展支持
- GitHub Actions 自动构建和发布
- 生成可移植的 ZIP 包

## 支持的依赖

本构建系统会编译以下依赖库：

- **zlib** - 压缩库
- **OpenSSL** - SSL/TLS 加密库
- **libxml2** - XML 解析库
- **libcurl** - URL 传输库
- **libsqlite3** - SQLite 数据库引擎
- **libpng** - PNG 图像库
- **libjpeg** - JPEG 图像库
- **freetype** - 字体渲染库
- **libzip** - ZIP 归档库
- **libiconv** - 字符编码转换库
- **bzip2** - 压缩库
- **xz** - LZMA 压缩库
- **pcre2** - 正则表达式库
- **oniguruma** - 正则表达式库

## 编译要求

### 必需软件

- Windows 10/11 或 Windows Server 2019/2022
- Microsoft Visual Studio 2022 (Community/Professional/Enterprise)
- CMake 3.20 或更高版本
- Strawberry Perl
- NASM (用于 OpenSSL)
- Git

### 环境配置

构建脚本会自动检测 Visual Studio 安装路径，支持以下配置：

- 平台: x64
- 构建类型: Release 或 Debug
- OpenSSL 版本: 3.x

## 使用方法

### 本地编译

1. 克隆仓库：
```cmd
git clone https://github.com/ServBay/PHP-Windows-Portable.git
cd PHP-Windows-Portable
```

2. 设置环境变量（可选）：
```cmd
set BUILD_BASE_ENV=C:\Development\PHP\build
set PREFIX_ENV=C:\ServBay\packages\php
set PHP_VERSION=8.3.15
```

3. 运行构建脚本：
```cmd
build_php.bat
```

### GitHub Actions 自动构建

在 GitHub 仓库页面：

1. 进入 **Actions** 标签页
2. 选择 **"Build PHP for Windows x64"** 工作流
3. 点击 **"Run workflow"**
4. 输入 PHP 版本号（例如：8.3.15）
5. 点击 **"Run workflow"** 开始构建

构建完成后，会自动创建 GitHub Release 并上传编译好的 ZIP 包。

## 构建输出

编译完成后，会生成以下内容：

- 构建目录：`%BUILD_BASE%` (默认: `C:\Development\PHP\build`)
- 安装目录：`%PREFIX%` (默认: `C:\ServBay\packages\php`)
- ZIP 包：`php-{version}-win-x64.zip`

安装目录结构：
```
C:\ServBay\packages\php\
├── bin\           # PHP 可执行文件和 DLL
├── include\       # 开发头文件
├── lib\           # 静态和导入库
├── etc\           # 配置文件
└── share\         # 文档和其他资源
```

## 版本信息

当前支持的 PHP 版本：

- PHP 8.3.x
- PHP 8.2.x
- PHP 8.1.x

## 自定义编译选项

可以通过修改 `build_php.bat` 脚本来自定义编译选项：

- `PLATFORM`: 目标平台 (x64)
- `BUILD_TYPE`: 构建类型 (Release/Debug)
- `BUILD_OPENSSL3`: 使用 OpenSSL 3.x (TRUE/FALSE)
- `INSTALL_PDB`: 安装调试符号文件 (ON/OFF)

## 扩展支持

默认编译的 PHP 扩展包括：

- Core extensions: curl, mbstring, openssl, pdo, pdo_mysql, pdo_sqlite, zip
- Image processing: gd (with PNG, JPEG, FreeType support)
- Compression: bz2, zlib
- XML: xml, simplexml, xmlreader, xmlwriter
- Database: mysqli, pdo_mysql, pdo_sqlite, sqlite3

## 故障排除

### 常见问题

1. **找不到 Visual Studio**
   - 确保已安装 Visual Studio 2022
   - 检查 `VCVARSALL` 环境变量是否正确设置

2. **依赖下载失败**
   - 检查网络连接
   - 确认依赖库的 URL 是否有效

3. **编译错误**
   - 查看构建日志文件
   - 确保所有依赖已正确下载和解压
   - 检查磁盘空间是否充足

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

本项目遵循 Apache License 2.0 许可证。

## 参考资源

- [PHP 官方网站](https://www.php.net/)
- [PHP 源代码](https://github.com/php/php-src)
- [Windows PHP SDK](https://github.com/php/php-sdk-binary-tools)
- [Visual Studio](https://visualstudio.microsoft.com/)

## 致谢

本项目参考了 Apache HTTPd Windows 编译项目的设计思路和实现方式。

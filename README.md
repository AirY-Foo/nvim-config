# 我的 Neovim 配置

从现用 LazyVim 配置整理，支持 Windows 和 Linux。包含主题、补全、LSP、Git、Codex 选区操作及 Docker/ROS 工作流。插件版本由 `lazy-lock.json` 固定。

## 另一台 Windows 设备

下载/克隆本仓库后，在仓库目录执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -InstallDependencies -Extras
```

脚本通过 WinGet 补齐 Git、Neovim、ripgrep、fd、Node.js 和 GCC；`-Extras` 还会安装 Nushell、LazyGit、Yazi 和 fzf。需要系统带有 WinGet，部分软件安装可能触发系统提权。已存在的工具会跳过；已有 Neovim 需要至少 0.11.2，否则脚本会提示升级。

脚本会备份 `%LOCALAPPDATA%\nvim`，复制配置，编译可选的 DebDeploy askpass 小工具，安装锁定的插件及 Mason 语言服务器。初次执行需要能访问 GitHub、npm 等软件源。失败会保留备份和安装日志提示，解决网络/依赖问题后可重新执行。

已装好依赖时：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

只部署配置、稍后再下载插件：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -SkipPlugins
```

## 另一台 Linux 设备

Debian/Ubuntu 可执行：

```bash
bash install.sh --install-deps
```

它会通过 apt 安装基础依赖；系统 Neovim 版本不足时从官方 GitHub release 安装到 `~/.local/opt`，并创建 `~/.local/bin/nvim` 链接。请确保 `~/.local/bin` 在 PATH 中。脚本不修改 shell 启动文件。

其他发行版先安装 Neovim ≥ 0.11.2、Git、curl、ripgrep、fd、C 编译器、Node.js、npm、unzip 和 Python venv，再运行：

```bash
bash install.sh
```

默认配置目录是 `${XDG_CONFIG_HOME:-~/.config}/nvim`。Nushell、LazyGit、Yazi、fzf、Docker 和 Codex CLI 是额外功能所需工具，可以按需安装。某些 Mason npm 工具可能需要比发行版自带版本更新的 Node.js，建议使用 Node.js LTS。

## 本机设置与账号

基础配置不要求 Docker。需要原来的容器 C++/ROS 功能时，把**安装后的配置目录**中 `lua/config/local.example.lua` 复制成 `lua/config/local.lua`，修改以下内容：

```lua
return {
  codex_args = { "--no-daemon" }, -- 原设备的桌面版 Codex 参数
  docker = {
    enabled = true,
    container = "miivii_dev",
    host_root = "D:/workspace/src", -- 改成新设备路径
    container_root = "/home/nvidia/workspace/src",
    clangd = "clangd-12",
  },
}
```

普通 Codex CLI 若不支持 `--no-daemon`，使用 `codex_args = {}`（也是默认值）。Codex 可执行程序、CLI 登录及账号凭据需要在新设备单独准备，仓库不携带登录状态。

`local.lua` 被 Git 忽略，重新部署时会保留目标设备原有的此文件。不要将它作为公共配置上传；共享默认设置应修改 `machine.lua`。若在仓库中放了自己的 `local.lua`，部署时会优先复制它。

容器必须已存在并有对应源码挂载、ROS 依赖和 clangd。每个项目仍需生成自己的 `build/compile_commands.json`；它属于项目构建产物，不随编辑器配置分发。当前容器路由匹配 `igv_*` 和 `get_all_path_tools`，可在本地设置修改 `project_patterns`。原设备安装 clangd 的命令是：

```bash
docker exec miivii_dev apt-get install -y clangd-12
```

其他容器请按其发行版安装可用版本，并修改 `docker.clangd`。容器内 Linux 专属依赖头文件能参与解析，但没有镜像到 Windows，因此不能直接在 Windows 中打开。Docker 镜像、容器、ROS、X11 和项目源码都不包含在这个仓库里。

## 常用操作

| 按键/命令 | 功能 |
| --- | --- |
| `gd` / `gD` / `gr` | 定义 / 声明 / 引用 |
| `Space ch` | C/C++ 源文件与头文件切换 |
| `Ctrl-o` | 返回上一次位置 |
| 选中代码后 `Space as` | 解释、检查、优化建议、修复、测试建议、自定义要求 |
| `Space aa` / `Space ap` | 打开 Codex / 输入项目问题 |
| `Space gg` | LazyGit |
| `:Yazi` / `:Nushell` | 文件管理器 / Nushell |
| `:MiiviiShell` | 容器终端 |
| `:MiiviiCMakeConfigure` | 容器中运行 CMake 并导出编译数据库 |
| `:MiiviiCMakeBuild` | 容器中编译 |
| `:checkhealth` / `:Mason` / `:Lazy` | 检查环境 / 语言工具 / 插件管理 |

DebDeploy 保留原有功能，目前只提供 Windows askpass helper。其 C# 源码在 `tools/`，部署时编译；密码在运行时输入，不写入仓库。Linux 上不要依赖这个 Windows 专用命令。

终端字体需要单独配置 Nerd Font，主题透明效果由终端背景配合；仓库不会修改系统字体或终端设置。

## 上传 GitHub 与后续维护

在 GitHub 创建空仓库，然后在**本目录**执行（替换仓库地址）：

```bash
git init
git add .
git status
git commit -m "Add portable Neovim configuration"
git branch -M main
git remote add origin https://github.com/YOUR_NAME/nvim-config.git
git push -u origin main
```

另一台设备 `git clone` 仓库后执行本页对应的安装脚本即可。脚本使用复制部署，**编辑安装目录不会自动同步到仓库**；后续建议在仓库里修改配置，提交后在各设备拉取并重新部署。`lazy-lock.json` 应随插件更新一起提交。

目录保留有效配置与锁文件，排除了旧备份、插件缓存、日志、编译索引和登录凭据。没有上传 `.codex`、`.ssh` 或本机插件安装目录。原有 Apache 2.0 LICENSE 保留。

## 验证与回滚

```bash
nvim --clean --headless -l tests/smoke.lua
bash -n install.sh
```

测试包含 Lua 语法、选区菜单上下文、C++ 本机/容器路由与路径边界；GitHub Actions 还检查 Windows/Linux 部署和备份。

本次整理已在 Windows 做过隔离配置启动、安装/重复安装与 helper 编译检查，并在现有 Linux 容器执行了配置复制与重复安装检查。全新设备上的系统软件和插件下载依赖网络，尚未用全新系统实测；部署脚本提供了安装逻辑和失败提示。Mason 工具自身版本不由 `lazy-lock.json` 固定。

每次覆盖配置前，旧目录会移动为 `nvim.backup-时间-标识`。需要回滚时，关闭 Neovim，把当前 `nvim` 目录改名，再将对应备份恢复成 `nvim`。插件数据目录保持独立，脚本不会清空它。

参考：[LazyVim 安装说明](https://www.lazyvim.org/installation)、[Neovim 官方安装说明](https://github.com/neovim/neovim/blob/master/INSTALL.md)。

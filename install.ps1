[CmdletBinding()]
param(
    [string]$Target = (Join-Path $env:LOCALAPPDATA 'nvim'),
    [switch]$InstallDependencies,
    [switch]$Extras,
    [switch]$SkipPlugins,
    [switch]$SkipServers,
    [switch]$SkipHelper
)
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\')
$Target = [IO.Path]::GetFullPath($Target).TrimEnd('\')
$protected = @([IO.Path]::GetPathRoot($Target).TrimEnd('\'), $env:USERPROFILE, $env:LOCALAPPDATA, $repo)
if ($protected -contains $Target -or $repo.StartsWith($Target + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw "Unsafe configuration destination: $Target"
}
if ((Test-Path -LiteralPath $Target) -and ((Get-Item -LiteralPath $Target).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    throw 'Destination is a symlink/junction. Choose a regular directory with -Target.'
}
function Refresh-Path {
    $env:PATH = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
        [Environment]::GetEnvironmentVariable('Path', 'User') + ';' + $env:PATH
}
if ($InstallDependencies) {
    if (!(Get-Command winget -ErrorAction SilentlyContinue)) { throw 'Install Microsoft App Installer (winget) first.' }
    $packages = @(
        @('git', 'Git.Git'), @('nvim', 'Neovim.Neovim'),
        @('rg', 'BurntSushi.ripgrep.MSVC'), @('fd', 'sharkdp.fd'),
        @('node', 'OpenJS.NodeJS.LTS'), @('gcc', 'BrechtSanders.WinLibs.POSIX.UCRT')
    )
    if ($Extras) { $packages += ,@('nu', 'Nushell.Nushell'); $packages += ,@('lazygit', 'JesseDuffield.lazygit'); $packages += ,@('yazi', 'sxyazi.yazi'); $packages += ,@('fzf', 'junegunn.fzf') }
    foreach ($package in $packages) {
        if (Get-Command $package[0] -ErrorAction SilentlyContinue) { continue }
        & winget install --id $package[1] --exact --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) { throw "winget failed for $($package[1]). Resolve the reported error and retry." }
        Refresh-Path
    }
}
Refresh-Path
if (!$SkipPlugins) {
    if (!(Get-Command nvim -ErrorAction SilentlyContinue) -or !(Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'Need nvim and git on PATH. Use -InstallDependencies or install them first.'
    }
    $version = (& nvim --version | Select-Object -First 1)
    if ($version -notmatch 'v(\d+)\.(\d+)\.(\d+)' -or [version]$Matches[0].Substring(1) -lt [version]'0.11.2') {
        throw "Neovim >= 0.11.2 is required; found $version"
    }
}
$backup = $null
if (Test-Path -LiteralPath $Target) {
    $backup = $Target + '.backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 6)
    Write-Host "Backing up checked destination $Target to $backup"
    Move-Item -LiteralPath $Target -Destination $backup
}
New-Item -ItemType Directory -Path $Target -Force | Out-Null
foreach ($name in @('init.lua', 'lazy-lock.json', 'lazyvim.json', 'stylua.toml', 'lua')) {
    Copy-Item -LiteralPath (Join-Path $repo $name) -Destination $Target -Recurse
}
# Keep machine overrides across updates; a repo-local override wins when supplied.
$localSource = Join-Path $repo 'lua\config\local.lua'
if (!(Test-Path -LiteralPath $localSource) -and $backup) {
    $oldLocal = Join-Path $backup 'lua\config\local.lua'
    if (Test-Path -LiteralPath $oldLocal) { Copy-Item -LiteralPath $oldLocal -Destination (Join-Path $Target 'lua\config\local.lua') }
}
if (!$SkipHelper) {
    $compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
    if (!(Test-Path -LiteralPath $compiler)) { $compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe' }
    if (Test-Path -LiteralPath $compiler) {
        New-Item -ItemType Directory -Path (Join-Path $Target 'bin') -Force | Out-Null
        & $compiler /nologo /target:exe /out:"$Target\bin\debdeploy-askpass.exe" (Join-Path $repo 'tools\DebDeployAskpass.cs')
        if ($LASTEXITCODE -ne 0) { throw 'Building the DebDeploy askpass helper failed.' }
    } else { Write-Warning 'C# compiler unavailable; only the optional DebDeploy feature needs its askpass helper.' }
}
if (!$SkipPlugins) {
    # XDG_CONFIG_HOME lets an explicit -Target work without touching the default config.
    $priorXdg = $env:XDG_CONFIG_HOME
    $priorApp = $env:NVIM_APPNAME
    try {
        $env:XDG_CONFIG_HOME = Split-Path -Parent $Target
        $env:NVIM_APPNAME = Split-Path -Leaf $Target
        & nvim --headless -i NONE -n "+lua require('config.bootstrap').plugins()" '+qa!'
        if ($LASTEXITCODE -ne 0) { throw 'Plugin restore failed. Check network access and rerun the installer.' }
        if (!$SkipServers) {
            & nvim --headless -i NONE -n "+lua require('config.bootstrap').main()" '+qa!'
            if ($LASTEXITCODE -ne 0) { throw 'Language-server setup failed. Rerun, or use :Mason to inspect the failure.' }
        }
    } finally {
        $env:XDG_CONFIG_HOME = $priorXdg
        $env:NVIM_APPNAME = $priorApp
    }
}
Write-Host "Installed: $Target"
if ($backup) { Write-Host "Previous configuration: $backup" }
Write-Host 'Open Neovim and run :checkhealth. Optional Docker/Codex settings: lua/config/local.example.lua.'

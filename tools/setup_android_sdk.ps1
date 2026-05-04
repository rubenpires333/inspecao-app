$ErrorActionPreference = 'Stop'

$sdkRoot = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
$toolsZip = Join-Path $env:TEMP 'commandlinetools-win.zip'
$javaHome = 'C:\Program Files\Android\Android Studio\jbr'

if (-not (Test-Path (Join-Path $javaHome 'bin\java.exe'))) {
    Write-Error "Java do Android Studio nao encontrado em: $javaHome"
    exit 1
}

$env:JAVA_HOME = $javaHome
$env:PATH = "$javaHome\bin;$env:PATH"

New-Item -ItemType Directory -Force -Path $sdkRoot | Out-Null

Write-Host 'A descarregar commandlinetools...'
$uri = 'https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip'
Invoke-WebRequest -Uri $uri -OutFile $toolsZip -UseBasicParsing

$extract = Join-Path $env:TEMP 'android-cmdline-tools'
if (Test-Path $extract) { Remove-Item $extract -Recurse -Force }
Expand-Archive -Path $toolsZip -DestinationPath $extract -Force

$latest = Join-Path $sdkRoot 'cmdline-tools\latest'
New-Item -ItemType Directory -Force -Path (Split-Path $latest) | Out-Null
if (Test-Path $latest) { Remove-Item $latest -Recurse -Force }
Move-Item (Join-Path $extract 'cmdline-tools') $latest

$sdkmanager = Join-Path $latest 'bin\sdkmanager.bat'
Write-Host 'A instalar pacotes SDK (pode demorar)...'
$installCmd = "`"$sdkmanager`" --sdk_root=`"$sdkRoot`" platform-tools `"platforms;android-35`" `"build-tools;35.0.0`""
cmd.exe /c $installCmd
if ($LASTEXITCODE -ne 0) { throw "sdkmanager install falhou: $LASTEXITCODE" }

Write-Host 'A aceitar licencas...'
$yes = ("y`n" * 100)
$yes | cmd.exe /c "`"$sdkmanager`" --sdk_root=`"$sdkRoot`" --licenses"
# licenses command pode retornar !=0 mesmo com sucesso em algumas versoes; ignorar se adb existir

[Environment]::SetEnvironmentVariable('ANDROID_HOME', $sdkRoot, 'User')
[Environment]::SetEnvironmentVariable('ANDROID_SDK_ROOT', $sdkRoot, 'User')

$pt = Join-Path $sdkRoot 'platform-tools'
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath -notlike "*$pt*") {
    [Environment]::SetEnvironmentVariable('Path', ($userPath.TrimEnd(';') + ';' + $pt), 'User')
}

Write-Host "ANDROID_HOME=$sdkRoot"
Write-Host 'Concluido. Feche e reabra o terminal e execute: flutter doctor -v'

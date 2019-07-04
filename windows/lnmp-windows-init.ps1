#
# $ set-ExecutionPolicy RemoteSigned
#

# 大于 -gt (greater than)
# 小于 -lt (less than)
# 大于或等于 -ge (greater than or equal)
# 小于或等于 -le (less than or equal)
# 不相等 -ne （not equal）
# 等于 -eq

Function print_help_info(){
  echo "
LNMP Windows init Tool

COMMANDS:

install     Install soft
uninstall   Uninstall soft
remove      Uninstall soft
list        List available softs
help        Print help info
"

  exit
}

$ErrorAction="SilentlyContinue"

. "$PSScriptRoot/common.ps1"

$global:source=$PWD
$global:USER_AGENT="5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3828.0 Safari/537.36"

# 配置环境变量
$LNMP_PATH="$HOME\lnmp"
[environment]::SetEnvironmentvariable("DOCKER_CLI_EXPERIMENTAL", "enabled", "User")
[environment]::SetEnvironmentvariable("DOCKER_BUILDKIT", "1", "User")
[environment]::SetEnvironmentvariable("LNMP_PATH", "$LNMP_PATH", "User")
[environment]::SetEnvironmentvariable("APP_ENV", "$APP_ENV", "User")

$LNMP_PATH = [environment]::GetEnvironmentvariable("LNMP_PATH", "User")

$items="$LNMP_PATH","$LNMP_PATH\windows","$LNMP_PATH\wsl", `
       "$LNMP_PATH\kubernetes", `
       "$LNMP_PATH\kubernetes\coreos",`
       "$env:USERPROFILE\app\pcit\bin", `
       "C:\php", `
       "C:\mysql\bin", `
       "C:\nginx", `
       "C:\Apache24\bin", `
       "C:\node", `
       "$env:ProgramData\npm", `
       "C:\bin", `
       "C:\Users\$env:username\go\bin", `
       "C:\go\bin", `
       "C:\Python", `
       "$HOME\AppData\Roaming\Composer\vendor\bin", `
       "$env:SystemRoot\system32\WindowsPowerShell\v1.0"

Foreach ($item in $items)
{
  $env_path=[environment]::GetEnvironmentvariable("Path", "User")
  $string=$(echo $env_path | select-string ("$item;").replace('\','\\'))

  if($string.Length -eq 0){
    write-host "
Add $item to system PATH env ...
    "
    [environment]::SetEnvironmentvariable("Path", "$env_Path;$item;","User")
  }
}

$env:Path = [environment]::GetEnvironmentvariable("Path", "User") `
            + ";" + [environment]::GetEnvironmentvariable("Path", "Machine")

Function _command($command){
  if ($command -eq "wsl"){
    wsl curl -V | out-null
  }else{
    get-command $command -ErrorAction "SilentlyContinue"
  }

  return $?
}

Function _wget($src,$des,$wsl=$true){
  $useWSL=_command wsl -and $wsl

  if ($useWSL -eq "True"){

    Write-host "

use WSL curl download file ...
"

    wsl -- curl -L $src -o $des --user-agent $USER_AGENT

    return
  }

  Invoke-WebRequest -uri $src -OutFile $des -UserAgent $USER_AGENT
  Unblock-File $des
}

Function _unzip($zip, $folder){
  Expand-Archive -Path $zip -DestinationPath $folder -Force
}

Function _rename($src,$target){
  if (!(Test-Path $target)){
  Rename-Item $src $target
  }
}

Function _mkdir($dir_path){
  if (!(Test-Path $dir_path )){
    New-Item $dir_path -type directory
  }
}

Function _ln($src,$target){
  New-Item -Path $target -ItemType SymbolicLink -Value $src -ErrorAction "SilentlyContinue"
}

Function _echo_line(){
  Write-Host "


"
}

Function _installer($zip, $unzip_path, $unzip_folder_name = 'null', $soft_path = 'null'){
  if (Test-Path $soft_path){
    Write-Host "==> $unzip_folder_name already installed" -ForegroundColor Green
    _echo_line
    return
  }

  Write-Host "==> $unzip_folder_name installing ..." -ForegroundColor Red

  if (!(Test-Path $unzip_folder_name)){
    _unzip $zip $unzip_path
  }

  if (!($soft_path -eq 'null')){
    _rename $unzip_folder_name $soft_path
  }

}

################################################################################

_mkdir C:\php-ext

_mkdir C:\bin

_mkdir $home\Downloads\lnmp-docker-cache

cd $home\Downloads\lnmp-docker-cache

$Env:PSModulePath="$Env:PSModulePath" + ";" `
                  + $PSScriptRoot + "\powershell_system" + ";"

Function __install($softs){
  Foreach ($soft in $softs){
    $soft,$version=(echo $soft).split('@')
    echo "==> Installing $soft $version ..."
    Import-Module "${PSScriptRoot}\powershell_softs\$soft"

    if($version){
      install $version
    }else{
      install
    }
    Remove-Module -Name $soft
  }
}

Function __uninstall($softs){
  Foreach ($soft in $softs){
    echo "==> Uninstalling $soft ..."
    Import-Module -Name "${PSScriptRoot}\powershell_softs\$soft"
    uninstall
    Remove-Module -Name $soft
  }
}

Function __list(){
  echo ""
  ls "${PSScriptRoot}\powershell_softs" -Name
  echo ""
  exit
}

if($args[0] -eq 'install'){
  $_, $softs = $args
  __install $softs
  exit
}

if($args[0] -eq 'uninstall' -or $args[0] -eq 'remove'){
  $_, $softs = $args
  __uninstall $softs
  exit
}

if($args[0] -eq 'list'){
  $_, $softs = $args
  __list $softs
  exit
}

if($args[0] -eq '--help' -or $args[0] -eq '-h' -or $args[0] -eq 'help'){
  $_, $softs = $args
  print_help_info
  exit
}

################################################################################

Function _downloader($url, $path, $soft, $version = 'null version',$wsl = $true){
  if (!(Test-Path $path)){
    Write-Host "==> Downloading $soft $version..." -NoNewLine -ForegroundColor Green
    _wget $url $path $wsl
    _echo_line
  }else{
     Write-Host "==> Skip $soft $version" -NoNewLine -ForegroundColor Red
     _echo_line
  }
}

#
# Git
#

_downloader `
  https://github.com/git-for-windows/git/releases/download/v${GIT_VERSION}.windows.1/Git-${GIT_VERSION}-64-bit.exe `
  Git-${GIT_VERSION}-64-bit.exe `
  Git ${GIT_VERSION}

#
# VC++ library
#
# @link https://support.microsoft.com/zh-cn/help/2977003/the-latest-supported-visual-c-downloads
# @link https://www.microsoft.com/en-us/download/details.aspx?id=40784
#

_downloader `
  https://aka.ms/vs/16/release/VC_redist.x64.exe `
  vc_redist.x64.exe `
  vc_redist.x64.exe

#
# NGINX
#

_downloader `
  https://nginx.org/download/nginx-${NGINX_VERSION}.zip `
  nginx-${NGINX_VERSION}.zip `
  NGINX ${NGINX_VERSION}

#
# HTTPD
#

_downloader `
    https://www.apachelounge.com/download/VS16/binaries/httpd-${HTTPD_VERSION}-win64-VS16.zip `
    httpd-${HTTPD_VERSION}-win64-VS16.zip `
    HTTPD ${HTTPD_VERSION}

_downloader `
  https://www.apachelounge.com/download/VS16/modules/mod_fcgid-${HTTPD_MOD_FCGID_VERSION}-win64-VS16.zip `
  mod_fcgid-${HTTPD_MOD_FCGID_VERSION}-win64-VS16.zip `
  mod_fcgid-${HTTPD_MOD_FCGID_VERSION}-win64-VS16

#
# PHP
#

_downloader `
  https://windows.php.net/downloads/releases/php-${PHP_VERSION}-nts-Win32-VC15-x64.zip `
  php-${PHP_VERSION}-nts-Win32-VC15-x64.zip `
  PHP ${PHP_VERSION}

#
# Composer
#

_downloader `
  https://getcomposer.org/Composer-Setup.exe `
  Composer-Setup.exe `
  Composer

#
# RunHiddenConsole
#

# http://blogbuildingu.com/files/RunHiddenConsole.zip

_downloader `
  http://redmine.lighttpd.net/attachments/download/660/RunHiddenConsole.zip `
  RunHiddenConsole.zip `
  RunHiddenConsole

_downloader `
  https://github.com/deemru/php-cgi-spawner/releases/download/1.1.23/php-cgi-spawner.exe `
  php-cgi-spawner.exe `
  php-cgi-spawner

#
# pecl
#

# https://pecl.php.net/package/yaml
_downloader `
  https://windows.php.net/downloads/pecl/releases/yaml/$PHP_YAML_EXTENSION_VERSION/php_yaml-$PHP_YAML_EXTENSION_VERSION-7.3-nts-vc15-x64.zip `
  C:\php-ext\php_yaml-$PHP_YAML_EXTENSION_VERSION-7.3-nts-vc15-x64.zip `
  php_yaml-$PHP_YAML_EXTENSION_VERSION-7.3-nts-vc15-x64 null $false
# https://pecl.php.net/package/xdebug
_downloader `
  https://windows.php.net/downloads/pecl/releases/xdebug/$PHP_XDEBUG_EXTENSION_VERSION/php_xdebug-$PHP_XDEBUG_EXTENSION_VERSION-7.3-nts-vc15-x64.zip `
  C:\php-ext\php_xdebug-$PHP_XDEBUG_EXTENSION_VERSION-7.3-nts-vc15-x64.zip `
  php_xdebug-$PHP_XDEBUG_EXTENSION_VERSION-7.3-nts-vc15-x64.zip null $false
# https://pecl.php.net/package/redis
_downloader `
  https://windows.php.net/downloads/pecl/releases/redis/$PHP_REDIS_EXTENSION_VERSION/php_redis-$PHP_REDIS_EXTENSION_VERSION-7.3-nts-vc15-x64.zip `
  C:\php-ext\php_redis-$PHP_REDIS_EXTENSION_VERSION-7.3-nts-vc15-x64.zip `
  php_redis-$PHP_REDIS_EXTENSION_VERSION-7.3-nts-vc15-x64.zip null $false
# https://pecl.php.net/package/mongodb
_downloader `
  https://windows.php.net/downloads/pecl/releases/mongodb/$PHP_MONGODB_EXTENSION_VERSION/php_mongodb-$PHP_MONGODB_EXTENSION_VERSION-7.3-nts-vc15-x64.zip `
  C:\php-ext\php_mongodb-$PHP_MONGODB_EXTENSION_VERSION-7.3-nts-vc15-x64.zip `
  php_mongodb-$PHP_MONGODB_EXTENSION_VERSION-7.3-nts-vc15-x64.zip null $false
# https://pecl.php.net/package/igbinary
_downloader `
  https://windows.php.net/downloads/pecl/releases/igbinary/$PHP_IGBINARY_EXTENSION_VERSION/php_igbinary-$PHP_IGBINARY_EXTENSION_VERSION-7.3-nts-vc15-x64.zip `
  C:\php-ext\php_igbinary-$PHP_IGBINARY_EXTENSION_VERSION-7.3-nts-vc15-x64.zip `
  php_igbinary-$PHP_IGBINARY_EXTENSION_VERSION-7.3-nts-vc15-x64.zip null $false
# https://curl.haxx.se/docs/caextract.html
# https://github.com/khs1994-docker/lnmp/issues/339
_downloader `
  https://curl.haxx.se/ca/cacert-${PHP_CACERT_DATE}.pem `
  C:\php-ext\cacert-${PHP_CACERT_DATE}.pem `
  C:\php-ext\cacert-${PHP_CACERT_DATE}.pem null $false

Function _pecl($zip,$file){
  if (!(Test-Path C:\php-ext\$file)){
    _unzip C:\php-ext\$zip C:\php-ext\temp
    mv C:\php-ext\temp\$file C:\php-ext\$file
  }
}

_pecl php_igbinary-$PHP_IGBINARY_EXTENSION_VERSION-7.3-nts-vc15-x64.zip php_igbinary.dll

_pecl php_mongodb-$PHP_MONGODB_EXTENSION_VERSION-7.3-nts-vc15-x64.zip php_mongodb.dll

_pecl php_redis-$PHP_REDIS_EXTENSION_VERSION-7.3-nts-vc15-x64.zip php_redis.dll

_pecl php_xdebug-$PHP_XDEBUG_EXTENSION_VERSION-7.3-nts-vc15-x64.zip php_xdebug.dll

_pecl php_yaml-$PHP_YAML_EXTENSION_VERSION-7.3-nts-vc15-x64.zip php_yaml.dll

cp -Force C:\php\php.ini C:\php-ext\php.ini

#
# MySQL
#

# https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-${MYSQL_VERSION}-winx64.zip `

_downloader `
  https://mirrors.ustc.edu.cn/mysql-ftp/Downloads/MySQL-8.0/mysql-${MYSQL_VERSION}-winx64.zip `
  mysql-${MYSQL_VERSION}-winx64.zip `
  MySQL ${MYSQL_VERSION}

#
# Node
#

_downloader `
  https://mirrors.ustc.edu.cn/node/v${NODE_VERSION}/node-v${NODE_VERSION}-win-x64.zip `
  node-v${NODE_VERSION}-win-x64.zip `
  Node.js ${NODE_VERSION}

#
# Golang
#

_downloader `
  https://studygolang.com/dl/golang/go${GOLANG_VERSION}.windows-amd64.zip `
  go${GOLANG_VERSION}.windows-amd64.zip `
  Golang ${GOLANG_VERSION}

#
# vim
#

_downloader `
  https://github.com/vim/vim-win32-installer/releases/download/v8.1.0005/gvim_8.1.0005_x86.exe `
  gvim_8.1.0005_x86.exe `
  gvim_8.1.0005_x86.exe

################################################################################

Function _nginx(){
  _installer nginx-${NGINX_VERSION}.zip C:\ C:\nginx-${NGINX_VERSION} C:\nginx
}

Function _mysql(){
  _installer mysql-${MYSQL_VERSION}-winx64.zip C:\ C:\mysql-${MYSQL_VERSION}-winx64 C:\mysql
}

Function _php(){
  _installer php-${PHP_VERSION}-nts-Win32-VC15-x64.zip C:\php C:\php C:\php

  Get-Process php-cgi-spawner -ErrorAction "SilentlyContinue" | out-null

  if(!($?)){
    cp php-cgi-spawner.exe C:\php
  }

  _installer RunHiddenConsole.zip C:\bin C:\bin\RunHiddenConsole.exe C:\bin\RunHiddenConsole.exe
}

Function _httpd(){
  if($(_command httpd)){
    $HTTPD_CURRENT_VERSION=($(httpd -v) -split " ")[2]
  }

  if ($HTTPD_CURRENT_VERSION.length -eq 0){
    _installer httpd-${HTTPD_VERSION}-win64-VS16.zip C:\ C:\Apache24 C:\Apache24
  }

  if ($HTTPD_CURRENT_VERSION -ne "Apache/${HTTPD_VERSION}"){
    _unzip httpd-${HTTPD_VERSION}-win64-VS16.zip $HOME\Downloads
    Copy-Item -Recurse -Force "$HOME\Downloads\Apache24\*" "C:\Apache24\"
  }

  if (!(Test-Path C:\Apache24\modules\mod_fcgid.so)){
    _installer mod_fcgid-${HTTPD_MOD_FCGID_VERSION}-win64-VS16.zip C:\Apache24\modules `
      C:\Apache24\modules\mod_fcgid-${HTTPD_MOD_FCGID_VERSION} C:\Apache24\modules\mod_fcgid

    mv C:\Apache24\modules\mod_fcgid\mod_fcgid.so C:\Apache24\modules\mod_fcgid.so
  }
}

Function _node(){
  if($(_command node)){
    $NODE_CURRENT_VERSION=$(node -v)
  }

  if ($NODE_CURRENT_VERSION.length -eq 0){
    _installer node-v${NODE_VERSION}-win-x64.zip C:\ C:\node-v${NODE_VERSION}-win-x64 C:\node
    return
  }

  if($NODE_CURRENT_VERSION -ne "v$NODE_VERSION"){
    echo "==> Installing node ${NODE_VERSION} ..."
    _unzip node-v${NODE_VERSION}-win-x64.zip C:\
    Copy-Item -Recurse -Force "C:/node-v${NODE_VERSION}-win-x64/*" "C:/node/"
    Remove-Item -Force -Recurse "C:/node-v${NODE_VERSION}-win-x64"
  }
}

Function _go(){
  if($(_command go)){
    $GOLANG_CURRENT_VERSION=($(go version) -split " ")[2]
  }

  if($GOLANG_CURRENT_VERSION.length -eq 0){
    _installer go${GOLANG_VERSION}.windows-amd64.zip C:\ C:\go C:\go
    return
  }

  if ($GOLANG_CURRENT_VERSION -ne "go$GOLANG_VERSION"){
    Write-Host "==> Upgrade go"
    Write-Host "Remove old go folder"
    Remove-Item -Recurse -Force C:\go
    Write-Host "Installing go..."
    _unzip go${GOLANG_VERSION}.windows-amd64.zip C:\
  }

  [environment]::SetEnvironmentvariable("GOPATH", "$HOME\go", "User")
}

_nginx

_httpd

_mysql

_php

_node

npm config set prefix $env:ProgramData\npm

_go

################################################################################

# apm

if($(_command apm)){
  apm config set registry https://registry.npm.taobao.org
}

################################################################################

if($(_command php)){
  $PHP_CURRENT_VERSION=$( php -r "echo PHP_VERSION;" )

  if ($PHP_CURRENT_VERSION -ne $PHP_VERSION){
      echo "==> Installing PHP $PHP_VERSION ..."
      _unzip $HOME/Downloads/php-$PHP_VERSION-nts-Win32-VC15-x64.zip C:/php-$PHP_VERSION
      Copy-Item -Force -Recurse "C:/php-$PHP_VERSION/*" "C:/php/"
      rm -Force -Recurse C:\php-$PHP_VERSION
  }
}

$SOFT_TEST_COMMAND="git --version", `
                   "docker --version", `
                   "nginx -v", `
                   "httpd -v", `
                   "mysql --version", `
                   "node -v", `
                   "npm -v", `
                   "go version"

Foreach ($item in $SOFT_TEST_COMMAND)
{
  write-host "==> $item

  "
  powershell -Command $item
  _echo_line
}

cd $source

################################################################################

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

################################################################################

if (!(Test-Path C:\php\php.ini)){
  mv C:\php\php.ini-development C:\php\php.ini
}

$items='yaml',`
       'xdebug',`
       'Zend Opcache',`
       'redis',`
       'mongodb',`
       'igbinary',`
       'curl',`
       'pdo_mysql'

Foreach ($item in $items)
{
  $a = php -r "echo extension_loaded('$item');"

  if (!($a -eq 1)){

    if ($item -eq 'Zend Opcache'){
      echo ' ' | out-file -Append C:/php/php.ini -encoding utf8
      echo "zend_extension=opcache" | out-file -Append C:/php/php.ini -encoding utf8
      continue
    }

    if (!(Test-Path C:\php-ext\php_$item.dll)){
      if ((Test-Path C:\php\ext\php_$item.dll)){
        echo ' ' | out-file -Append C:/php/php.ini -encoding utf8
        echo "extension=$item" | out-file -Append C:/php/php.ini -encoding utf8
      }else{
        continue
      }
      continue
    }

    if ($item -eq 'xdebug'){
      echo ' ' | out-file -Append C:/php/php.ini -encoding utf8
      echo "; zend_extension=C:\php-ext\php_$item" | out-file -Append C:/php/php.ini -encoding utf8
      continue
    }
    echo ' ' | out-file -Append C:/php/php.ini -encoding utf8
    echo "extension=C:\php-ext\php_$item" | out-file -Append C:/php/php.ini -encoding utf8
  }
}

#
# Windows php curl ssl
#
# @link https://github.com/khs1994-docker/lnmp/issues/339
#

$a = php -r "echo ini_get('curl.cainfo');"

if ($a -ne "C:\php-ext\cacert-${PHP_CACERT_DATE}.pem"){
  echo "curl.cainfo=C:\php-ext\cacert-${PHP_CACERT_DATE}.pem" | out-file -Append C:/php/php.ini -encoding utf8
}

php -r "echo ini_get('curl.cainfo');"

Write-Host "


"

php -m

################################################################################

$HTTPD_IS_RUN=0

get-service Apache2.4 | out-null

if (!($?)){
    httpd.exe -k install
    $HTTPD_IS_RUN=1
}

$a=Select-String 'include conf.d/' C:\Apache24\conf\httpd.conf

if ($a.Length -eq 0){
  echo "Add config in C:\Apache24\conf\httpd.conf"

  echo ' ' | out-file -Append C:\Apache24\conf\httpd.conf
  echo "include conf.d/*.conf" | out-file -Append C:\Apache24\conf\httpd.conf
}

################################################################################

if(!(Test-Path C:\mysql\data)){

  Write-Host "mysql is init ..."

  mysqld --initialize

  mysqld --install
}

if (!(Test-Path C:/mysql/my.cnf)){
  Copy-Item $PSScriptRoot/config/my.cnf C:/mysql/my.cnf
}

$mysql_password=($(select-string `
  "A temporary password is generated for" C:\mysql\data\*.err) -split " ")[12]

Write-host "

Please exec command start(or init) mysql

$ net start mysql

$ mysql -uroot -p`"$mysql_password`"

mysql> ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'mytest';

mysql> FLUSH PRIVILEGES;

mysql> GRANT ALL ON *.* TO 'root'@'localhost' WITH GRANT OPTION;

# add remote login user

mysql> CREATE USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY 'password';

mysql> GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;
"

################################################################################

_mkdir $home\lnmp\windows\logs

_mkdir C:\nginx\conf\conf.d

_ln C:\nginx\conf\conf.d $home\lnmp\windows\nginx

_ln C:\nginx\logs $home\lnmp\windows\logs\nginx

Get-Process nginx -ErrorAction "SilentlyContinue" | out-null

if (!($?)){
  echo ' ' | out-file -Append $home\lnmp\windows\logs\nginx\access.log -ErrorAction "SilentlyContinue"
  echo ' ' | out-file -Append $home\lnmp\windows\logs\nginx\error.log -ErrorAction "SilentlyContinue"
}

################################################################################

_mkdir C:\Apache24\conf.d

_ln C:\Apache24\conf.d $home\lnmp\windows\httpd

_ln C:\Apache24\logs $home\lnmp\windows\logs\httpd

################################################################################

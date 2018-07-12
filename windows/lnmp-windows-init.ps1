#
# $ set-ExecutionPolicy RemoteSigned
#

. "$PSScriptRoot/.env.example.ps1"

if (Test-Path "$PSScript/.env.ps1"){
  . "$PSScriptRoot/.env.ps1"
}

$global:source=$PWD

Function _command($command){
  get-command $command -ErrorAction "SilentlyContinue"

  if($?){
    return $true
  }

  return $false
}

Function _wget($src,$des){
  if ($( _command wsl)){

    Write-host "

use WSL curl download file ...
"

    wsl curl -L $src -o $des

    return
  }

  Invoke-WebRequest -uri $src -OutFile $des
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
    Write-Host "$unzip_folder_name already installed" -ForegroundColor Green
    _echo_line
    return
  }

  Write-Host "$unzip_folder_name installing ..." -ForegroundColor Red

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

cd $home\Downloads

Function _downloader($url, $path, $soft, $version = 'null version'){
  if (!(Test-Path $path)){
    Write-Host "download $soft $version..." -NoNewLine -ForegroundColor Green
    _wget $url $path
    _echo_line
  }else{
     Write-Host "skip $soft $version" -NoNewLine -ForegroundColor Red
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
  https://aka.ms/vs/15/release/vc_redist.x64.exe `
  vc_redist.x64.exe `
  vc_redist.x64.exe

#
# NGINX
#

_downloader `
  http://nginx.org/download/nginx-${NGINX_VERSION}.zip `
  nginx-${NGINX_VERSION}.zip `
  NGINX ${NGINX_VERSION}

#
# HTTPD
#

_downloader `
    http://www.apachelounge.com/download/VC15/binaries/httpd-${HTTPD_VERSION}-win64-VC15.zip `
    httpd-${HTTPD_VERSION}-win64-VC15.zip `
    HTTPD ${HTTPD_VERSION}

_downloader `
  http://www.apachelounge.com/download/VC15/modules/mod_fcgid-${HTTPD_MOD_FCGID_VERSION}-win64-VC15.zip `
  mod_fcgid-${HTTPD_MOD_FCGID_VERSION}-win64-VC15.zip `
  mod_fcgid-${HTTPD_MOD_FCGID_VERSION}-win64-VC15

#
# PHP
#

_downloader `
  http://windows.php.net/downloads/releases/php-${PHP_VERSION}-nts-Win32-VC15-x64.zip `
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

_downloader `
  https://windows.php.net/downloads/pecl/releases/yaml/2.0.2/php_yaml-2.0.2-7.2-nts-vc15-x64.zip `
  C:\php-ext\php_yaml-2.0.2-7.2-nts-vc15-x64.zip `
  php_yaml-2.0.2-7.2-nts-vc15-x64

_downloader `
  https://windows.php.net/downloads/pecl/releases/xdebug/2.7.0alpha1/php_xdebug-2.7.0alpha1-7.2-nts-vc15-x64.zip `
  C:\php-ext\php_xdebug-2.7.0alpha1-7.2-nts-vc15-x64.zip `
  php_xdebug-2.7.0alpha1-7.2-nts-vc15-x64.zip

_downloader `
  https://windows.php.net/downloads/pecl/releases/redis/4.0.0/php_redis-4.0.0-7.2-nts-vc15-x64.zip `
  C:\php-ext\php_redis-4.0.0-7.2-nts-vc15-x64.zip `
  php_redis-4.0.0-7.2-nts-vc15-x64.zip

_downloader `
  https://windows.php.net/downloads/pecl/releases/mongodb/1.4.2/php_mongodb-1.4.2-7.2-nts-vc15-x64.zip `
  C:\php-ext\php_mongodb-1.4.2-7.2-nts-vc15-x64.zip `
  php_mongodb-1.4.2-7.2-nts-vc15-x64.zip

_downloader `
  https://windows.php.net/downloads/pecl/releases/igbinary/2.0.6RC1/php_igbinary-2.0.6rc1-7.2-nts-vc15-x64.zip `
  C:\php-ext\php_igbinary-2.0.6rc1-7.2-nts-vc15-x64.zip `
  php_igbinary-2.0.6rc1-7.2-nts-vc15-x64.zip

_downloader `
  https://curl.haxx.se/ca/cacert-2018-03-07.pem `
  C:\cacert-2018-03-07.pem `
  C:\cacert-2018-03-07.pem

Function _pecl($zip,$file){
  if (!(Test-Path C:\php-ext\$file)){
    _unzip C:\php-ext\$zip C:\php-ext\temp
    mv C:\php-ext\temp\$file C:\php-ext\$file
  }
}


Function backup_php_ini(){
  cp -Force C:\php\php.ini C:\php-ext\php.ini
}

_pecl php_igbinary-2.0.6rc1-7.2-nts-vc15-x64.zip php_igbinary.dll

_pecl php_mongodb-1.4.2-7.2-nts-vc15-x64.zip php_mongodb.dll

_pecl php_redis-4.0.0-7.2-nts-vc15-x64.zip php_redis.dll

_pecl php_xdebug-2.7.0alpha1-7.2-nts-vc15-x64.zip php_xdebug.dll

_pecl php_yaml-2.0.2-7.2-nts-vc15-x64.zip php_yaml.dll

backup_php_ini

#
# MySQL
#

_downloader `
  https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-${MYSQL_VERSION}-winx64.zip `
  mysql-${MYSQL_VERSION}-winx64.zip `
  MYSQL ${MYSQL_VERSION}

#
# Docker
#

_downloader `
  "https://download.docker.com/win/edge/Docker%20for%20Windows%20Installer.exe" `
  "docker.exe" `
  Docker

#
# IDEA
#

_downloader `
  https://download.jetbrains.com/toolbox/jetbrains-toolbox-${IDEA_VERSION}.exe `
  jetbrains-toolbox-${IDEA_VERSION}.exe `
  jetbrains-toolbox ${IDEA_VERSION} `

#
# Node
#

_downloader `
  https://nodejs.org/dist/v${NODE_VEERSION}/node-v${NODE_VEERSION}-win-x64.zip `
  node-v${NODE_VEERSION}-win-x64.zip `
  Node.js ${NODE_VEERSION}

#
# Pytohn
#

_downloader `
  https://www.python.org/ftp/python/${PYTHON_VERSION}/python-${PYTHON_VERSION}-amd64.exe `
  python-${PYTHON_VERSION}-amd64.exe `
  Python ${PYTHON_VERSION}

#
# Golang
#

_downloader `
  https://studygolang.com/dl/golang/go${GOLANG_VERSION}.windows-amd64.zip `
  go${GOLANG_VERSION}.windows-amd64.zip `
  Golang ${GOLANG_VERSION}

#
# zeal
#

_downloader `
  https://dl.bintray.com/zealdocs/windows/zeal-${ZEAL_VERSION}-windows-x64.msi `
  zeal-${ZEAL_VERSION}-windows-x64.msi `
  Zeal

#
# vim
#

_downloader `
  https://github.com/vim/vim-win32-installer/releases/download/v8.1.0005/gvim_8.1.0005_x86.exe `
  gvim_8.1.0005_x86.exe `
  gvim_8.1.0005_x86.exe

################################################################################

_installer nginx-${NGINX_VERSION}.zip C:\ C:\nginx-${NGINX_VERSION} C:\nginx

_installer mysql-${MYSQL_VERSION}-winx64.zip C:\ C:\mysql-${MYSQL_VERSION}-winx64 C:\mysql

_installer php-${PHP_VERSION}-nts-Win32-VC15-x64.zip C:\php C:\php C:\php

cp php-cgi-spawner.exe C:\php

_installer httpd-${HTTPD_VERSION}-win64-VC15.zip C:\ C:\Apache24 C:\Apache24

if (!(Test-Path C:\Apache24\modules\mod_fcgid.so)){
  _installer mod_fcgid-${HTTPD_MOD_FCGID_VERSION}-win64-VC15.zip C:\Apache24\modules `
  C:\Apache24\modules\mod_fcgid-${HTTPD_MOD_FCGID_VERSION} C:\Apache24\modules\mod_fcgid

  mv C:\Apache24\modules\mod_fcgid\mod_fcgid.so C:\Apache24\modules\mod_fcgid.so
}

_installer node-v${NODE_VEERSION}-win-x64.zip C:\ C:\node-v${NODE_VEERSION}-win-x64 C:\node

_installer RunHiddenConsole.zip C:\bin C:\bin\RunHiddenConsole.exe C:\bin\RunHiddenConsole.exe

_installer go${GOLANG_VERSION}.windows-amd64.zip C:\ C:\go C:\go

[environment]::SetEnvironmentvariable("GOPATH", "$HOME\go", "User");

################################################################################

[environment]::SetEnvironmentvariable("LNMP_PATH", "$HOME\lnmp", "User");

$env:Path = [environment]::GetEnvironmentvariable("Path", "User")
$env:LNMP_PATH = [environment]::GetEnvironmentvariable("LNMP_PATH", "User")

$items="$env:LNMP_PATH","$env:LNMP_PATH\windows","$env:LNMP_PATH\wsl", `
       "C:\php","C:\mysql\bin","C:\nginx","C:\Apache24\bin", `
       "C:\node","C:\bin" `

Foreach ($item in $items)
{
  $env:Path = [environment]::GetEnvironmentvariable("Path", "User")

  $string=$(echo $env:path | select-string ("$item;").replace('\','\\'))

  if($string.Length -eq 0){
    write-host "
set system env $item ...
    "
    [environment]::SetEnvironmentvariable("Path", "$env:Path;$item;","User")
  }
}

[environment]::SetEnvironmentvariable("APP_ENV", "windows", "User");

################################################################################

$env:Path = [environment]::GetEnvironmentvariable("Path", "User")

if($(_command php)){
  $PHP_CURRENT_VERSION=$( php -r "echo PHP_VERSION;" )

  if ($PHP_CURRENT_VERSION -ne $PHP_VERSION){
      echo "installing PHP $PHP_VERSION ..."
      _unzip $HOME/Downloads/php-$PHP_VERSION-nts-Win32-VC15-x64.zip C:/php-$PHP_VERSION
      cp -rec -Force C:\php-$PHP_VERSION C:\php
      rm -Confirm -Force C:\php-$PHP_VERSION
  }
}

$SOFT_TEST_COMMAND="git --version","docker --version","nginx -v","httpd -v", `
                   "mysql --version", `
                   "node -v", `
                   "npm -v", `
                   "python --version", `
                   "go version"

Foreach ($item in $SOFT_TEST_COMMAND)
{
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

$items='yaml','xdebug','Zend Opcache','redis', 'mongodb', 'igbinary','curl','pdo_mysql'

Foreach ($item in $items)
{
  $a = php -r "echo extension_loaded('$item');"

  if (!($a -eq 1)){

    if ($item -eq 'Zend Opcache'){
      echo ' ' >> C:\php\php.ini
      echo "zend_extension=opcache" >> C:\php\php.ini
      continue
    }

    if (!(Test-Path C:\php-ext\php_$item.dll)){
      if ((Test-Path C:\php\ext\php_$item.dll)){
        echo ' ' >> C:\php\php.ini
        echo "extension=curl" >> C:\php\php.ini
      }else{
        continue
      }
      continue
    }

    if ($item -eq 'xdebug'){
      echo ' ' >> C:\php\php.ini
      echo "zend_extension=C:\php-ext\php_$item" >> C:\php\php.ini
      continue
    }
    echo ' ' >> C:\php\php.ini
    echo "extension=C:\php-ext\php_$item" >> C:\php\php.ini
  }
}

#
# Windows php curl ssl
#
# @link https://github.com/khs1994-docker/lnmp/issues/339
#

$a = php -r "echo ini_get('curl.cainfo');"

if ($a.Length -eq 0){
  echo "curl.cainfo=C:\cacert-2018-03-07.pem" >> C:\php\php.ini
}

php -r "echo ini_get('curl.cainfo');"

Write-Host "


"

php -m

################################################################################

get-service Apache2.4 | out-null

if (!($?)){
    httpd.exe -k install
}

$a=Select-String 'include conf.d/' C:\Apache24\conf\httpd.conf

if ($a.Length -eq 0){
  echo "Add config in C:\Apache24\conf\httpd.conf"

  echo ' ' >> C:\Apache24\conf\httpd.conf
  echo "include conf.d/*.conf" >> C:\Apache24\conf\httpd.conf
}

################################################################################

if(!(Test-Path C:\mysql\data)){

  Write-Host "mysql is init ..."

  mysqld --initialize

  mysqld --install
}

$mysql_password=$(select-string "A temporary password is generated for" C:\mysql\data\*.err)

$mysql_password=$($mysql_password -split " ")[12]

Write-Warning "

Mysql temporary password is

$mysql_password

"

Write-host "

Please exec command start mysql

$ net start mysql

$ mysql -uroot -p TEMP_PASSWORD

$ ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'mytest';

$ FLUSH PRIVILEGES;

$ GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;
"

################################################################################

_mkdir $home\lnmp\windows\logs

_mkdir C:\nginx\conf\conf.d

_ln C:\nginx\conf\conf.d $home\lnmp\windows\nginx

_ln C:\nginx\logs $home\lnmp\windows\logs\nginx

echo ' ' >> $home\lnmp\windows\logs\nginx\access.log -ErrorAction "SilentlyContinue"

echo ' ' >> $home\lnmp\windows\logs\nginx\error.log -ErrorAction "SilentlyContinue"

################################################################################

_mkdir C:\Apache24\conf.d

_ln C:\Apache24\conf.d $home\lnmp\windows\httpd

_ln C:\Apache24\logs $home\lnmp\windows\logs\httpd

################################################################################

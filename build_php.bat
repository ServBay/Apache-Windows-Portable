@echo off

rem @(#)build_php.bat 1.0 - 2025-11-05
rem
rem 1.0 - Initial release based on Apache build_all.bat structure. 2025-11-05
rem
rem PHP build command file for Windows.
rem
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

rem --- GitHub Actions Integration ---
rem Use environment variables if set, otherwise use defaults.
if defined PHP_VERSION (
  set "PHP_SRC=php-%PHP_VERSION%"
) else (
  echo WARN: PHP_VERSION not set, using default
  set "PHP_SRC=php-8.3.15"
)
if defined BUILD_BASE_ENV (
  set BUILD_BASE=%BUILD_BASE_ENV%
) else (
  echo WARN: BUILD_BASE_ENV not set, using default C:\Development\PHP\build
  set BUILD_BASE=C:\Development\PHP\build
)
if defined PREFIX_ENV (
  set PREFIX=%PREFIX_ENV%
) else (
  echo WARN: PREFIX_ENV not set, using default C:\ServBay\packages\php
  set PREFIX=C:\ServBay\packages\php
)
echo PHP Version to build: %PHP_SRC%
echo Using BUILD_BASE: %BUILD_BASE%
echo Using PREFIX: %PREFIX%
rem --- End GitHub Actions Integration ---

rem Set required build platform to x86 or x64.
rem Defaulting to x64 for GitHub Actions typical use case
set PLATFORM=x64

rem Set required build type to Release or Debug.
rem Defaulting to Release
set BUILD_TYPE=Release

rem Specify if OPENSSL3 build is required, TRUE or FALSE.
rem Defaulting to TRUE
set BUILD_OPENSSL3=TRUE

rem Request PDB files - ON or OFF.
rem Defaulting to OFF
set INSTALL_PDB=OFF

rem Define build packages with their version. This is also the recommended build order.
set ZLIB=zlib-1.3.1
set BZIP2=bzip2-1.0.8
set XZ=xz-5.6.3
set PCRE2=pcre2-10.45
set ONIGURUMA=oniguruma-6.9.9
if /i "%BUILD_OPENSSL3%" == "TRUE" (
  set OPENSSL=openssl-3.3.3
) else (
  set OPENSSL=openssl-1.1.1w
)
set LIBXML2=libxml2-2.14.1
set SQLITE=sqlite-autoconf-3470200
set LIBICONV=libiconv-1.17
set LIBCURL=curl-8.13.0
set LIBPNG=libpng-1.6.45
set LIBJPEG=libjpeg-turbo-3.1.0
set FREETYPE=freetype-2.13.3
set LIBZIP=libzip-1.11.2

rem Use OpenSSL with PHP - ON or OFF.
rem Defaulting to ON
set PHP_USE_OPENSSL=ON

rem ------------------------------------------------------------------------------
rem
rem Define path to MS Visual Studio build environment script.
rem Check if VCVARSALL is set by the environment (e.g., GitHub Actions)
if not defined VCVARSALL (
  echo WARN: VCVARSALL environment variable not set. Trying default path...
  rem Attempt to find a default VS 2022 path if not set
  if "%PLATFORM%"=="x64" (
      set "VCVARSALL=C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
  ) else (
      set "VCVARSALL=C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars32.bat"
  )
  if not exist "%VCVARSALL%" (
       set "VCVARSALL=C:\Program Files (x86)\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars%PLATFORM%.bat"
  )
)

if exist "%VCVARSALL%" (
  echo Calling VCVARSALL: %VCVARSALL% with platform %PLATFORM%
  call "%VCVARSALL%" %PLATFORM%
) else (
  echo ERROR: Could not find "%VCVARSALL%". Please ensure it is set correctly or exists at the default path.
  exit /b 1
)

rem --- Create necessary base directories ---
if not exist "%BUILD_BASE%" mkdir "%BUILD_BASE%"
if not exist "%BUILD_BASE%\..\src" mkdir "%BUILD_BASE%\..\src"
if not exist "%PREFIX%" mkdir "%PREFIX%"
rem --- End Create necessary base directories ---

rem ------------------------------------------------------------------------------
rem
rem ZLIB

rem Check for package and switch to source folder.
rem
call :check_package_source %ZLIB%

if !STATUS! == 0 (
  set ZLIB_CMAKE_OPTS=-DCMAKE_INSTALL_PREFIX=%PREFIX% -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DBUILD_SHARED_LIBS=ON -DINSTALL_PKGCONFIG_DIR=%PREFIX%/lib/pkgconfig
  call :build_package %ZLIB% "!ZLIB_CMAKE_OPTS!" & if not !STATUS! == 0 exit /b !STATUS!
)

rem ------------------------------------------------------------------------------
rem
rem BZIP2

rem Check for package and switch to source folder.
rem
call :check_package_source %BZIP2%

if !STATUS! == 0 (
  echo. & echo Building %BZIP2%

  rem BZip2 doesn't have CMake support, use nmake
  nmake /f makefile.msc & call :get_status
  if !STATUS! == 0 (
    rem Manual install for bzip2
    if not exist "%PREFIX%\include" mkdir "%PREFIX%\include"
    if not exist "%PREFIX%\lib" mkdir "%PREFIX%\lib"
    if not exist "%PREFIX%\bin" mkdir "%PREFIX%\bin"

    copy bzlib.h "%PREFIX%\include\" 1>nul
    copy libbz2.lib "%PREFIX%\lib\" 1>nul
    copy bzip2.exe "%PREFIX%\bin\" 1>nul
  ) else (
    echo nmake for %BZIP2% failed with status !STATUS!
    exit /b !STATUS!
  )
)

rem ------------------------------------------------------------------------------
rem
rem XZ

rem Check for package and switch to source folder.
rem
call :check_package_source %XZ%

if !STATUS! == 0 (
  set XZ_CMAKE_OPTS=-DCMAKE_INSTALL_PREFIX=%PREFIX% -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DBUILD_SHARED_LIBS=ON
  call :build_package %XZ% "!XZ_CMAKE_OPTS!" & if not !STATUS! == 0 exit /b !STATUS!
)

rem ------------------------------------------------------------------------------
rem
rem PCRE2

rem Check for package and switch to source folder.
rem
call :check_package_source %PCRE2%

if !STATUS! == 0 (
  rem Patch CMakeLists.txt to change man page install path, and that of cmake config files.
  rem
  perl -pi.bak -e ^" ^
    s~(^.+DESTINATION ^)(man^)~${1}share/${2}~; ^
    s~(^install.+DESTINATION ^)(cmake^)~${1}lib/${2}/pcre2-\x24\x7BPCRE2_MAJOR\x7D.\x24\x7BPCRE2_MINOR\x7D~; ^
    ^" CMakeLists.txt

  set PCRE2_CMAKE_OPTS=-DCMAKE_INSTALL_PREFIX=%PREFIX% -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DBUILD_SHARED_LIBS=ON -DPCRE2_BUILD_TESTS=OFF -DPCRE2_BUILD_PCRE2GREP=OFF -DPCRE2_SUPPORT_JIT=OFF -DPCRE2_SUPPORT_UNICODE=ON -DPCRE2_NEWLINE=CRLF -DINSTALL_MSVC_PDB=%INSTALL_PDB%
  call :build_package %PCRE2% "!PCRE2_CMAKE_OPTS!" & if not !STATUS! == 0 exit /b !STATUS!
)

rem ------------------------------------------------------------------------------
rem
rem ONIGURUMA

rem Check for package and switch to source folder.
rem
call :check_package_source %ONIGURUMA%

if !STATUS! == 0 (
  set ONIGURUMA_CMAKE_OPTS=-DCMAKE_INSTALL_PREFIX=%PREFIX% -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DBUILD_SHARED_LIBS=ON
  call :build_package %ONIGURUMA% "!ONIGURUMA_CMAKE_OPTS!" & if not !STATUS! == 0 exit /b !STATUS!
)

rem ------------------------------------------------------------------------------
rem
rem OPENSSL

rem Check for package and switch to source folder.
rem
call :check_package_source %OPENSSL%

if !STATUS! == 0 (
  echo. & echo Building %OPENSSL%

  if /i "%PLATFORM%" == "x64" (
    set OS_COMPILER=VC-WIN64A
  ) else (
    set OS_COMPILER=VC-WIN32
  )

  if /i "%BUILD_TYPE%" == "Release" (
    set OPENSSL_BUILD_TYPE=--release
  ) else (
    set OPENSSL_BUILD_TYPE=--debug
  )
  set OPENSSL_CONFIGURE_OPTS=--prefix=%PREFIX% --libdir=lib --openssldir=%PREFIX%\conf --with-zlib-include=%PREFIX%\include shared zlib-dynamic enable-camellia no-idea no-mdc2 %OPENSSL_BUILD_TYPE%

  perl Configure !OS_COMPILER! !OPENSSL_CONFIGURE_OPTS! & call :get_status
  if !STATUS! == 0 (
    if exist makefile (
      if /i "%INSTALL_PDB%"=="OFF" (
        perl -pi.bak -e ^" ^
          s~^(INSTALL_.*PDBS=^).*~${1}nul~; ^
          ^" makefile
      )
      rem Make clean not distclean, else Makefile gets deleted.
      rem
      nmake clean 2>nul
      nmake & call :get_status
      if !STATUS! == 0 (
        nmake install & call :get_status
        if not !STATUS! == 0 (
          echo nmake install for %OPENSSL% failed with status !STATUS!
          exit /b !STATUS!
        )
      ) else (
        echo nmake for %OPENSSL% failed with status !STATUS!
        exit /b !STATUS!
      )
    ) else (
      echo Cannot find Makefile for %OPENSSL% in !SRC_DIR!
      exit /b !STATUS!
    )
  ) else (
    echo perl configure for %OPENSSL% failed with status !STATUS!
    exit /b !STATUS!
  )
)

rem ------------------------------------------------------------------------------
rem
rem LIBXML2

rem Check for package and switch to source folder.
rem
call :check_package_source %LIBXML2%

if !STATUS! == 0 (
  set LIBXML2_CMAKE_OPTS=-DCMAKE_INSTALL_PREFIX=%PREFIX% -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DBUILD_SHARED_LIBS=ON -DLIBXML2_WITH_ICONV=OFF -DLIBXML2_WITH_PYTHON=OFF -DLIBXML2_WITH_ZLIB=ON
  call :build_package %LIBXML2% "!LIBXML2_CMAKE_OPTS!" & if not !STATUS! == 0 exit /b !STATUS!
)

rem ------------------------------------------------------------------------------
rem
rem SQLITE

rem Check for package and switch to source folder.
rem
call :check_package_source %SQLITE%

if !STATUS! == 0 (
  echo. & echo Building %SQLITE%

  rem SQLite amalgamation build
  cl /c /O2 /MD /DSQLITE_API=__declspec(dllexport) /DSQLITE_ENABLE_COLUMN_METADATA sqlite3.c & call :get_status
  if !STATUS! == 0 (
    link /DLL /OUT:sqlite3.dll sqlite3.obj & call :get_status
    if !STATUS! == 0 (
      rem Manual install for sqlite
      if not exist "%PREFIX%\include" mkdir "%PREFIX%\include"
      if not exist "%PREFIX%\lib" mkdir "%PREFIX%\lib"
      if not exist "%PREFIX%\bin" mkdir "%PREFIX%\bin"

      copy sqlite3.h "%PREFIX%\include\" 1>nul
      copy sqlite3.lib "%PREFIX%\lib\" 1>nul
      copy sqlite3.dll "%PREFIX%\bin\" 1>nul
    ) else (
      echo link for %SQLITE% failed with status !STATUS!
      exit /b !STATUS!
    )
  ) else (
    echo cl for %SQLITE% failed with status !STATUS!
    exit /b !STATUS!
  )
)

rem ------------------------------------------------------------------------------
rem
rem LIBICONV

rem Check for package and switch to source folder.
rem
call :check_package_source %LIBICONV%

if !STATUS! == 0 (
  echo. & echo Building %LIBICONV%

  rem Run configure script for libiconv
  bash -c "./configure --prefix=%PREFIX:\=/% --enable-shared --disable-static" & call :get_status
  if !STATUS! == 0 (
    make & call :get_status
    if !STATUS! == 0 (
      make install & call :get_status
      if not !STATUS! == 0 (
        echo make install for %LIBICONV% failed with status !STATUS!
        exit /b !STATUS!
      )
    ) else (
      echo make for %LIBICONV% failed with status !STATUS!
      exit /b !STATUS!
    )
  ) else (
    echo configure for %LIBICONV% failed with status !STATUS!
    exit /b !STATUS!
  )
)

rem ------------------------------------------------------------------------------
rem
rem LIBCURL

rem Check for package and switch to source folder.
rem
call :check_package_source %LIBCURL%

if !STATUS! == 0 (
  set CURL_CMAKE_OPTS=-DCMAKE_INSTALL_PREFIX=%PREFIX% -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DCURL_USE_OPENSSL=%PHP_USE_OPENSSL% -DOPENSSL_ROOT_DIR=%PREFIX% -DCURL_USE_SCHANNEL=ON -DCURL_WINDOWS_SSPI=ON -DENABLE_UNICODE=ON -DCURL_STATIC_CRT=OFF -DUSE_WIN32_CRYPTO=ON -DUSE_LIBIDN2=OFF -DCURL_USE_LIBPSL=OFF -DCURL_USE_LIBSSH2=OFF

  call :build_package %LIBCURL% "!CURL_CMAKE_OPTS! -DBUILD_SHARED_LIBS=ON" & if not !STATUS! == 0 exit /b !STATUS!
  call :build_package %LIBCURL% "!CURL_CMAKE_OPTS! -DBUILD_SHARED_LIBS=OFF" & if not !STATUS! == 0 exit /b !STATUS!
)

rem ------------------------------------------------------------------------------
rem
rem LIBPNG

rem Check for package and switch to source folder.
rem
call :check_package_source %LIBPNG%

if !STATUS! == 0 (
  set LIBPNG_CMAKE_OPTS=-DCMAKE_INSTALL_PREFIX=%PREFIX% -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DBUILD_SHARED_LIBS=ON -DPNG_TESTS=OFF
  call :build_package %LIBPNG% "!LIBPNG_CMAKE_OPTS!" & if not !STATUS! == 0 exit /b !STATUS!
)

rem ------------------------------------------------------------------------------
rem
rem LIBJPEG

rem Check for package and switch to source folder.
rem
call :check_package_source %LIBJPEG%

if !STATUS! == 0 (
  set LIBJPEG_CMAKE_OPTS=-DCMAKE_INSTALL_PREFIX=%PREFIX% -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DBUILD_SHARED_LIBS=ON -DENABLE_STATIC=OFF -DWITH_TURBOJPEG=OFF
  call :build_package %LIBJPEG% "!LIBJPEG_CMAKE_OPTS!" & if not !STATUS! == 0 exit /b !STATUS!
)

rem ------------------------------------------------------------------------------
rem
rem FREETYPE

rem Check for package and switch to source folder.
rem
call :check_package_source %FREETYPE%

if !STATUS! == 0 (
  set FREETYPE_CMAKE_OPTS=-DCMAKE_INSTALL_PREFIX=%PREFIX% -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DBUILD_SHARED_LIBS=ON -DFT_DISABLE_HARFBUZZ=TRUE -DFT_DISABLE_BROTLI=TRUE
  call :build_package %FREETYPE% "!FREETYPE_CMAKE_OPTS!" & if not !STATUS! == 0 exit /b !STATUS!
)

rem ------------------------------------------------------------------------------
rem
rem LIBZIP

rem Check for package and switch to source folder.
rem
call :check_package_source %LIBZIP%

if !STATUS! == 0 (
  set LIBZIP_CMAKE_OPTS=-DCMAKE_INSTALL_PREFIX=%PREFIX% -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DBUILD_SHARED_LIBS=ON -DBUILD_TOOLS=OFF -DBUILD_REGRESS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_DOC=OFF
  call :build_package %LIBZIP% "!LIBZIP_CMAKE_OPTS!" & if not !STATUS! == 0 exit /b !STATUS!
)

rem ------------------------------------------------------------------------------
rem
rem PHP

rem Check for package and switch to source folder.
rem
call :check_package_source %PHP_SRC%

if !STATUS! == 0 (
  echo. & echo Building %PHP_SRC%

  rem PHP uses buildconf and configure on Windows
  rem This requires PHP SDK Binary Tools
  echo. & echo NOTE: PHP Windows build requires PHP SDK Binary Tools
  echo Please refer to: https://github.com/php/php-sdk-binary-tools
  echo.
  echo For now, we recommend using the official PHP Windows build process.
  echo This script has prepared all dependencies in: %PREFIX%
  echo.
  echo To build PHP manually:
  echo 1. Download PHP SDK Binary Tools
  echo 2. Run: phpsdk-vs17-x64.bat
  echo 3. Run: buildconf
  echo 4. Run: configure --with-prefix=%PREFIX% --enable-cli --with-openssl --with-curl --with-zlib --with-bz2 --enable-mbstring --enable-gd --with-jpeg --with-png --with-freetype --enable-zip --with-pdo-mysql --enable-pdo --with-sqlite3
  echo 5. Run: nmake
  echo 6. Run: nmake install
)

echo Build finished with status: !STATUS!
exit /b !STATUS!

rem ------------------------------------------------------------------------------
rem
rem Get current errorlevel value and assign it to the status variable.

:get_status
call doskey /exename=err err=%%errorlevel%%
for /f "usebackq tokens=2 delims== " %%i in (`doskey /m:err`) do (set STATUS=%%i)
exit /b !STATUS!

rem ------------------------------------------------------------------------------
rem
rem Get package and version from release variable passed as first parameter.

:get_package_details
set RELEASE=%~1
for /f "delims=-" %%i in ('echo(%RELEASE:-=^&echo(%') do call set "PACKAGE=%%RELEASE:-%%i=%%"
for %%i in (%RELEASE:-= %) do set VERSION=%%i
exit /b

rem ------------------------------------------------------------------------------
rem
rem Check package source folder exists, from release variable passed as first parameter.
rem Uses BUILD_BASE which should be set earlier.
:check_package_source

set SRC_DIR=%BUILD_BASE%\..\src\%~1
if not exist "!SRC_DIR!" (
  echo ERROR for package %~1
  echo Could not find package source folder "!SRC_DIR!"
  set STATUS=1
) else (
  cd /d "!SRC_DIR!"
  set STATUS=0
)
exit /b !STATUS!

rem ------------------------------------------------------------------------------
rem
rem Build subroutine.
rem Parameter one is the package release variable.
rem Parameter two is any required CMake options.
rem Parameter three (optional) is any package sub-folder to the CMakeLists.txt file.

:build_package

call :get_package_details %~1

rem Check source folder exists, else exit (non-fatal).

call :check_package_source %~1
if not !STATUS! == 0 (
  exit /b !STATUS!  REM Exit if source not found
) else (
  if not "%~3" == "" (
    set SRC_DIR=!SRC_DIR!\%~3
  )
)

rem Clean up any previous build.

if exist "%BUILD_BASE%\!PACKAGE!" rmdir /s /q "%BUILD_BASE%\!PACKAGE!" 1>nul 2>&1
mkdir "%BUILD_BASE%\!PACKAGE!" 1>nul 2>&1

rem Build, make and install.

if exist "%BUILD_BASE%\!PACKAGE!" (
  cd /d "%BUILD_BASE%\!PACKAGE!"
  echo. & echo Building %~1

  rem Patch CMakeLists.txt to remove debug suffix from libraries. Messes up various builds.
  rem Tried setting CMAKE_DEBUG_POSTFIX to an empty string on the CMake command line but
  rem this doesn't work with all packages, e.g. PCRE2, EXPAT, LIBXML2, etc.
  rem Ensure CMakeLists.txt exists before patching
  if exist "!SRC_DIR!\CMakeLists.txt" (
    perl -pi -e ^" ^
      s~((DEBUG_POSTFIX^|POSTFIX_DEBUG^)\s+^)([\x22]*^)[-_]*(^|s^)d([\x22]*^)~${1}\x22${4}\x22~; ^
      ^" "!SRC_DIR!\CMakeLists.txt"
  ) else (
     echo WARN: CMakeLists.txt not found in !SRC_DIR! for patching debug suffix. Skipping patch.
  )

  rem Run CMake to create an NMake makefile, which we then process.

  cmake -G "NMake Makefiles" %~2 -S "!SRC_DIR!" -B . & call :get_status
  if !STATUS! == 0 (
    nmake & call :get_status
    if !STATUS! == 0 (
      nmake install & call :get_status
      if !STATUS! == 0 (
        exit /b !STATUS!
      ) else (
        echo ERROR: nmake install for !PACKAGE! failed with exit status !STATUS!
        exit /b !STATUS!
      )
    ) else (
      echo ERROR: nmake for !PACKAGE! failed with exit status !STATUS!
      exit /b !STATUS!
    )
  ) else (
    echo ERROR: cmake for !PACKAGE! failed with exit status !STATUS!
    exit /b !STATUS!
  )
) else (
  echo ERROR: Failed to make folder "%BUILD_BASE%\!PACKAGE!"
  exit /b 1
)
exit /b

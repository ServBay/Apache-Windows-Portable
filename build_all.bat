@echo off

rem @(#)build_all.bat 3.4 - 2025-04-08 tangent
rem
rem 1.0 - Initial release. 2020-12-17
rem 1.1 - Switch CURL to Schannel (WinSSL) rather than OpenSSL, for mod_md.
rem       Accordingly, remove LIBSSH2. Remove YAJL and MOD_SECURITY since not core
rem       ASF/Apache modules. Add LUA_COMPAT_ALL compile option to LUA. 2020-12-18
rem 1.2 - Move CURL build after NGHTTP2 and update options to include HTTP2, BROTLI and UNICODE. 2021-01-03
rem 1.3 - Use OpenSSL (conditionally) with CURL and patch to force use of native CA store on Windows.
rem       Request CURL builds with LDAPS support (Schannel based). 2021-02-16
rem 1.4 - Remove extraneous CMake INSTALL_MSVC_PDB option entries.
rem       Bump releases: PCRE (8.45), EXPAT (2.4.1), OPENSSL (1.1.1l), LIBXML2 (2.9.12),
rem       LUA (5.4.3), NGHTTP2 (1.44.0), CURL (7.78.0), HTTPD (2.4.48). 2021-08-27
rem 1.5 - Bump releases: JANSSON (2.14), NGHTTP2 (1.46.0), CURL (7.80.0), HTTPD (2.4.51). 2021-11-22
rem 1.6 - Bump releases: HTTPD (2.4.52), OpenSSL (1.1.1m). 2021-12-28
rem 1.7 - Bump EXPAT (2.4.2), CURL (7.81.0). Change LUA option LUA_COMPAT_ALL to LUA_COMPAT_5_3.
rem       Patch APR (1.7.0) handle leak (PR 61165 [Ivan Zhakov]). Refine Perl patch edits.
rem       Update VCVARSALL script path for MS Visual Studio 2022 (VS17). 2022-01-14
rem 1.8 - Bump CURL (7.82.0), EXPAT (2.4.7), HTTPD (2.4.53), LUA (5.4.4), NGHTTP2 (1.47.0),
rem       OPENSSL (1.1.1n/3.0.2), PCRE2 (10.39). Provide options to build PCRE2 rather than PCRE,
rem       and similarly build OpenSSL3 rather than OpenSSL. 2022-03-17
rem 1.9 - Bump CURL (7.83.1), EXPAT (2.4.8), HTTPD (2.4.54), LIBXML2 (2.9.14), OPENSSL (1.1.1o/3.0.3),
rem       PCRE2 (10.40), ZLIB (1.2.12). 2022-06-13
rem 2.0 - Bump CURL (7.86.0), EXPAT (2.5.0), LIBXML2 (2.10.3), OPENSSL (1.1.1s/3.0.7), ZLIB (1.2.13).
rem       Add option to set CURL default SSL backend to Schannel rather than OpenSSL. 2022-11-10
rem 2.1 - Bump APR (1.7.2), APR-UTIL (1.6.3), CURL (7.87.0), HTTPD (2.4.55), NGHTTP2 (1.51.0),
rem       PCRE2 (10.42). 2023-02-05
rem 2.2 - Bump CURL (7.88.1), HTTPD (2.4.56), NGHTTP2 (1.52.0), OPENSSL (1.1.1t/3.0.8). 2023-03-08
rem 2.3 - Bump APR (1.7.4), CURL (8.0.1), HTTPD (2.4.57), LIBXML2 (2.11.2), OPENSSL (1.1.1t/3.1.0). 2023-05-12
rem 2.4 - Bump CURL (8.2.1), LIBXML2 (2.11.5), LUA (5.4.6), NGHTTP2 (1.55.1), OPENSSL (1.1.1v/3.1.2). 2023-08-10
rem 2.5 - Bump BROTLI (1.1.0), CURL (8.4.0), HTTPD (2.4.58), NGHTTP2 (1.57.0), OPENSSL (1.1.1w/3.1.3). 2023-10-20
rem 2.6 - Patch HTTPD ApacheMonitor.rc file to comment out MANIFEST file reference, which otherwise
rem       causes a duplicate resource cvtres/link error following recent updates to VS2022.
rem       Bump CURL (8.6.0), LIBXML2 (2.12.5), NGHTTP2 (1.59.0), OPENSSL (3.1.5), ZLIB (1.3.1). 2024-02-04
rem 2.7 - Bump CURL (8.7.1), EXPAT (2.6.2), HTTPD (2.4.59), LIBXML2 (2.12.6), NGHTTP2 (1.61.0), PCRE2 (10.43). 2024-04-04
rem 2.8 - Bump CURL (8.8.0), LIBXML2 (2.12.7), NGHTTP2 (1.62.1), OPENSSL (3.1.6), PCRE2 (10.44). 2024-06-07
rem 2.9 - Bump HTTPD (2.4.62), LIBXML2 (2.13.2), LUA (5.4.7). 2024-07-25
rem 3.0 - Bump APR (1.7.5), CURL (8.9.1), LIBXML2 (2.13.3), NGHTTP2 (1.63.0), OPENSSL (3.1.17).
rem       Add option to CURL build to disable searching for idn2 library. 2024-09-06
rem 3.1 - Bump CURL (8.11.0), EXPAT (2.6.4), LIBXML2 (2.13.5), NGHTTP2 (1.64.0). Patch mod_rewrite.c
rem       to apply Eric Coverner's patch r1919860 as mentioned in the Apache Lounge 2.4.62 Changelog.
rem       Expose result of mklink command when creating APR symbolic links, in case it fails. 2024-11-13
rem 3.2 - Bump CURL (8.11.1), HTTPD (2.4.63), and OPENSSL (3.4.0). 2025-01-24
rem 3.3 - Bump CURL (8.12.1), LIBXML2 (2.13.6), and PCRE (10.45). Regress OPENSSL (3.3.3).
rem       Add options to CURL build to disable using libpsl and libssh2 libraries.
rem       Add BUILD_TYPE option support to OpenSSL. 2025-03-01
rem 3.4 - Bump CURL (8.13.0), EXPAT (2.7.1), JANSSON (2.14.1), LIBXML2 (2.14.1), and NGHTTP2 (1.65.0).
rem       Don't define VCVARSALL variable if already set. Drop support for old PCRE series and revise CMake options.
rem       Switch LIBXML2 build to using CMake. Revise CURL CMake config to prevent possible command line overflow.
rem       Resolve mod_session_crypto issue by updating APR-UTIL build to use OpenSSL with APU_HAVE_CRYPTO.
rem       Refine script logic when BUILD_TYPE is set to DEBUG. 2025-04-08

rem Apache build command file for Windows.
rem
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

rem --- GitHub Actions Integration ---
rem Use environment variables if set, otherwise use defaults.
if defined BUILD_BASE_ENV (
  set BUILD_BASE=%BUILD_BASE_ENV%
) else (
  echo WARN: BUILD_BASE_ENV not set, using default C:\Development\Apache24\build
  set BUILD_BASE=C:\Development\Apache24\build
)
if defined PREFIX_ENV (
  set PREFIX=%PREFIX_ENV%
) else (
  echo WARN: PREFIX_ENV not set, using default C:\ServBay\packages\apache
  set PREFIX=C:\ServBay\packages\apache
)
echo Using BUILD_BASE: %BUILD_BASE%
echo Using PREFIX: %PREFIX%
rem --- End GitHub Actions Integration ---


rem Set required build platform to x86 or x64.
rem Defaulting to x64 for GitHub Actions typical use case
rem set PLATFORM=x86
set PLATFORM=x64

rem Set required build type to Release or Debug.
rem Defaulting to Release
rem set BUILD_TYPE=Debug
set BUILD_TYPE=Release

rem Specify if OPENSSL3 build is required, TRUE or FALSE.
rem Defaulting to TRUE
set BUILD_OPENSSL3=TRUE

rem Request PDB files - ON or OFF.
rem Defaulting to OFF
set INSTALL_PDB=OFF

rem Define build packages with their version. This is also the recommended build order.
set ZLIB=zlib-1.3.1
set PCRE2=pcre2-10.45
set EXPAT=expat-2.7.1
if /i "%BUILD_OPENSSL3%" == "TRUE" (
  set OPENSSL=openssl-3.3.3
) else (
  set OPENSSL=openssl-1.1.1w
)
set LIBXML2=libxml2-2.14.1
set JANSSON=jansson-2.14.1
set BROTLI=brotli-1.1.0
set LUA=lua-5.4.7
set APR=apr-1.7.5
set APR-ICONV=apr-iconv-1.2.2
set APR-UTIL=apr-util-1.6.3
set NGHTTP2=nghttp2-1.65.0
set CURL=curl-8.13.0
set HTTPD=httpd-2.4.63
set MOD_FCGID=mod_fcgid-2.3.9

rem Use OpenSSL with CURL - ON or OFF.
rem Defaulting to ON
set CURL_USE_OPENSSL=ON
rem
rem Specify CURL default SSL backend. Defaults to OpenSSL if not specified.
rem NB - you can change the SSL backend at run time with environment variable CURL_SSL_BACKEND.
rem Defaulting to SCHANNEL
set CURL_DEFAULT_SSL_BACKEND=SCHANNEL

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
  set ZLIB_CMAKE_OPTS=-DCMAKE_INSTALL_PREFIX=%PREFIX% -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DBUILD_SHARED_LIBS=ON -DINSTALL_PKGCONFIG_DIR=%PREFIX%/lib/pkgconfig
  call :build_package %ZLIB% "!ZLIB_CMAKE_OPTS!" & if not !STATUS! == 0 exit /b !STATUS!
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

  set PCRE2_CMAKE_OPTS=-DCMAKE_INSTALL_PREFIX=%PREFIX% -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DBUILD_SHARED_LIBS=ON -DPCRE2_BUILD_TESTS=OFF -DPCRE2_BUILD_PCRE2GREP=OFF -DPCRE2_SUPPORT_JIT=OFF -DPCRE2_SUPPORT_UNICODE=ON -DPCRE2_NEWLINE=CRLF -DINSTALL_MSVC_PDB=%INSTALL_PDB%
  call :build_package %PCRE2% "!PCRE2_CMAKE_OPTS!" & if not !STATUS! == 0 exit /b !STATUS!
)

rem ------------------------------------------------------------------------------
rem
rem EXPAT

rem Check for package source folder.
rem
call :check_package_source %EXPAT%

if !STATUS! == 0 (
  set EXPAT_CMAKE_OPTS=-DCMAKE_INSTALL_PREFIX=%PREFIX% -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DCMAKE_POLICY_VERSION_MINIMUM=3.5
  call :build_package %EXPAT% "!EXPAT_CMAKE_OPTS!" & if not !STATUS! == 0 exit /b !STATUS!
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
  set LIBXML2_CMAKE_OPTS=-DCMAKE_INSTALL_PREFIX=%PREFIX% -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DBUILD_SHARED_LIBS=ON -DLIBXML2_WITH_ICONV=OFF -DLIBXML2_WITH_PYTHON=OFF -DLIBXML2_WITH_ZLIB=ON
  call :build_package %LIBXML2% "!LIBXML2_CMAKE_OPTS!" & if not !STATUS! == 0 exit /b !STATUS!
)

rem ------------------------------------------------------------------------------
rem
rem JANSSON

rem Check for package and switch to source folder.
rem
call :check_package_source %JANSSON%

if !STATUS! == 0 (
  set JANSSON_CMAKE_OPTS=-DCMAKE_INSTALL_PREFIX=%PREFIX% -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DJANSSON_BUILD_SHARED_LIBS=ON -DJANSSON_BUILD_DOCS=OFF -DJANSSON_INSTALL_CMAKE_DIR=lib/cmake/jansson
  call :build_package %JANSSON% "!JANSSON_CMAKE_OPTS!" & if not !STATUS! == 0 exit /b !STATUS!
)

rem ------------------------------------------------------------------------------
rem
rem BROTLI

rem Check for package and switch to source folder.
rem
call :check_package_source %BROTLI%

if !STATUS! == 0 (
  set BROTLI_CMAKE_OPTS=-DCMAKE_INSTALL_PREFIX=%PREFIX% -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DCMAKE_POLICY_VERSION_MINIMUM=3.5
  call :build_package %BROTLI% "!BROTLI_CMAKE_OPTS!" & if not !STATUS! == 0 exit /b !STATUS!
)

rem ------------------------------------------------------------------------------
rem
rem LUA

rem Check for package and switch to source folder.
rem
call :check_package_source %LUA%

if !STATUS! == 0 (
  rem Patch CMakeLists.txt to add LUA_COMPAT_5_3 to compile options.
  rem
  perl -pi.bak -e ^" ^
    s~( LUA_BUILD_AS_DLL ^)(^\^)^)~${1}LUA_COMPAT_5_3 ${2}~; ^
    ^" CMakeLists.txt

  set LUA_CMAKE_OPTS=-DCMAKE_INSTALL_PREFIX=%PREFIX% -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DCMAKE_POLICY_VERSION_MINIMUM=3.5
  call :build_package %LUA% "!LUA_CMAKE_OPTS!" & if not !STATUS! == 0 exit /b !STATUS!
)

rem ------------------------------------------------------------------------------
rem
rem APR

rem Check for package and switch to source folder.
rem
call :check_package_source %APR%

if !STATUS! == 0 (
  rem Patch apr.hw - _WIN32_WINT to 0x600 series
  perl -pi.bak -e ^" ^
    s~(#define _WIN32_WINNT ^)0x05\d\d$~${1}0x0600~; ^
    ^" include\apr.hw

  set APR_CMAKE_OPTS=-DCMAKE_INSTALL_PREFIX=%PREFIX% -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DMIN_WINDOWS_VER=0x0600 -DAPR_HAVE_IPV6=ON -DAPR_INSTALL_PRIVATE_H=ON -DAPR_BUILD_TESTAPR=OFF -DINSTALL_PDB=%INSTALL_PDB%
  call :build_package %APR% "!APR_CMAKE_OPTS!" & if not !STATUS! == 0 exit /b !STATUS!
)

rem ------------------------------------------------------------------------------
rem
rem APR-ICONV

rem Note APR-ICONV makefiles rebuild APR since the above CMake puts the build files elsewhere.

rem Check for package and switch to source folder.
rem
call :check_package_source %APR-ICONV%

if !STATUS! == 0 (
  echo. & echo Building %APR-ICONV%

  rem Create non-version specific folder links to the APR, APR-ICONV and APR-UTIL sources.
  rem The various makefiles assume these exist.
  rem Ensure the target directories exist before creating links
  if not exist "%BUILD_BASE%\..\src\%APR%" echo ERROR: Source directory %BUILD_BASE%\..\src\%APR% not found! && exit /b 1
  if not exist "%BUILD_BASE%\..\src\%APR-ICONV%" echo ERROR: Source directory %BUILD_BASE%\..\src\%APR-ICONV% not found! && exit /b 1
  if not exist "%BUILD_BASE%\..\src\%APR-UTIL%" echo ERROR: Source directory %BUILD_BASE%\..\src\%APR-UTIL% not found! && exit /b 1

  pushd "%BUILD_BASE%\..\src"
  if exist apr rmdir apr > nul 2>&1
  if exist apr-iconv rmdir apr-iconv > nul 2>&1
  if exist apr-util rmdir apr-util > nul 2>&1
  mklink /d apr %APR%
  echo Result of mklink apr: %ERRORLEVEL%
  mklink /d apr-iconv %APR-ICONV%
  echo Result of mklink apr-iconv: %ERRORLEVEL%
  mklink /d apr-util %APR-UTIL%
  echo Result of mklink apr-util: %ERRORLEVEL%
  popd

  rem Copy apr.h and apr_escape_test_char.h from APR build into API source.
  rem Ensure source files exist before copying
  if not exist "%BUILD_BASE%\apr\apr.h" echo ERROR: %BUILD_BASE%\apr\apr.h not found! && exit /b 1
  copy "%BUILD_BASE%\apr\apr*.h" ".\include" 1>nul
  if not exist "%BUILD_BASE%\apr\apr_escape_test_char.h" echo ERROR: %BUILD_BASE%\apr\apr_escape_test_char.h not found! && exit /b 1
  copy "%BUILD_BASE%\apr\apr_escape_test_char.h" "..\%APR%\include" 1>nul

  rem Choose platform options; reference as delayed expansion variables.
  rem
  if /i "%PLATFORM%" == "x64" (
    set BUILD_CFG=x64
    set BUILD_DIR=x64
  ) else (
    set BUILD_CFG=Win32
    set BUILD_DIR=.
  )

  rem Patch modules.mk.win for x64 Debug
  rem
  perl -pi.bak -e ^" ^
    m~(APR_SOURCE\^)\\^)(.+\\^)(Debug\\libapr-1^)~;{${2} ? $s=${2} : $s=$s}; ^
    s~(API_SOURCE\^)\\^)(Debug\\libapriconv-1^)~{$s ? ${1}.$s.${2} : $^&}~e; ^
    s~(CFG_OUTPUT  = ^)(Debug\\iconv^)~{$s ? ${1}.$s.${2} : $^&}~e; ^
    ^" build\modules.mk.win

  rmdir /s /q Debug LibD LibR Release x64 1>nul 2>&1
  nmake /f apriconv.mak CFG="apriconv - !BUILD_CFG! %BUILD_TYPE%" & call :get_status
  if not !STATUS! == 0 (
    echo nmake apriconv.mak for %APR-ICONV% failed with status !STATUS!
    exit /b !STATUS!
  )
  nmake /f libapriconv.mak CFG="libapriconv - !BUILD_CFG! %BUILD_TYPE%" & call :get_status
  if not !STATUS! == 0 (
    echo nmake libapriconv.mak for %APR-ICONV% failed with status !STATUS!
    exit /b !STATUS!
  )
  pushd ccs
  nmake /f Makefile.win BUILD_MODE="!BUILD_CFG! %BUILD_TYPE%" BIND_MODE="shared" & call :get_status
  if not !STATUS! == 0 (
    echo nmake ccs Makefile.win for %APR-ICONV% failed with status !STATUS!
    popd
    exit /b !STATUS!
  )
  popd
  pushd ces
  nmake /f Makefile.win BUILD_MODE="!BUILD_CFG! %BUILD_TYPE%" BIND_MODE="shared" & call :get_status
  if not !STATUS! == 0 (
    echo nmake ces Makefile.win for %APR-ICONV% failed with status !STATUS!
    popd
    exit /b !STATUS!
  )
  popd

  rem Manual install required with apr-iconv
  rem
  if exist "!BUILD_DIR!\LibD\apriconv-1.lib" (
    echo -- Installing: "%PREFIX%\lib\apriconv-1.lib"
    copy /b /y "!BUILD_DIR!\LibD\apriconv-1.lib" "%PREFIX%\lib" 1>nul 2>&1
  )
  if exist "!BUILD_DIR!\LibR\apriconv-1.lib" (
    echo -- Installing: "%PREFIX%\lib\apriconv-1.lib"
    copy /b /y "!BUILD_DIR!\LibR\apriconv-1.lib" "%PREFIX%\lib" 1>nul 2>&1
  )
  if exist "!BUILD_DIR!\%BUILD_TYPE%\libapriconv-1.lib" (
    echo -- Installing: "%PREFIX%\lib\libapriconv-1.lib"
    copy /b /y "!BUILD_DIR!\%BUILD_TYPE%\libapriconv-1.lib" "%PREFIX%\lib" 1>nul 2>&1
  )
  if exist "!BUILD_DIR!\%BUILD_TYPE%\libapriconv-1.dll" (
    echo -- Installing: "%PREFIX%\bin\libapriconv-1.dll"
    copy /b /y "!BUILD_DIR!\%BUILD_TYPE%\libapriconv-1.dll" "%PREFIX%\bin" 1>nul 2>&1
  )
  if exist "include\api_version.h" (
    echo -- Installing: "%PREFIX%\include\api_version.h"
    copy /b /y "include\api_version.h" "%PREFIX%\include" 1>nul 2>&1
  )
  if exist "include\apr_iconv.h" (
    echo -- Installing: "%PREFIX%\include\apr_iconv.h"
    copy /b /y "include\apr_iconv.h" "%PREFIX%\include" 1>nul 2>&1
  )
  if exist "!BUILD_DIR!\%BUILD_TYPE%\iconv" (
    echo -- Installing: "%PREFIX%\bin\iconv"
    xcopy "!BUILD_DIR!\%BUILD_TYPE%\iconv\*.so" "%PREFIX%\bin\iconv\" /c /d /i /y 1>nul 2>&1
  )
)

rem ------------------------------------------------------------------------------
rem
rem APR-UTIL

rem Check for package and switch to source folder.
rem
call :check_package_source %APR-UTIL%

if !STATUS! == 0 (
  rem Patch CMakelists.txt to support APR-ICONV if we've built it.
  rem
  if exist "%PREFIX%\lib\libapriconv-1.lib" (
    perl -pi.bak -e ^" ^
      s~^(SET.+APR_LIBRARIES[\s]+^)(\x22^)(.+libapr^)(-1.lib^)(.+ CACHE^)~${1}${2}${3}${4}${2} ${2}${3}iconv${4}${5}~; ^
      s~^(apu_have_apr_iconv_10^) 0~${1} 1~; ^
      ^" CMakeLists.txt
  )

  rem Check if we're building APR-UTIL 1.6.3
  rem
  if not x%APR-UTIL:1.6.3=%==x:%APR-UTIL% (
    rem Patch include\apu.hwc and CMakelists.txt to support OpenSSL, which is needed with APU_HAVE_CRYPTO.
    rem
    if exist "%PREFIX%\lib\libcrypto.lib" (
      perl -pi.bak -e ^" ^
        s~^(APU_HAVE_OPENSSL[\s]+^)0$~${1}\@apu_have_openssl_10\@~; ^
        ^" include\apu.hwc

      perl -pi.bak -e ^" ^
        s~^([\s]+^)(SET.+apu_have_crypto_10 1\^)^)$~${1}${2} \n${1}SET(apu_have_openssl_10 1^)~; ^
        ^" CMakeLists.txt
    )
  )

  set APR-UTIL_CMAKE_OPTS=-DCMAKE_INSTALL_PREFIX=%PREFIX% -DOPENSSL_ROOT_DIR=%PREFIX% -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DAPU_HAVE_CRYPTO=ON -DAPR_BUILD_TESTAPR=OFF -DINSTALL_PDB=%INSTALL_PDB%
  call :build_package %APR-UTIL% "!APR-UTIL_CMAKE_OPTS!" & if not !STATUS! == 0 exit /b !STATUS!
)

rem ------------------------------------------------------------------------------
rem
rem NGHTTP2

rem Check for package and switch to source folder.
rem
call :check_package_source %NGHTTP2%

if !STATUS! == 0 (
  set NGHTTP2_CMAKE_OPTS=-DCMAKE_INSTALL_PREFIX=%PREFIX% -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DSTATIC_LIB_SUFFIX=_static -DENABLE_LIB_ONLY=ON
  call :build_package %NGHTTP2% "!NGHTTP2_CMAKE_OPTS!" & if not !STATUS! == 0 exit /b !STATUS!
)

rem ------------------------------------------------------------------------------
rem
rem CURL - have to build twice to get both shared and static libs.

rem Check for package and switch to source folder.
rem
call :check_package_source %CURL%

if !STATUS! == 0 (
  if /i "%CURL_USE_OPENSSL%" == "ON" (
    rem Patch lib\url.c to force use of native CA store on Windows.
    rem
    perl -pi.bak -0777 -Mopen=OUT,:raw -e ^" ^
    s~(return result;\n#endif$^)\n  }~${1} \n#if defined(USE_WIN32_CRYPTO^)\n^
    /* Mandate Windows CA store to be used */\n^
    if(\x21set-\x3Essl.primary.CAfile \x26\x26 \x21set-\x3Essl.primary.CApath^) {\n^
      /* User and environment did not specify any CA file or path.\n^
       */\n^
      set-\x3Essl.native_ca_store = TRUE;\n^
    }\n#endif\n  }~smg; ^
    ^" lib\url.c
  ) else (
    rem Remove above lib\url.c patch if present.
    rem
    perl -pi.bak -0777 -Mopen=OUT,:raw -e ^" ^
    s~(return result;\n#endif^) \n.+native_ca_store = TRUE;\n    }\n#endif\n~${1}\n~smg; ^
    ^" lib\url.c
  )

  if /i "%CURL_USE_OPENSSL%" == "ON" if /i "%CURL_DEFAULT_SSL_BACKEND%" == "SCHANNEL" (
    rem Patch CMakeLists.txt to add a compiler definition for a default SSL backend of Schannel.
    rem
    perl -pi.bak -e ^" ^
      s~(USE_OPENSSL ON\^)^)\n~${1} \n  add_definitions(-DCURL_DEFAULT_SSL_BACKEND=\x22schannel\x22^)\n~m; ^
      ^" CMakeLists.txt
  ) else (
    rem Remove above CMakeLists.txt patch if present.
    rem
    perl -pi.bak -e ^" ^
      s~(USE_OPENSSL ON\^)^) \n~${1}\n~m; ^
      s~[ ]+add_definitions.+CURL_DEFAULT_SSL_BACKEND=.*\n~~m; ^
      ^" CMakeLists.txt
  )

  rem Patch doc build CMakeLists.txt to reduce number of files processed per batch loop.
  rem This reduces the chance of line length overflow problems with Windows command shell.
  rem
  perl -pi.bak -e ^" ^
    s~(_files_per_batch[\s]+^)200(\^)^)~${1}100${2}~m; ^
    ^" docs\libcurl\CMakeLists.txt

  set CURL_CMAKE_OPTS=-DCMAKE_INSTALL_PREFIX=%PREFIX% -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DCURL_USE_OPENSSL=%CURL_USE_OPENSSL% -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DOPENSSL_ROOT_DIR=%PREFIX% -DCURL_USE_SCHANNEL=ON -DCURL_WINDOWS_SSPI=ON -DCURL_BROTLI=ON -DUSE_NGHTTP2=ON -DHAVE_LDAP_SSL=ON -DENABLE_UNICODE=ON -DCURL_STATIC_CRT=OFF -DUSE_WIN32_CRYPTO=ON -DUSE_LIBIDN2=OFF -DCURL_USE_LIBPSL=OFF -DCURL_USE_LIBSSH2=OFF

  call :build_package %CURL% "!CURL_CMAKE_OPTS! -DBUILD_SHARED_LIBS=ON" & if not !STATUS! == 0 exit /b !STATUS!
  call :build_package %CURL% "!CURL_CMAKE_OPTS! -DBUILD_SHARED_LIBS=OFF" & if not !STATUS! == 0 exit /b !STATUS!
)

rem ------------------------------------------------------------------------------
rem
rem HTTPD

rem Check for package and switch to source folder.
rem
call :check_package_source %HTTPD%

if !STATUS! == 0 (
  rem Patch CMakeLists.txt to build ApacheMonitor.
  rem
  perl -pi.bak -e ^" ^
    s~(^^# ^)(.+ApacheMonitor.+^)~${2}~; ^
    ^" CMakeLists.txt

  rem Patch ApacheMonitor.rc to comment out MANIFEST file reference.
  rem
  perl -pi.bak -e ^" ^
    s~(^^CREATEPROCESS_MANIFEST^)~// ${1}~; ^
    ^" support\win32\ApacheMonitor.rc

  rem Check if we're building HTTPD 2.4.62 and if so patch mod_rewrite.c
  rem
  if not x%HTTPD:2.4.62=%==x:%HTTPD% (
    rem Patch mod_rewrite.c to apply Eric Coverner's patch r1919860 as mentioned
    rem in the Apache Lounge 2.4.62 Changelog
    rem
    rem Note \h denotes horizontal whitespace...
    perl -pi.bak -0777 -Mopen=OUT,:raw -e ^" ^
      s~^([\h]+^)(int is_proxyreq = 0;\n^)(\n[\h]+ctx^)~${1}${2}${1}int prefix_added = 0;\n${3}~smg; ^
      s~^([\h]+^)(newuri = apr_pstrcat[^^;]+;^)\n([\h]+\}^)~${1}${2}\n${1}prefix_added = 1;\n${3}~smg; ^
      ^" modules\mappers\mod_rewrite.c
  )

  set HTTPD_CMAKE_OPTS=-DCMAKE_INSTALL_PREFIX=%PREFIX% -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DINSTALL_PDB=%INSTALL_PDB% -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DOPENSSL_ROOT_DIR=%PREFIX%
  call :build_package %HTTPD% "!HTTPD_CMAKE_OPTS!" & if not !STATUS! == 0 exit /b !STATUS!

  rem Install additional support scripts.
  rem Ensure source directory exists before proceeding
  if not exist "!src_dir!\support\dbmmanage.in" echo ERROR: !src_dir!\support\dbmmanage.in not found! && exit /b 1
  perl -pe ^" ^
    s~#.+perlbin.+\n~~m; ^
    ^" "!src_dir!\support\dbmmanage.in" > "%PREFIX%\bin\dbmmanage.pl"

  if not exist "!src_dir!\docs\cgi-examples\printenv" echo ERROR: !src_dir!\docs\cgi-examples\printenv not found! && exit /b 1
  if not exist "%PREFIX%\cgi-bin" mkdir "%PREFIX%\cgi-bin"
  copy "!src_dir!\docs\cgi-examples\printenv" "%PREFIX%\cgi-bin\printenv.pl" 1>nul 2>&1
)

rem ------------------------------------------------------------------------------
rem
rem MOD_FCGID

rem Check for package and switch to source folder.
rem
call :check_package_source %MOD_FCGID%

if !STATUS! == 0 (
  rem Package provides both NMake makefile and experimental CMake. We use the latter.

  set MOD_FCGID_CMAKE_OPTS=-DCMAKE_INSTALL_PREFIX=%PREFIX% -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DINSTALL_PDB=NO -DCMAKE_POLICY_VERSION_MINIMUM=3.5
  call :build_package %MOD_FCGID% "!MOD_FCGID_CMAKE_OPTS!" modules\fcgid & if not !STATUS! == 0 exit /b !STATUS!
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

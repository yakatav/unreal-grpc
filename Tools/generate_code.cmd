@echo off
setlocal enabledelayedexpansion

::set current directory as proto file path
set INPUT_PROTO_PATH=%cd%

:: initialize
set count=0

:: Searches for proto files and stores them in an array
for /r "%INPUT_PROTO_PATH%" %%f in (*.proto) do (
    set /a count+=1
    set INPUT_PROTO_FILES_ARRAY[!count!]=%%f
)

:: Display array contents for debugging
for /l %%i in (1,1,%count%) do (
    echo Found: !INPUT_PROTO_FILES_ARRAY[%%i]!
)

:: check array contents
for /l %%i in (1,1,%count%) do (
    set "INPUT_PROTO_FILE=!INPUT_PROTO_FILES_ARRAY[%%i]!"
    if not exist "!INPUT_PROTO_FILE!" (
        echo Input proto file '!INPUT_PROTO_FILE!' does not exist!
        endlocal
        pause
        exit /b 1
    )
)

::make sure output path exist
set OUTPUT_PATH=%1
if not exist %OUTPUT_PATH% (
	echo Output path '%OUTPUT_PATH%' not exist!
	pause
	exit /b 1
)

::get turbolink plugin path
pushd %~dp0\..
set TL_UE_PLUGIN_PATH=%cd%
popd

set TURBOLINK_PLUGIN_PATH=%TL_UE_PLUGIN_PATH%\Tools\protoc-gen-turbolink.exe
set PROTOC_EXE_PATH=%TL_UE_PLUGIN_PATH%\Source\ThirdParty\protobuf\bin\protoc.exe
set PROTOBUF_INC_PATH=%TL_UE_PLUGIN_PATH%\Source\ThirdParty\protobuf\include
set GRPC_CPP_PLUGIN_EXE_PATH=%TL_UE_PLUGIN_PATH%\Source\ThirdParty\grpc\bin\grpc_cpp_plugin.exe
set FIX_PROTO_CPP=%TL_UE_PLUGIN_PATH%\Tools\fix_proto_cpp.txt
set FIX_PROTO_H=%TL_UE_PLUGIN_PATH%\Tools\fix_proto_h.txt
set CPP_OUTPUT_PATH=%OUTPUT_PATH%\Private\pb
if not exist %CPP_OUTPUT_PATH% mkdir %CPP_OUTPUT_PATH%

:: Print Variables for debugging

echo Checking existence of files or directories...

set "variables=TURBOLINK_PLUGIN_PATH PROTOC_EXE_PATH PROTOBUF_INC_PATH GRPC_CPP_PLUGIN_EXE_PATH FIX_PROTO_CPP FIX_PROTO_H CPP_OUTPUT_PATH"

set "errorFlag=0"
for %%v in (%variables%) do (
    set "currentVar=!%%v!"
    IF NOT EXIST "!currentVar!" (
        echo !currentVar! not found at !currentVar!
        set "errorFlag=1"
    ) ELSE (
        echo !currentVar! exists at !currentVar!
    )
)

if !errorFlag! equ 1 (
    echo Error: At least one required file or directory not found.
    exit /b 1
)

::call protoc.exe
for /l %%i in (1,1,%count%) do (
    "%PROTOC_EXE_PATH%" ^
     --proto_path="%PROTOBUF_INC_PATH%" --proto_path="%INPUT_PROTO_PATH%" ^
     --cpp_out="%CPP_OUTPUT_PATH%" ^
     --plugin=protoc-gen-grpc="%GRPC_CPP_PLUGIN_EXE_PATH%" --grpc_out=%CPP_OUTPUT_PATH% ^
     --plugin=protoc-gen-turbolink="%TURBOLINK_PLUGIN_PATH%" --turbolink_out="%OUTPUT_PATH%" ^
     --turbolink_opt="GenerateJsonCode=true" ^
     "!INPUT_PROTO_FILES_ARRAY[%%i]!"
)


for /l %%i in (1,1,%count%) do (
    set PROTO_FILE=!INPUT_PROTO_FILES_ARRAY[%%i]!
    set RELATIVE_PROTO_FILE=!PROTO_FILE:%INPUT_PROTO_PATH%\=!
    :: fix protobuf compile warning 
    call :FixCompileWarning "%FIX_PROTO_H%" %CPP_OUTPUT_PATH%\!RELATIVE_PROTO_FILE! "pb.h"
    call :FixCompileWarning "%FIX_PROTO_CPP%" %CPP_OUTPUT_PATH%\!RELATIVE_PROTO_FILE! "pb.cc"
)
goto :eof

:FixCompileWarning
set FIX_FILE=%1
set FILE_PATH=%~p2
set FILE_NAME=%~n2.%~3

pushd %FILE_PATH%
copy /b %FIX_FILE%+%FILE_NAME% %FILE_NAME%.tmp
del /f %FILE_NAME%
rename %FILE_NAME%.tmp %FILE_NAME%
popd 

goto :eof

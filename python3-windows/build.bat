echo off

cd python3-windows

if "%ARCH%"=="win32" goto :buildarch
if "%ARCH%"=="amd64" goto :buildarch
goto :unsupported_arch

:unsupported_arch
echo Unsupported platform
::pause
goto:eof

:buildarch
echo Building Python for %ARCH%
if not exist %ARCH% mkdir "%ARCH%"
cd "%ARCH%"

:: Download the Python embeddable
curl -vLO https://www.python.org/ftp/python/%PYVER%/python-%PYVER%-embed-%ARCH%.zip
7z x python-%PYVER%-embed-%ARCH%.zip -o* -y
del python-%PYVER%-embed-%ARCH%.zip

:: Enable site packages
cd python-%PYVER%-embed-%ARCH%\
for /r %%x in (*._pth) do (call :FindReplace "#import site" "import site" %%x)
cd ..

:: Copy and run the get-pip script to the embeddable folder
xcopy ..\get-pip.py python-%PYVER%-embed-%ARCH%\ /Y
python python-%PYVER%-embed-%ARCH%\get-pip.py

:: Create the final embeddable dir and moves Python distribution into it
if exist "embeddable\" rmdir /S /Q "embeddable\"
move /Y python-%PYVER%-embed-%ARCH% embeddable

goto:eof

:FindReplace <findstr> <replstr> <file>
set tmp="%temp%\tmp.txt"
If not exist %temp%\_.vbs call :MakeReplace
for /f "tokens=*" %%a in ('dir "%3" /s /b /a-d /on') do (
  for /f "usebackq" %%b in (`Findstr /mic:"%~1" "%%a"`) do (
    echo(&Echo Replacing "%~1" with "%~2" in file %%~nxa
    <%%a cscript //nologo %temp%\_.vbs "%~1" "%~2">%tmp%
    if exist %tmp% move /Y %tmp% "%%~dpnxa">nul
  )
)
del %temp%\_.vbs
exit /b

:MakeReplace
>%temp%\_.vbs echo with Wscript
>>%temp%\_.vbs echo set args=.arguments
>>%temp%\_.vbs echo .StdOut.Write _
>>%temp%\_.vbs echo Replace(.StdIn.ReadAll,args(0),args(1),1,-1,1)
>>%temp%\_.vbs echo end with
    @echo off  
      
    :: BatchGotAdmin  
    :-------------------------------------  
    REM  --> Check for permissions  
    >nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"  
      
    REM --> If error flag set, we do not have admin.  
    if '%errorlevel%' NEQ '0' (  
        echo Requesting administrative privileges...  
        goto UACPrompt  
    ) else ( goto gotAdmin )  
      
    :UACPrompt  
        echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"  
        echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"  
      
        "%temp%\getadmin.vbs"  
        exit /B  
      
    :gotAdmin  
        if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )  
        pushd "%CD%"  
        CD /D "%~dp0"  
    :--------------------------------------  
net stop Cms.SanityCheck.Service
net stop Cms.SanityCheck.Service
%WinDir%\Microsoft.NET\Framework64\v4.0.30319\InstallUtil.exe /u CmsSanityCheck.exe
cls
%WinDir%\Microsoft.NET\Framework64\v4.0.30319\InstallUtil.exe CmsSanityCheck.exe
net start Cms.SanityCheck.Service



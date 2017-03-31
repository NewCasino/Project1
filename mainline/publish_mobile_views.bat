@echo off

set sourcePath=D:\work\svn\cms2012\GamMatrix.CMS
set deployPath=D:\temp\mobile360\deploy\build



echo "----------------------------------------"
echo "------------- Adding Views -------------"
echo "----------------------------------------"


call:deployShared

call:deployOperator Alea365Mobile
call:deployOperator ArtemisBetMobile
call:deployOperator CapitolBetMobile
call:deployOperator ContorabetMobile
call:deployOperator ExclusiveBetMobile2
call:deployOperator GutsMobile
call:deployOperator JetbullM
call:deployOperator MobiBetMobile
call:deployOperator NextCasinoMobile
call:deployOperator NorskespillMobile
call:deployOperator OneLuckyMobile
call:deployOperator ParasinoMobile
call:deployOperator PlayAdjaraMobile
call:deployOperator PlayHippoMobile
call:deployOperator SuperLennyMobile
call:deployOperator TeambetMobile
call:deployOperator ThrillsMobile

call:buildCleanup

::pause
goto:eof

:deployShared
	mkdir  %deployPath%\Views\MobileShared\
	xcopy %sourcePath%\Views\MobileShared\*  %deployPath%\Views\MobileShared\* /S /F /Y
	del /F  %deployPath%\Views\MobileShared\Metadata\Settings\.Casino_NetEntGameLoadBaseUrl
	del /F  %deployPath%\Views\MobileShared\Metadata\Settings\.Casino_NetEntGamePlayBaseUrl
	del /Q /S /F  %deployPath%\Views\MobileShared\Metadata\Casino\Games\NetEnt\*
	rmdir /Q /S  %deployPath%\Views\MobileShared\Metadata\Casino\Games\NetEnt\
	del /Q /S /F  %deployPath%\Views\MobileShared\Metadata\_CasinoEngine\*
	rmdir /Q /S %deployPath%\Views\MobileShared\Metadata\_CasinoEngine\
	del /Q /S /F %deployPath%\Views\MobileShared\.config\*
	rmdir /Q /S %deployPath%\Views\MobileShared\.config
goto:eof

:deployOperator
	SETLOCAL

	set sourceDir=%~1
	set deployDir=%~2
	if [%deployDir%]==[] set deployDir=%~1

	echo "---------- Deployment of %sourceDir% started  ---------"
	mkdir  %deployPath%\Views\%deployDir%\
	xcopy %sourcePath%\Views\%sourceDir%\*  %deployPath%\Views\%deployDir%\* /S /F /Y
	rmdir /Q /S %deployPath%\Views\%deployDir%\.config
	rmdir /Q /S %deployPath%\Views\%deployDir%\Metadata\Settings
	echo "---------- Deployment of %sourceDir% completed  ---------"

	ENDLOCAL
goto:eof

:buildCleanup
	del /Q /S /F %deployPath%\*.psd
	::del /Q /S /F %deployPath%\.svn
	::rmdir /Q /S %deployPath%\.svn
goto:eof
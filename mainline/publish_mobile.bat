set sourcePath=D:\work\svn\cms2012\GamMatrix.CMS
set deployPath=D:\temp\mobile360\deploy\build



echo "----------------------------------------"
echo "------------- Adding Code --------------"
echo "----------------------------------------"


::mkdir  %deployPath%\App_Code\
::xcopy %sourcePath%\App_Code\*  %deployPath%\App_Code\* /S /Y

mkdir  %deployPath%\App_Data\
copy /Y /B %sourcePath%\App_Data\classicpage_view_source  %deployPath%\App_Data\classicpage_view_source
copy /Y /B %sourcePath%\App_Data\http_handler_source  %deployPath%\App_Data\http_handler_source
copy /Y /B %sourcePath%\App_Data\metadata_source  %deployPath%\App_Data\metadata_source
copy /Y /B %sourcePath%\App_Data\page_source  %deployPath%\App_Data\page_source
copy /Y /B %sourcePath%\App_Data\page_template_source  %deployPath%\App_Data\page_template_source
copy /Y /B %sourcePath%\App_Data\partial_view_source  %deployPath%\App_Data\partial_view_source
copy /Y /B %sourcePath%\App_Data\view_source  %deployPath%\App_Data\view_source

mkdir  %deployPath%\App_WebReferences\
xcopy %sourcePath%\App_WebReferences\*  %deployPath%\App_WebReferences\* /S /Y

mkdir  %deployPath%\images\
xcopy %sourcePath%\images\*  %deployPath%\images\* /S /Y

mkdir  %deployPath%\js\
xcopy %sourcePath%\js\*  %deployPath%\js\* /S /Y


del /Q /S /F %deployPath%\.svn
del /Q /S /F %deployPath%\*.psd
rmdir /Q /S %deployPath%\.svn

mkdir  %deployPath%\Bin\
copy /Y /B %sourcePath%\Bin\BLToolkit.4.dll  %deployPath%\Bin\BLToolkit.4.dll
copy /Y /B %sourcePath%\Bin\CM.dll  %deployPath%\Bin\CM.dll
copy /Y /B %sourcePath%\Bin\GamMatrix.Components.dll  %deployPath%\Bin\GamMatrix.Components.dll
copy /Y /B %sourcePath%\Bin\GamMatrix.Infrastructure.dll  %deployPath%\Bin\GamMatrix.Infrastructure.dll
copy /Y /B %sourcePath%\Bin\GamMatrix.CMS.dll  %deployPath%\Bin\GamMatrix.CMS.dll

copy /Y /B %sourcePath%\Bin\CM.pdb  %deployPath%\Bin\CM.pdb
copy /Y /B %sourcePath%\Bin\GamMatrix.Components.pdb  %deployPath%\Bin\GamMatrix.Components.pdb
copy /Y /B %sourcePath%\Bin\GamMatrix.Infrastructure.pdb  %deployPath%\Bin\GamMatrix.Infrastructure.pdb
copy /Y /B %sourcePath%\Bin\GamMatrix.CMS.pdb  %deployPath%\Bin\GamMatrix.CMS.pdb

copy /Y /B %sourcePath%\Global.asax  %deployPath%\Global.asax
copy /Y /B %sourcePath%\7zip.exe  %deployPath%\7zip.exe
copy /Y /B %sourcePath%\crossdomain.xml  %deployPath%\crossdomain.xml


call publish_mobile_views.bat

echo "----------deploy complete ---------"



del /Q /S /F %deployPath%\.svn
del /Q /S /F %deployPath%\*.psd
rmdir /Q /S %deployPath%\.svn
del G:\����\* /F /S /Q 
rmdir G:\���� /S /Q 
mkdir G:\����\

xcopy G:\CMS\Cms\CmsWeb\*.ttf  G:\����\*.ttf /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.eot  G:\����\*.eot /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.cs  G:\����\*.cs /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.aspx  G:\����\*.aspx /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.ascx  G:\����\*.ascx /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.asmx  G:\����\*.asmx /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.ashx  G:\����\*.ashx /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.master  G:\����\*.master /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.resx  G:\����\*.resx /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.js  G:\����\*.js /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.css  G:\����\*.css /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.jpg  G:\����\*.jpg /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.jpeg  G:\����\*.jpeg /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.swf  G:\����\*.swf /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.gif  G:\����\*.gif /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.png  G:\����\*.png /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.png  G:\����\*.png /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.xsd  G:\����\*.xsd /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.skin  G:\����\*.skin /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.xslt  G:\����\*.xslt /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.xsl  G:\����\*.xsl /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.svcinfo  G:\����\*.svcinfo /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.svcmap  G:\����\*.svcmap /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.wsdl  G:\����\*.wsdl /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.discomap  G:\����\*.discomap /S /F /Y

mkdir  G:\����\Bin\
copy /Y /B G:\CMS\Cms\CmsWeb\Bin\Longrun.CM.dll  G:\����\Bin\Longrun.CM.dll
copy /Y /B G:\CMS\Cms\CmsWeb\Bin\Longrun.CM.pdb  G:\����\Bin\Longrun.CM.pdb
copy /Y /B G:\CMS\Cms\CmsWeb\Bin\Longrun.Lib.dll  G:\����\Bin\Longrun.Lib.dll
copy /Y /B G:\CMS\Cms\CmsWeb\Bin\Longrun.Lib.pdb  G:\����\Bin\Longrun.Lib.pdb
copy /Y /B G:\CMS\Cms\CmsWeb\Bin\Longrun.Web.UI.dll  G:\����\Bin\Longrun.Web.UI.dll
copy /Y /B G:\CMS\Cms\CmsWeb\Bin\Longrun.Web.UI.pdb  G:\����\Bin\Longrun.Web.UI.pdb

copy /Y /B G:\CMS\Cms\CmsWeb\Bin\EcmaScript.NET.modified.dll  G:\����\Bin\EcmaScript.NET.modified.dll
copy /Y /B G:\CMS\Cms\CmsWeb\Bin\Yahoo.Yui.Compressor.dll  G:\����\Bin\Yahoo.Yui.Compressor.dll

rmdir G:\����\op /S /Q 
rmdir G:\����\CuteSoft_Client /S /Q 
rmdir G:\����\aspnet_client /S /Q 
rmdir G:\����\App_Data /S /Q 
rmdir G:\����\temp /S /Q 
rmdir G:\����\StaticFiles /S /Q 
rmdir G:\����\opCommon\img\NetEnt /S /Q 
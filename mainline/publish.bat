del G:\发布\* /F /S /Q 
rmdir G:\发布 /S /Q 
mkdir G:\发布\

xcopy G:\CMS\Cms\CmsWeb\*.ttf  G:\发布\*.ttf /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.eot  G:\发布\*.eot /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.cs  G:\发布\*.cs /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.aspx  G:\发布\*.aspx /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.ascx  G:\发布\*.ascx /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.asmx  G:\发布\*.asmx /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.ashx  G:\发布\*.ashx /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.master  G:\发布\*.master /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.resx  G:\发布\*.resx /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.js  G:\发布\*.js /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.css  G:\发布\*.css /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.jpg  G:\发布\*.jpg /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.jpeg  G:\发布\*.jpeg /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.swf  G:\发布\*.swf /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.gif  G:\发布\*.gif /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.png  G:\发布\*.png /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.png  G:\发布\*.png /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.xsd  G:\发布\*.xsd /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.skin  G:\发布\*.skin /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.xslt  G:\发布\*.xslt /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.xsl  G:\发布\*.xsl /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.svcinfo  G:\发布\*.svcinfo /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.svcmap  G:\发布\*.svcmap /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.wsdl  G:\发布\*.wsdl /S /F /Y
xcopy G:\CMS\Cms\CmsWeb\*.discomap  G:\发布\*.discomap /S /F /Y

mkdir  G:\发布\Bin\
copy /Y /B G:\CMS\Cms\CmsWeb\Bin\Longrun.CM.dll  G:\发布\Bin\Longrun.CM.dll
copy /Y /B G:\CMS\Cms\CmsWeb\Bin\Longrun.CM.pdb  G:\发布\Bin\Longrun.CM.pdb
copy /Y /B G:\CMS\Cms\CmsWeb\Bin\Longrun.Lib.dll  G:\发布\Bin\Longrun.Lib.dll
copy /Y /B G:\CMS\Cms\CmsWeb\Bin\Longrun.Lib.pdb  G:\发布\Bin\Longrun.Lib.pdb
copy /Y /B G:\CMS\Cms\CmsWeb\Bin\Longrun.Web.UI.dll  G:\发布\Bin\Longrun.Web.UI.dll
copy /Y /B G:\CMS\Cms\CmsWeb\Bin\Longrun.Web.UI.pdb  G:\发布\Bin\Longrun.Web.UI.pdb

copy /Y /B G:\CMS\Cms\CmsWeb\Bin\EcmaScript.NET.modified.dll  G:\发布\Bin\EcmaScript.NET.modified.dll
copy /Y /B G:\CMS\Cms\CmsWeb\Bin\Yahoo.Yui.Compressor.dll  G:\发布\Bin\Yahoo.Yui.Compressor.dll

rmdir G:\发布\op /S /Q 
rmdir G:\发布\CuteSoft_Client /S /Q 
rmdir G:\发布\aspnet_client /S /Q 
rmdir G:\发布\App_Data /S /Q 
rmdir G:\发布\temp /S /Q 
rmdir G:\发布\StaticFiles /S /Q 
rmdir G:\发布\opCommon\img\NetEnt /S /Q 
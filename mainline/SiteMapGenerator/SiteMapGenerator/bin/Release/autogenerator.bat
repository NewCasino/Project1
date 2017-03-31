@echo off
set b=%~dp0
@echo start to add schedule task...
@echo schtasks /create /tn "AutoGenerateSitemap" /tr %b%SiteMapGenerator.exe /sc daily /st 00:00:00
schtasks /create /tn "AutoGenerateSitemap" /tr %b%SiteMapGenerator.exe /sc hourly /mo 3

@echo add schedule task successfully
pause
@echo on
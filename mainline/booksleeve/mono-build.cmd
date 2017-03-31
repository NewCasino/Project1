:: illustration command-line script for building at the command-line in mono; this script assumes that
:: the path search list includes the mono build tools, specifically mcs

@rd /s /q Mono 2>NUL
@md Mono
@copy license.txt Mono > NUL
@echo Building to %CD%\Mono
@mcs -recurse:BookSleeve\*.cs -sdk:4 -target:library -doc:Mono\BookSleeve.xml -optimize+ -out:Mono\BookSleeve.dll -platform:anycpu -debug

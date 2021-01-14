@echo off

mkdir .\build\DeathGift\addons\amxmodx\scripting\

copy .\DeathGift-Icon.png .\build\
copy .\README.md .\build\
xcopy .\amxmodx .\build\DeathGift\addons\amxmodx /s /e
xcopy .\resources\* .\build\DeathGift\ /s /e

copy .\DeathGift.sma .\build\DeathGift\addons\amxmodx\scripting\
copy .\DG_MoreBonuses.sma .\build\DeathGift\addons\amxmodx\scripting\
copy .\DG_MoreFuncs.sma .\build\DeathGift\addons\amxmodx\scripting\
xcopy .\include\*.inc .\build\DeathGift\addons\amxmodx\scripting\include\ /s /e /y /q

del .\DeathGift.zip
cd .\build
zip -r .\..\DeathGift.zip .
cd ..
rmdir .\build /s /q

echo .
echo .
echo .
set /p q=Done.
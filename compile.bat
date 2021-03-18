@echo off

echo /============ PREPARE =============
echo /

xcopy .\include C:\AmxModX\1.9.0\include /s /e /y

rd /S /q .\plugins
mkdir .\plugins
cd .\plugins

echo /
echo /
echo /============ COMPILE =============
echo /

for /R ..\ %%F in (*.sma) do amxx190 %%F

echo /
echo /
echo /============ END =============
echo /

set /p q=Done.
@echo off

copy .\include\DeathGift.inc C:\AmxModX\1.9.0\include\

del .\plugins /q
mkdir .\plugins

amxx190 .\DeathGift.sma
move .\DeathGift.amxx .\plugins\
amxx190 .\DG_MoreBonuses.sma
move .\DG_MoreBonuses.amxx .\plugins\
amxx190 .\DG_MoreFuncs.sma
move .\DG_MoreFuncs.amxx .\plugins\

echo .
echo .
echo .
set /p q=Done...
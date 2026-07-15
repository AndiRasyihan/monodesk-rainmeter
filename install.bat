@echo off
setlocal
REM ===== MonoDesk installer: salin skin ke Rainmeter lalu aktifkan =====

set "SRC=%~dp0MonoDesk"
set "DST=%USERPROFILE%\Documents\Rainmeter\Skins\MonoDesk"
set "RM=C:\Program Files\Rainmeter\Rainmeter.exe"

echo Menyalin tema MonoDesk ke %DST% ...
xcopy "%SRC%" "%DST%\" /E /I /Y >nul
if errorlevel 1 (
  echo GAGAL menyalin file skin.
  exit /b 1
)

if not exist "%RM%" (
  echo Rainmeter.exe tidak ditemukan di "%RM%".
  echo Skin sudah tersalin - aktifkan manual lewat Rainmeter Manage.
  exit /b 1
)

echo Merefresh Rainmeter dan mengaktifkan skin...
"%RM%" [!RefreshApp]
timeout /t 1 /nobreak >nul
"%RM%" [!ActivateConfig "MonoDesk\Clock" "Clock.ini"][!Move 1400 100 "MonoDesk\Clock"]
"%RM%" [!ActivateConfig "MonoDesk\Stats" "Stats.ini"][!Move 1480 430 "MonoDesk\Stats"]
"%RM%" [!ActivateConfig "MonoDesk\Launcher" "Launcher.ini"][!Move 1520 740 "MonoDesk\Launcher"]
"%RM%" [!ActivateConfig "MonoDesk\TodoList" "TodoList.ini"][!Move 1180 740 "MonoDesk\TodoList"]
"%RM%" [!ActivateConfig "MonoDesk\Photo" "Photo.ini"][!Move 1180 430 "MonoDesk\Photo"]
"%RM%" [!ActivateConfig "MonoDesk\Music" "Music.ini"][!Move 840 740 "MonoDesk\Music"]

echo.
echo Selesai! Tema MonoDesk aktif di desktop.
echo Atur posisi dengan drag, zoom dengan scroll mouse di atas widget.
endlocal

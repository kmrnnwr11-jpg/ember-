@echo off
rem Avvia Ember: il motore (Runner), la pagina dell'app, e la apre nel browser.
rem Doppio clic su questo file. Per spegnere Ember chiudi le due finestre nere.
cd /d "%~dp0"
rem Il motore vuole Node 22: su questo PC e' in tools, accanto a Flutter.
for /d %%D in ("%USERPROFILE%\tools\node-v22*") do set "PATH=%%D;%PATH%"
rem Flutter e Java stanno nella stessa cartella: servono al motore per costruire le app (anche Android).
if exist "%USERPROFILE%\tools\flutter\bin\flutter.bat" set "PATH=%USERPROFILE%\tools\flutter\bin;%PATH%"
if exist "%USERPROFILE%\tools\jdk-17\bin\java.exe" set "JAVA_HOME=%USERPROFILE%\tools\jdk-17"
if not exist "apps\ide\build\web\index.html" (
  echo La pagina dell'app non e' ancora stata preparata: la preparo ora, ci vogliono un paio di minuti...
  pushd apps\ide
  call "%USERPROFILE%\tools\flutter\bin\flutter.bat" build web --release
  popd
)
start "Ember - motore" /min cmd /c "cd /d apps\runner && npx tsx --env-file-if-exists=../../.env src/index.ts"
start "Ember - pagina" /min cmd /c "node tools\serve_web.mjs"
timeout /t 10 /nobreak >nul
start "" "http://localhost:8899/"

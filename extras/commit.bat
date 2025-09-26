@echo off
cd /d A:\Desarrollos\Natura

echo Reading commit message from VERSION file...

for /f "usebackq delims=" %%i in (`powershell -Command "& {$content = Get-Content 'extras\VERSION' -Raw; if($content -match '\[\[data\]\]\s*([^\[]+)') { $matches[1].Trim() } else { 'Update' }}"`) do set COMMIT_MSG=%%i

echo Commit message: %COMMIT_MSG%

echo Adding files...
git add .

echo Committing...
git commit -m "%COMMIT_MSG%"

echo Pushing...
git push

echo Done!
pause
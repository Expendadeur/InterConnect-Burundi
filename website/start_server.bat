@echo off
echo Demarrage du serveur web InterConnect Burundi sur http://localhost:5000 ...
cd /d %~dp0
python -m http.server 5000
pause

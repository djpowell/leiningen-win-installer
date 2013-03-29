del /q Output\*
call "%ProgramFiles(x86)%\Inno Setup 5\iscc.exe" /dconfigure leiningen-installer.iss
call "%ProgramFiles(x86)%\Inno Setup 5\iscc.exe" leiningen-installer.iss

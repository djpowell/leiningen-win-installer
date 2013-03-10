; InnoSetup 5.5.3 Installer definition for Leiningen - (c) David Powell 2013

#define MyAppName "Leiningen"
#define MyAppVersion "2.0-installer_alpha_1"
#define MyAppPublisher "djpowell"
#define MyAppURL "https://bitbucket.org/djpowell/leiningen-win-installer"
             
; Set the following lines to the location of the latest JDK and corresponding JRE to embed in the installer
#define JDK_Source "C:\Program Files (x86)\Java\jdk1.7.0_17"
#define JRE_Source "C:\Program Files (x86)\Java\jre7"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{450F3BB7-7198-4401-A147-BDA0BECF6A3A}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={userpf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
LicenseFile=license.txt
OutputBaseFilename=leiningen-installer
Compression=lzma
SolidCompression=yes
ChangesEnvironment=yes
ChangesAssociations=yes
PrivilegesRequired=lowest

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "lein.bat"; DestDir: "{app}"
Source: "curl.exe"; DestDir: "{app}"
Source: "license.txt"; DestDir: "{app}\license.txt"
Source: "profiles.clj"; DestDir: "{%LEIN_HOME|{%USERPROFILE}\.lein}"; Flags: onlyifdoesntexist
Source: "{#JRE_Source}\*"; DestDir: "{app}\java"; Flags: recursesubdirs createallsubdirs
Source: "{#JDK_Source}\bin\javac.exe"; DestDir: "{app}\java\bin\"
Source: "{#JDK_Source}\lib\tools.jar"; DestDir: "{app}\java\lib\"
Source: "{#JDK_Source}\bin\apt.exe"; DestDir: "{app}\java\bin\"
Source: "{#JDK_Source}\lib\jconsole.jar"; DestDir: "{app}\java\lib\"

[Icons]                                             
Name: "{group}\Clojure REPL"; Filename: "{app}\lein.bat"; WorkingDir: "{userdocs}"; Parameters: "repl"
Name: "{group}\Edit profiles.clj"; Filename: "{%LEIN_HOME|{%USERPROFILE}\.lein}\profiles.clj"

[Run]
Filename: "{app}\lein.bat"; WorkingDir: "{userdocs}"; Parameters: "self-install"; StatusMsg: "Running 'lein self-install'"; Flags: runasoriginaluser
Filename: "{app}\lein.bat"; WorkingDir: "{userdocs}"; Parameters: "repl"; Description: "Run a Clojure REPL"; Flags: postinstall nowait skipifsilent

[Code]

function AppendToPath(OldPath, NewPath: String): String;
var
  Path: String;
begin
  Path := OldPath;
  if Pos(NewPath, Path) = 0 then
  begin
    if Length(Path) > 0 then
    begin
      Path := Path + ';';
    end
    Path := Path + NewPath;
  end
  Result := Path;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var                     
  AppPath: String;
  JavaPath: String;
  Path: String;
begin
  if CurStep = ssPostInstall then
  begin
    if not RegQueryStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', Path) then
    begin
      Path := '';
    end

    AppPath := ExpandConstant('{app}');
    Path := AppendToPath(Path, AppPath);
    RegWriteStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', Path);

    JavaPath := AddQuotes(AddBackslash(AppPath) + 'java\bin\java.exe');
    RegWriteStringValue(HKEY_CURRENT_USER, 'Environment', 'LEIN_JAVA_CMD', JavaPath);

  end
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  AppPath: String;
  Path: String;
begin
  if CurUninstallStep = usPostUninstall then
  begin
    if RegQueryStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', Path) then
    begin
      AppPath := ExpandConstant('{app}');
      if Pos(AppPath, Path) = 0 then
      begin
        StringChangeEx(Path, AppPath, '', True);
      end

      StringChangeEx(Path, ';;', ';', True);
      RegWriteStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', Path);
    end

    RegDeleteValue(HKEY_CURRENT_USER, 'Environment', 'LEIN_JAVA_CMD');
  end
end;




; InnoSetup 5.5.3 Installer definition for Leiningen - (c) David Powell 2013

#define MyAppName "Leiningen"
#define MyAppVersion "installer_alpha_2"
#define MyAppPublisher "djpowell"
#define MyAppURL "https://bitbucket.org/djpowell/leiningen-win-installer"
             
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
PrivilegesRequired=lowest
SetupLogging=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "curl.exe"; DestDir: "{app}"
Source: "curl-ca-bundle.crt"; DestDir: "{app}"
Source: "license.txt"; DestDir: "{app}"
Source: "licenses\*"; DestDir: "{app}\licenses"
Source: "profiles.clj"; DestDir: "{%LEIN_HOME|{%USERPROFILE}\.lein}"; Flags: onlyifdoesntexist

[Icons]                                             
Name: "{group}\Clojure REPL"; Filename: "{app}\lein.bat"; WorkingDir: "{userdocs}"; Parameters: "repl"
Name: "{group}\Edit profiles.clj"; Filename: "{%LEIN_HOME|{%USERPROFILE}\.lein}\profiles.clj"

[Run]
Filename: "{app}\curl.exe"; WorkingDir: "{app}"; Parameters: """https://raw.github.com/technomancy/leiningen/stable/bin/lein.bat"" -o lein.bat"; StatusMsg: "Downloading 'lein.bat'"; Flags: runasoriginaluser runminimized
Filename: "{app}\lein.bat"; WorkingDir: "{app}"; Parameters: "self-install"; StatusMsg: "Running 'lein self-install'"; Flags: runasoriginaluser runminimized
Filename: "{app}\lein.bat"; WorkingDir: "{userdocs}"; Parameters: "repl"; Description: "Run a Clojure REPL"; Flags: postinstall nowait skipifsilent 

[UninstallDelete]
Type: files; Name: "{app}\lein.bat"
Type: filesandordirs; Name: "{%LEIN_HOME|{%USERPROFILE}\.lein}\self-installs"
Type: filesandordirs; Name: "{%LEIN_HOME|{%USERPROFILE}\.lein}\indices"

[Code]

var      
  JdkCount : Integer;
  JdkVersions : TArrayOfString;   
  Jdk64s : TArrayOfBoolean;
  JdkPaths : TArrayOfString;        
  JdkIndexes : TArrayOfInteger;
  JdkPage : TInputOptionWizardPage;
  CustomJdkPage : TInputDirWizardPage;  
  SelectedJdkIndex : Integer;
  SelectedJdkPath : String;

procedure PopulateJdks();
var
  JavaVersions : TArrayOfString;
  JavaPath : String;
  I, J, JI : Integer;
  JavaCount : Integer;
begin
  JavaCount := 0;                                         
  if RegGetSubkeyNames(HKEY_LOCAL_MACHINE_64, 'SOFTWARE\JavaSoft\Java Development Kit', JavaVersions) then
  begin
    JavaCount := JavaCount + GetArrayLength(JavaVersions);
  end
  if RegGetSubkeyNames(HKEY_LOCAL_MACHINE, 'SOFTWARE\JavaSoft\Java Development Kit', JavaVersions) then
  begin
    JavaCount := JavaCount + GetArrayLength(JavaVersions);
  end

  SetArrayLength(JdkVersions, JavaCount);
  SetArrayLength(Jdk64s, JavaCount);   
  SetArrayLength(JdkPaths, JavaCount);
  SetArrayLength(JdkIndexes, JavaCount);
            
  JI := 0;

  if RegGetSubkeyNames(HKEY_LOCAL_MACHINE_64, 'SOFTWARE\JavaSoft\Java Development Kit', JavaVersions) then
  begin
    for I := 0 to GetArrayLength(JavaVersions)-1 do
    begin
      RegQueryStringValue(HKEY_LOCAL_MACHINE_64, 'SOFTWARE\JavaSoft\Java Development Kit\' + JavaVersions[I], 'JavaHome', JavaPath);
      JdkVersions[JI] := JavaVersions[I];
      Jdk64s[JI] := True;
      JdkPaths[JI] := JavaPath;
      JI := JI + 1;
    end
  end

  if RegGetSubkeyNames(HKEY_LOCAL_MACHINE, 'SOFTWARE\JavaSoft\Java Development Kit', JavaVersions) then
  begin
    for I := 0 to GetArrayLength(JavaVersions)-1 do
    begin
      RegQueryStringValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\JavaSoft\Java Development Kit\' + JavaVersions[I], 'JavaHome', JavaPath);
      JdkVersions[JI] := JavaVersions[I];
      Jdk64s[JI] := False;
      JdkPaths[JI] := JavaPath;
      JI := JI + 1;
    end
  end

  // filter out broken installs
  for I := 0 to GetArrayLength(JdkVersions) - 1 do
  begin
    if not FileExists(AddBackslash(JdkPaths[I]) + 'bin\javac.exe') then
    begin
      JdkVersions[I] := '';
    end
  end

  // filter out duplicates
  for I := 0 to GetArrayLength(JdkVersions) - 1 do
  begin
    for J := 0 to GetArrayLength(JdkVersions) - 1 do
    begin
      if ((I <> J) and (JdkPaths[I] = JdkPaths[J]) and (JdkVersions[I] <> '') and (JdkVersions[J] <> '')) then
      begin
        if Length(JdkVersions[I]) < Length(JdkVersions[J]) then
        begin
          JdkVersions[I] := '';
        end
        else
        begin
          JdkVersions[J] := '';
        end
      end
    end
  end

  JdkCount := 0;
  for I := 0 to GetArrayLength(JdkVersions) - 1 do
  begin                    
    if JdkVersions[I] <> '' then
    begin
        JdkCount := JdkCount + 1;
    end
  end

end;

function InitializeSetup(): Boolean;
var
  Button : Integer;
begin            
  PopulateJdks();

  if JdkCount > 0 then
  begin
    Result := True;
  end
  else
  begin
    Button := MsgBox('An installed Java Development Kit could not been found automatically.' + Chr(13) + Chr(10) + Chr(13) + Chr(10) + 'Ensure that you have downloaded and installed a JDK from:' + Chr(13) + Chr(10) + 'http://www.oracle.com/technetwork/java/javase/overview/index.html' + Chr(13) + Chr(10) + Chr(13) + Chr(10) + 'Continue the installation?', mbError, MB_YESNO or MB_DEFBUTTON2);
    Result := (Button = IDYES);
  end 

end;

procedure InitializeWizard();
var      
  I, JI : Integer;
  Description : String;
begin
  JdkPage := CreateInputOptionPage(wpSelectDir, 'Select JDK', '', 'Select the path to a Java Development Kit for Leiningen to use:', True, True);

  JI := 0;
  for I := 0 to GetArrayLength(JdkVersions)-1 do
  begin
    if (JdkVersions[I] <> '') then
    begin
      JdkIndexes[JI] := I;
      JI := JI + 1;
      if Jdk64s[I] then
      begin
        Description := '64-bit';
      end
      else
      begin
        Description := '32-bit';
      end

      Description := Description + ' JDK ' + JdkVersions[I];
      
      Description := Description + '    ( ' + JdkPaths[I] + ' )';

      JdkPage.Add(Description);      
    end
  end

  JdkPage.Add('Custom location...');

  CustomJdkPage := CreateInputDirPage(JdkPage.ID, 'Custom JDK Location', '', 'Specify the location of an installed JDK:', False, '');
  CustomJdkPage.Add('');
end;

function SelectedJdkLocation() : String;
begin
  if JdkPage.SelectedValueIndex = (JdkPage.CheckListBox.Items.Count - 1) then
  begin
    SelectedJdkPath := AddBackslash(CustomJdkPage.Values[0]) + 'bin\java.exe';
  end
  else
  begin
    SelectedJdkPath := AddBackslash(JdkPaths[SelectedJdkIndex]) + 'bin\java.exe';
  end
  Result := SelectedJdkPath;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  // TODO
  if CurPageId = CustomJdkPage.ID then
  begin
    if FileExists(AddBackslash(CustomJdkPage.Values[0]) + 'bin\javac.exe') then
    begin
      Result := True;
    end
    else
    begin
      MsgBox('The specified location does not appear to contain a JDK', mbError, MB_OK);
      Result := False;
    end
  end  
  else if CurPageId = JdkPage.ID then
  begin
    if JdkPage.SelectedValueIndex = -1 then
    begin
      Result := False;
    end
    else
    begin
      SelectedJdkIndex := JdkIndexes[JdkPage.SelectedValueIndex];
      Result := True;
    end
  end
  else
  begin                    
    Result := True;
  end
end;
  
function ShouldSkipPage(PageID: Integer): Boolean;
begin
  if (PageID = CustomJdkPage.ID) and (JdkPage.SelectedValueIndex <> (JdkPage.CheckListBox.Items.Count - 1)) then
  begin
    Result := True;
  end
  else
  begin
    Result := False;
  end
end;

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
  if CurStep = ssInstall then
  begin
    SelectedJdkLocation();
  end
  else if CurStep = ssPostInstall then
  begin
    if not RegQueryStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', Path) then
    begin
      Path := '';
    end
    Log('Original PATH: ' + Path);

    AppPath := ExpandConstant('{app}');
    Log('App Path: ' + AppPath);

    Path := AppendToPath(Path, AppPath);
    Log('Updated PATH: ' + Path);
    RegWriteStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', Path);
    Log('PATH changed');

    JavaPath := AddQuotes(SelectedJdkPath);
    Log('Java Path: ' + JavaPath);
    RegWriteStringValue(HKEY_CURRENT_USER, 'Environment', 'LEIN_JAVA_CMD', JavaPath);
    Log('Set LEIN_JAVA_CMD: ' + JavaPath);
  end
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  AppPath: String;
  Path: String;
begin
  if CurUninstallStep = usUninstall then
  begin
    if RegQueryStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', Path) then
    begin
      Log('Original PATH: ' + Path);
      AppPath := ExpandConstant('{app}');
      Log('App Path: ' + AppPath);
      if Pos(AppPath, Path) <> 0 then
      begin
        StringChangeEx(Path, ';' + AppPath, '', True);
        StringChangeEx(Path, AppPath + ';', '', True);
        StringChangeEx(Path, AppPath, '', True);
      end

      Log('Updated PATH: ' + Path);
      RegWriteStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', Path);
      Log('PATH changed');
    end

    RegDeleteValue(HKEY_CURRENT_USER, 'Environment', 'LEIN_JAVA_CMD');
    Log('Removed LEIN_JAVA_CMD');
  end
end;

// TODO sort the jdk list sensibly

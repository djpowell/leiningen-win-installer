; InnoSetup 5.5.4 Installer definition for Leiningen - (c) David Powell 2013

#define MyAppName "Leiningen"
#define MyAppVersion "1.0"
#define MyAppPublisher "David Powell"
#define MyAppURL "http://leiningen-win-installer.djpowell.net/"
#define MyInstallerBaseName "leiningen-installer"
             
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
#ifndef configure
AppModifyPath="{app}\bin\configure-{#MyInstallerBaseName}.exe"
UninstallFilesDir={app}\bin
OutputBaseFilename={#MyInstallerBaseName}-{#MyAppVersion}
; add some extra space for the bat and jar files
ExtraDiskSpaceRequired=15000000
#endif
#ifdef configure
DisableDirPage=yes
OutputBaseFilename=configure-{#MyInstallerBaseName}
Uninstallable=no
UpdateUninstallLogAppName=no
#endif
DefaultDirName={%LEIN_HOME|{%USERPROFILE}\.lein}
DirExistsWarning=no
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
Compression=zip
SolidCompression=yes
ChangesEnvironment=yes
PrivilegesRequired=lowest
SetupLogging=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Messages]
#ifdef configure
WelcomeLabel2=This will configure [name] on your computer.%n%nIt is recommended that you close all other applications before continuing.
WizardReady=Ready to Configure
ReadyLabel1=Setup is now ready to begin configuring [name] on your computer.
ReadyLabel2a=Click Configure to continue, or click Back if you want to review or change any settings.
ReadyLabel2b=Click Configure to continue with the installation.
ButtonInstall=&Configure
WizardInstalling=Configuring
InstallingLabel=Please wait while Setup configures [name] on your computer.
FinishedLabelNoIcons=Setup has finished configuring [name] on your computer.
#endif

[Files]
#ifndef configure
Source: "curl.exe"; DestDir: "{app}\bin"
Source: "curl-ca-bundle.crt"; DestDir: "{app}\bin"
Source: "license.txt"; DestDir: "{app}\bin"
Source: "file-assoc-in-0.1.0-standalone.jar"; DestDir: "{app}\bin"
Source: "Output\configure-{#MyInstallerBaseName}.exe"; DestDir: "{app}\bin"
Source: "profiles.clj"; DestDir: "{%LEIN_HOME|{%USERPROFILE}\.lein}"; Flags: onlyifdoesntexist
#endif

[Icons]                                             
#ifndef configure
Name: "{group}\Clojure REPL"; Filename: "{app}\bin\lein.bat"; WorkingDir: "{userdocs}"; Parameters: "repl"; IconFilename: "{sys}\shell32.dll"; IconIndex: 133
Name: "{group}\Edit profiles.clj"; Filename: "{%LEIN_HOME|{%USERPROFILE}\.lein}\profiles.clj"; Flags: excludefromshowinnewinstall; IconFilename: "{sys}\shell32.dll"; IconIndex: 69
Name: "{group}\Online help"; Filename: "{#MyAppURL}"; Flags: excludefromshowinnewinstall; IconFilename: "{sys}\shell32.dll"; IconIndex: 154
Name: "{group}\Configure Leiningen Installation"; Filename: "{app}\bin\configure-{#MyInstallerBaseName}.exe"; Flags: excludefromshowinnewinstall
#endif

[Run]
Filename: "{app}\bin\curl.exe"; WorkingDir: "{app}\bin"; Parameters: """https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein.bat"" -L -o lein.bat"; StatusMsg: "Downloading 'lein.bat'"; Flags: runasoriginaluser runminimized
Filename: "{cmd}"; WorkingDir: "{app}\bin"; Parameters: "/c set LEIN_JAVA_CMD={code:GetSelectedJdkPath} && ""{app}\bin\lein.bat"" self-install"; StatusMsg: "Downloading leiningen (lein self-install)"; Flags: runasoriginaluser runminimized
Filename: "{#MyAppURL}"; Description: "Open online help"; Flags: postinstall nowait skipifsilent shellexec
Filename: "{cmd}"; WorkingDir: "{userdocs}"; Parameters: "/c set LEIN_JAVA_CMD={code:GetSelectedJdkPath} && ""{app}\bin\lein.bat"" repl"; Description: "Run a Clojure REPL"; Flags: postinstall nowait skipifsilent

[UninstallDelete]
#ifndef configure
Type: files; Name: "{app}\bin\lein.bat"
Type: filesandordirs; Name: "{%LEIN_HOME|{%USERPROFILE}\.lein}\self-installs"
Type: filesandordirs; Name: "{%LEIN_HOME|{%USERPROFILE}\.lein}\indices"
#endif

[Code]

const
  FileAssocJarName = 'file-assoc-in-0.1.0-standalone.jar';

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
  PreviousJdkPath : String;
  PreviousJdkIndex : Integer;
  CustomJdkIndex : Integer;

function GetSelectedJdkPath(Param: String): String;
begin
  Result := SelectedJdkPath;
end;

function IsInstalled(): Boolean;
begin
  Result := RegValueExists(HKEY_CURRENT_USER, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{450F3BB7-7198-4401-A147-BDA0BECF6A3A}_is1', 'UninstallString');
end;

procedure PopulateJdks();
var
  JavaVersions : TArrayOfString;
  JavaPath : String;
  I, J, JI : Integer;
  JavaCount : Integer;
begin
  JavaCount := 0;

  if IsWin64() then
  begin
    if RegGetSubkeyNames(HKEY_LOCAL_MACHINE_64, 'SOFTWARE\JavaSoft\Java Development Kit', JavaVersions) then
    begin
      JavaCount := JavaCount + GetArrayLength(JavaVersions);
    end
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

  if IsWin64() then
  begin
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

  PreviousJdkPath := GetEnv('LEIN_JAVA_CMD');
  if not FileExists(PreviousJdkPath) then
  begin
    PreviousJdkPath := '';
  end

end;

function InitializeSetup(): Boolean;
var
  Button : Integer;
begin            
#ifdef configure
  if not IsInstalled() then
  begin
    MsgBox('Check that the application is installed, before attempting to configure the installation', mbInformation, MB_OK);
    Result := False;
  end
  else
  begin
#endif
  PopulateJdks();

  if JdkCount > 0 then
  begin
    Result := True;
  end
  else
  begin
    Button := MsgBox('An installed Java Development Kit could not be found automatically.' + Chr(13) + Chr(10) +
                      Chr(13) + Chr(10) + 
                      'Ensure that you have downloaded and installed a JDK from:' + Chr(13) + Chr(10) + 
                      'http://www.oracle.com/technetwork/java/javase/overview/index.html' + Chr(13) + Chr(10) + 
                      Chr(13) + Chr(10) + 
                      'Continue the installation?', mbError, MB_YESNO or MB_DEFBUTTON2);
    Result := (Button = IDYES);
  end 

#ifdef configure
  end
#endif
end;

procedure InitializeWizard();
var      
  I, JI : Integer;
  BestJI : Integer;
  BestVer : String;
  Bitness : String;
  Description : String;
begin
  JdkPage := CreateInputOptionPage(wpSelectProgramGroup, 'Select JDK', '', 'Select the path to a Java Development Kit for Leiningen to use:', True, False);

  BestJI := -2;
  BestVer := '';
  JI := 0;
  for I := 0 to GetArrayLength(JdkVersions)-1 do
  begin
    if (JdkVersions[I] <> '') then
    begin
      JdkIndexes[JI] := I;
      if Jdk64s[I] then
      begin
        Bitness := '64-bit';
      end
      else
      begin
        Bitness := '32-bit';
      end

      Description := Bitness + ' JDK ' + JdkVersions[I] + '    ( ' + JdkPaths[I] + ' )';

      // Set the default as the JDK with the highest version, preferring 64-bit if available
      if (CompareText(JdkVersions[I] + '_' + Bitness, BestVer)) >= 0 then
      begin
        BestVer := Description;
        BestJI := JI;
      end

      JdkPage.Add(Description);      
      JI := JI + 1;
    end
  end

  if (PreviousJdkPath <> '') then
  begin
    PreviousJdkIndex := JI; 
    JI := JI + 1;
    JdkPage.Add('Previous location.    ( ' + PreviousJdkPath + ' )');
    JdkPage.SelectedValueIndex := PreviousJdkIndex;
  end
  else if BestJI <> -2 then
  begin
    PreviousJdkIndex := -3; 
    JdkPage.SelectedValueIndex := BestJI;
  end

  CustomJdkIndex := JI;
  JdkPage.Add('Custom location...');

  CustomJdkPage := CreateInputDirPage(JdkPage.ID, 'Custom JDK Location', '', 'Specify the location of an installed JDK:', False, '');
  CustomJdkPage.Add('');
end;

Procedure SetSelectedJdkLocation();
begin
  if JdkPage.SelectedValueIndex = CustomJdkIndex then
  begin
    SelectedJdkPath := RemoveQuotes(AddBackslash(CustomJdkPage.Values[0]) + 'bin\java.exe');
  end
  else if JdkPage.SelectedValueIndex = PreviousJdkIndex then
  begin
    SelectedJdkPath := RemoveQuotes(PreviousJdkPath);
  end
  else
  begin
    SelectedJdkPath := RemoveQuotes(AddBackslash(JdkPaths[SelectedJdkIndex]) + 'bin\java.exe');
  end
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if CurPageId = CustomJdkPage.ID then
  begin
    if FileExists(AddBackslash(CustomJdkPage.Values[0]) + 'bin\java.exe') then
    begin
      SetSelectedJdkLocation();
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
      if JdkPage.SelectedValueIndex <> CustomJdkIndex then
      begin
        SelectedJdkIndex := JdkIndexes[JdkPage.SelectedValueIndex];
        SetSelectedJdkLocation();
      end
    end
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

function SetProfileJavaCmd(JavaPath: String): Boolean;
var
  ProfilesPath: String;
  AssocArgs: String;
  ResultCode: Integer;
  ResultMsg: String;
  Success: Boolean;
begin
  ProfilesPath := AddBackslash(ExpandConstant('{%LEIN_HOME|{%USERPROFILE}\.lein}')) + 'profiles.clj';
  AssocArgs := '-jar ' + AddQuotes(AddBackslash(ExpandConstant('{app}\bin')) + FileAssocJarName) + ' ' +
                            AddQuotes(ProfilesPath) + ' ' +
                            '"[:user :java-cmd]"' + ' ' +
                            AddQuotes(JavaPath);
  Log('Assoc Command: ' + JavaPath + ' ' + AssocArgs);
  Success := Exec(JavaPath, AssocArgs,
                      ExpandConstant('{app}\bin'), SW_SHOWMINIMIZED, ewWaitUntilTerminated, ResultCode);
  if Success and (ResultCode = 0) then
  begin
    Log('Updated profile');
  end
  else
  begin
    if Success then
    begin
      ResultMsg := 'Ran';
    end
    else
    begin
      ResultMsg := SysErrorMessage(ResultCode);
    end
    Log('Failed to update profile: ' + IntToStr(ResultCode));
    MsgBox('Failed to update file: ' + ProfilesPath + chr(13) + chr(10) +
            'Ensure that :java-cmd is set to: ' + AddQuotes(JavaPath) + ' in your :user profile.' + chr(13) + chr(10) +
            'Result: ' + ResultMsg + '; Code: ' + IntToStr(ResultCode),
            mbError, MB_OK);
  end
  Result := Success;
end;

function UpdateReadyMemo(Space, NewLine, MemoUserInfoInfo, MemoDirInfo, MemoTypeInfo, MemoComponentsInfo, MemoGroupInfo, MemoTasksInfo: String): String;
var
  InstallInfo : String;
begin
  if (MemoDirInfo <> '') then
  begin
    InstallInfo := MemoDirInfo;
  end
  else
  begin
    InstallInfo := 'Install location:' + NewLine + Space + ExpandConstant('{app}') + NewLine;
  end

  Result := MemoUserInfoInfo +
            InstallInfo +
            MemoTypeInfo +
            MemoComponentsInfo +
            MemoGroupInfo +
            MemoTasksInfo +
            NewLine + 'JDK Path:' + NewLine + Space + SelectedJdkPath;
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
    Log('Original PATH: ' + Path);

    AppPath := ExpandConstant('{app}\bin');
    Log('App Path: ' + AppPath);

    Path := AppendToPath(Path, AppPath);
    Log('Updated PATH: ' + Path);
    RegWriteStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', Path);
    Log('PATH changed');

    JavaPath := RemoveQuotes(SelectedJdkPath);
    Log('Java Path: ' + JavaPath);
    RegWriteStringValue(HKEY_CURRENT_USER, 'Environment', 'LEIN_JAVA_CMD', JavaPath);
    Log('Set LEIN_JAVA_CMD: ' + JavaPath);

    SetProfileJavaCmd(JavaPath);
  end
end;

#ifndef configure
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
      AppPath := ExpandConstant('{app}\bin');
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
#endif


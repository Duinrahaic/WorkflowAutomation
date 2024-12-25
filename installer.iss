[Setup]
#define MyAppName "WorkflowAutomation"
#define MyAppExeName "WorkflowAutomation.exe"
#define OutputPath "output"

AppName={#MyAppName}
AppVersion=1.0.0
DefaultDirName={pf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir={#OutputPath}
OutputBaseFilename={#MyAppName}_Installer
Compression=lzma
SolidCompression=yes
SignTool=SignTool.exe sign /fd SHA256 /a /f "{#OutputPath}\self-signed-cert.pfx" /p "password" $f

[Files]
Source: "{#OutputPath}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent

[Code]
function InitializeSetup: Boolean;
begin
  Result := True;
end;

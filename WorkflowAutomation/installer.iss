[Setup]
#define RepositoryName "WorkflowAutomation"

AppName={#RepositoryName}
AppVersion=1.0.0
DefaultDirName={pf}\{#RepositoryName}
DefaultGroupName={#RepositoryName}
OutputDir=output
OutputBaseFilename={#RepositoryName}-Installer
Compression=lzma
SolidCompression=yes

[Files]
Source: "{#RepositoryName}\bin\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs
Source: "dotnet-runtime-installer.exe"; DestDir: "{tmp}"; Flags: ignoreversion

[Run]
Filename: "{tmp}\dotnet-runtime-installer.exe"; Parameters: "/quiet"; StatusMsg: "Installing .NET Core Runtime 8..."; Flags: waituntilterminated runhidden

[Icons]
Name: "{group}\{#RepositoryName}"; Filename: "{app}\{#RepositoryName}.exe"
Name: "{group}\Uninstall {#RepositoryName}"; Filename: "{uninstallexe}"

[Code]
function IsDotNetInstalled: Boolean;
var
  VersionOutput: string;
begin
  Result := Exec('cmd.exe', '/C dotnet --list-runtimes', '', SW_HIDE, ewWaitUntilTerminated, VersionOutput) and (Pos('Microsoft.NETCore.App 8.', VersionOutput) > 0);
end;

procedure InitializeWizard;
begin
  if not IsDotNetInstalled then
  begin
    ExtractTemporaryFile('dotnet-runtime-installer.exe');
  end;
end;

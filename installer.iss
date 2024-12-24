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

[Run]
Filename: "powershell.exe"; Parameters: "-Command if (!(Get-Command 'dotnet' -ErrorAction SilentlyContinue)) { Start-Process -FilePath msiexec.exe -ArgumentList '/i https://dotnet.microsoft.com/download/dotnet/thank-you/runtime-desktop-8.0.0-windows-x64-installer /quiet' -Wait }"; StatusMsg: "Installing .NET Core Runtime 8..."; Flags: runhidden waituntilterminated
Filename: "{app}\{#RepositoryName}.exe"; Description: "Launch {#RepositoryName}"; Flags: nowait postinstall skipifsilent

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
    MsgBox('The required .NET Core Runtime 8 is not installed. It will now be downloaded and installed.', mbInformation, MB_OK);
  end;
end;

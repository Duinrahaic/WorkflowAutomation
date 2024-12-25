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

[Code]
function IsDotNet8Installed: Boolean;
var
  VersionOutput: string;
begin
  Result := Exec('cmd.exe', '/C dotnet --list-runtimes', '', SW_HIDE, ewWaitUntilTerminated, VersionOutput) and (Pos('Microsoft.NETCore.App 8.', VersionOutput) > 0);
end;

function GetLatestDotNet8RuntimeUrl: String;
var
  Url: String;
  TempFile: String;
  DownloadCode: Integer;
begin
  TempFile := ExpandConstant('{tmp}\runtime-latest.json');
  Url := 'https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/releases-index.json';

  // Download the release metadata
  if not DownloadTemporaryFile(Url, TempFile, DownloadCode) then
  begin
    MsgBox('Failed to download .NET release metadata. Setup will now exit.', mbError, MB_OK);
    Result := '';
    Exit;
  end;

  // Parse the latest release URL for .NET 8
  Result := ExtractJsonField(TempFile, 'releases', 'latest-release-url', '8.0');
  if Result = '' then
  begin
    MsgBox('Failed to find the latest .NET 8 runtime URL. Setup will now exit.', mbError, MB_OK);
  end;
end;

function InitializeSetup: Boolean;
var
  dotNet8Installed: Boolean;
  latestDotNetRuntimeUrl: string;
  downloadResultCode: Integer;
begin
  Result := True;

  dotNet8Installed := IsDotNet8Installed;

  if not dotNet8Installed then
  begin
    MsgBox('The .NET 8 runtime is required. Downloading and installing it now.', mbInformation, MB_OK);

    latestDotNetRuntimeUrl := GetLatestDotNet8RuntimeUrl;

    if latestDotNetRuntimeUrl = '' then
    begin
      Result := False;
      Exit;
    end;

    // Run PowerShell to fetch and install the latest .NET 8 runtime installer
    Exec('powershell.exe', '/C Invoke-WebRequest -Uri ' + latestDotNetRuntimeUrl + ' -OutFile "{tmp}\dotnet-installer.exe"; Start-Process msiexec.exe -ArgumentList "/i {tmp}\dotnet-installer.exe /quiet" -Wait', '', SW_HIDE, ewWaitUntilTerminated, downloadResultCode);

    dotNet8Installed := IsDotNet8Installed;

    if not dotNet8Installed then
    begin
      MsgBox('Failed to download and install the .NET 8 runtime. Setup will now exit.', mbError, MB_OK);
      Result := False;
    end;
  end;
end;

function DownloadTemporaryFile(const Url, DestFile: String; var ErrorCode: Integer): Boolean;
begin
  Exec('powershell.exe', '/C Invoke-WebRequest -Uri ' + Url + ' -OutFile ' + DestFile, '', SW_HIDE, ewWaitUntilTerminated, ErrorCode);
  Result := FileExists(DestFile);
end;

function ExtractJsonField(const FilePath, ArrayKey, FieldKey, MatchValue: String): String;
var
  JsonOutput: String;
  TempCode: Integer;
begin
  Result := '';
  Exec('powershell.exe', '/C Get-Content ' + FilePath + ' | ConvertFrom-Json | Select-Object -ExpandProperty ' + ArrayKey + ' | Where-Object {$_.channel-version -like "' + MatchValue + '*"} | Select-Object -ExpandProperty ' + FieldKey, '', SW_HIDE, ewWaitUntilTerminated, TempCode);
  if TempCode = 0 then
    Result := JsonOutput;
end;

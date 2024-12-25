name: Build, Test, and Release Installer

on:
  push:
    tags:
      - 'v*' # Trigger on version tags

jobs:
  build-release:
    runs-on: windows-latest

    steps:
      # Step 1: Checkout the repository
      - name: Checkout Repository
        uses: actions/checkout@v4

      # Step 2: Setup .NET
      - name: Setup .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: 8.0

      # Step 3: Restore dependencies
      - name: Restore Dependencies
        run: dotnet restore

      # Step 4: Build and Test the application
      - name: Publish Application with Runtime
        run: dotnet publish -c Release -o output --self-contained --runtime win-x64

      - name: Run Tests
        run: dotnet test --no-build --verbosity normal

      # Step 5: Generate a Self-Signed Certificate
      - name: Generate Self-Signed Certificate
        run: |
          $cert = New-SelfSignedCertificate -Type CodeSigning -Subject "CN=SelfSigned" -CertStoreLocation "Cert:\LocalMachine\My"
          $thumbprint = $cert.Thumbprint
          Export-PfxCertificate -Cert "Cert:\LocalMachine\My\$thumbprint" -FilePath self-signed-cert.pfx -Password (ConvertTo-SecureString -String "password" -Force -AsPlainText)
        shell: pwsh

      # Step 6: Create Inno Setup Installer
      - name: Create Inno Setup Installer
        run: |
          iscc /DMyAppName=${{ github.event.repository.name }} /DMyOutputPath=output /DMyInstallerPath=installer.iss

      # Step 7: Sign the Installer
      - name: Sign Installer
        run: |
          SignTool sign /fd SHA256 /f self-signed-cert.pfx /p password output/${{ github.event.repository.name }}_Installer.exe

      # Step 8: Get Pull Requests Since Last Tag
      - name: Get Pull Requests Since Last Tag
        id: prs
        run: |
          PREV_TAG=$(git describe --tags --abbrev=0 HEAD^)
          echo "Previous Tag: $PREV_TAG"
          PRS=$(gh pr list --base $PREV_TAG --json title,number --jq '.[] | "- PR #\(.number): \(.title)"')
          echo "prs=$PRS" >> $GITHUB_ENV
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      # Step 9: Create Release with Installer Asset
      - name: Create GitHub Release
        uses: actions/create-release@v1
        with:
          tag_name: ${{ github.ref_name }}
          release_name: Release ${{ github.ref_name }}
          body: |
            ## Pull Requests
            ${{ env.prs }}
          draft: false
          prerelease: false
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Upload Installer to Release
        uses: actions/upload-release-asset@v1
        with:
          repo_token: ${{ secrets.GITHUB_TOKEN }}
          release_id: ${{ steps.create-release.outputs.id }}
          asset_path: output/${{ github.event.repository.name }}_Installer.exe
          asset_name: ${{ github.event.repository.name }}_Installer.exe
          content_type: application/vnd.microsoft.portable-executable

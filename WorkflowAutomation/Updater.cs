using System;
using System.Diagnostics;
using System.IO;
using System.Net.Http;
using System.Reflection;
using System.Text.Json;
using System.Threading.Tasks;

namespace WorkflowAutomation;

public static class Updater
{
    private static readonly string Username = "Duinrahaic";
    private static readonly string ApplicationName = $"{Assembly.GetExecutingAssembly().GetName().Name}";

    private static async Task<string?> Query()
    {
        try
        {
            using var client = new HttpClient();
            client.DefaultRequestHeaders.Add("User-Agent", $"{ApplicationName}-AutoUpdater");
            var response = await client.GetStringAsync($@"https://api.github.com/repos/{Username}/{ApplicationName}/releases/latest");
            return response;
        }
        catch
        {
            return null;
        }
    }

    private static bool CheckForUpdate(string query)
    {
        try
        {
            var json = JsonDocument.Parse(query);
            var latestVersionTag = json.RootElement.GetProperty("tag_name").GetString();
            if (string.IsNullOrEmpty(latestVersionTag))
                return false;

            var currentVersion = new Version($"{Assembly.GetExecutingAssembly().GetName().Version}"); 
            var latestVersion = new Version(latestVersionTag.TrimStart('v'));
            return latestVersion > currentVersion;
        }
        catch
        {
            return false;
        }
    }

    private static async Task DownloadUpdate(string query)
    {
        try
        {
            var json = JsonDocument.Parse(query);
            var dl = json.RootElement.GetProperty("assets")[0].GetProperty("browser_download_url").GetString();

            if (string.IsNullOrEmpty(dl))
                return;

            string outputFilePath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, $"{ApplicationName}-Installer.exe");

            Console.WriteLine($"Downloading update from {dl}...");
            using var client = new HttpClient();
            using var response = await client.GetAsync(dl, HttpCompletionOption.ResponseHeadersRead);

            response.EnsureSuccessStatusCode();

            using var fileStream = new FileStream(outputFilePath, FileMode.Create, FileAccess.Write, FileShare.None);
            await response.Content.CopyToAsync(fileStream);

            Console.WriteLine("Update downloaded. Launching installer...");

            Process.Start(new ProcessStartInfo
            {
                FileName = outputFilePath,
                UseShellExecute = true
            });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error downloading update: {ex.Message}");
        }
    }

    public static async Task Update()
    {
        var query = await Query();
        if (string.IsNullOrEmpty(query)) return;
        if (CheckForUpdate(query))
        {
            Console.WriteLine("Update available. Downloading...");
            await DownloadUpdate(query);
        }
        else
        {
            Console.WriteLine("No updates available.");
        }
    }
}

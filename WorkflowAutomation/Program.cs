﻿namespace WorkflowAutomation;

class Program
{
    static async Task Main(string[] args)
    {
        Console.WriteLine("Hello, World!");
        await Updater.Update();
    }
}
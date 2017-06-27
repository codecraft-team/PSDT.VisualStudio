@{
    RootModule = '.\PSDT.VisualStudio.psm1'
    ModuleVersion = '1.0.0.0'
    GUID = 'a2257dee-1612-4a75-b823-50821e27f227'
    Author = 'Tauri-Code'
    CompanyName = 'Tauri-Code'
    Copyright = '(c) 2017 Tauri-Code. All rights reserved.'
    Description = 'A collection of Visual Studio related PowerShell developer tools.'
    RequiredModules = @("PSDT.App")
    FunctionsToExport = @("Import-VSCommandPrompt","Get-VSSolution","Invoke-VSBuild","Invoke-VSTest","Restore-VSSolutionNugetPackages")
    CmdletsToExport = @("*-*")
    VariablesToExport = '*'
    AliasesToExport = @("gvss","ivsb","ivst","rvss")
}
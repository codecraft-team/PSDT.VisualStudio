<#
.Synopsis
    Imports Visual Studio command prompt variables to the current session.
.DESCRIPTION
    Check the $env:PSDT_VSCommandPromptVariable variable to see, which version of Visual Studio tools was used by the import. 
#>
Function Import-VSCommandPrompt() {
    # Calls Import-VSCommandPrompt because module will be loaded.
}

$env:PSDT_VSCommandPromptVariable = $null;

Function VSCommandPrompt {
    $vsDevCmd = Get-ChildItem VsDevCmd.bat -Path "C:\*\Microsoft Visual Studio*\Common7\Tools" -Recurse | Select-Object -Last 1;
    $env:PSDT_VSCommandPromptVariable = $($vsDevCmd.FullName);

    Push-Location $vsDevCmd.DirectoryName;
    
    $activity = "Loading developer command prompt environment: {0}..." -f $($vsDevCmd.FullName);
    Write-Progress -Activity $activity -Status "Looking for variables...";
    
    cmd /c "$($vsDevCmd.Name)&Set" | ForEach-Object {
        if ($_ -match "=") {
            $v = $_.split("=");
            Write-Progress -Activity $activity -Status "ENV:\$($v[0]) = $($v[1])";
            Set-Item -Force -Path "ENV:\$($v[0])" -Value "$($v[1])";
        }
    }

    Write-Progress -Activity $activity -Completed;

    Pop-Location;
}

<#
.Synopsis
    Gets the Visual Studio solutions, which match the filter parameters in the current or in any child directories.
    The cmdlet's default alias is: gvss
.DESCRIPTION
    The cmdlet is using the Get-File cmdlet from the PSDT.App module, to find the solution files.
.EXAMPLE
    The example gets all solutions files on the drive R, which have a matching FullName for the pattern *common*full*.
   
    PS R:\Get-VSSolution common full
   
        Directory: R:\Source\cool-project\master\common\Sources\Builds\FullBuild

    Mode                LastWriteTime         Length Name                                                                                           
    ----                -------------         ------ ----                                                                                           
    -a----         1/9/2017   8:03 AM          21870 FullBuild.sln                                                                                  

.EXAMPLE
    The example gets all solution files under the R:\Source, which have a matching FullName for the pattern *cool*ject*host*.

    PS R:\Source\Get-VSSolution cool ject host
    
        Directory: R:\Source\cool-project\master\accounts\Sources\Deployment\ServiceHost

    Mode                LastWriteTime         Length Name                                                                                           
    ----                -------------         ------ ----                                                                                           
    -a----        1/23/2017  12:56 PM          17492 ServiceHost.sln                                                                                

        Directory: R:\Source\cool-project\master\orders\Sources\Deployment\ServiceHost

    Mode                LastWriteTime         Length Name                                                                                           
    ----                -------------         ------ ----                                                                                           
    -a----         3/3/2017   3:13 PM          55670 ServiceHost.sln                                                                                

.EXAMPLE
    The example shows all matching projects using tab completion.

    Type the command below and press the TAB.
        
        PS R:\Get-VSSolution common full

    Pressing the tab will replace the last word with the first matching solution.
        
        PS R:\Get-VSSolution common R:\Source\cool-project\master\common\Sources\Builds\FullBuild.sln

.EXAMPLE
    The example shows all matching projects in a completion list.

    After typing the following line:
        
        PS R:\Get-VSSolution common f

    Pressing the CTRL+SPACE will replace the last word with the first matching solution's full name, and will list each other matches.
        
        PS R:\Get-VSSolution common R:\Source\cool-project\master\common\Sources\Builds\FullBuild.sln
        R:\Source\cool-project\master\common\Sources\Builds\FeedbackBuild.sln
        R:\Source\cool-project\master\common\Sources\Builds\FeatureBuild.sln

#>
Function Get-VSSolution {
    return Find-ChildItem -Filter "*.sln" @args;
}

Set-Alias gvss Get-VSSolution;

<#
.Synopsis
   Builds the specified solution.
   The cmdlet default alias is: ivsb
.DESCRIPTION
   Uses msbuild to build visual studio solution files.
.EXAMPLE
   Invoke-VSBuild -Solution Build.sln
   The example uses default values to build the explicitly passed solution.
.EXAMPLE
   Get-VSSolution Build.sln | Invoke-VSBuild
   The example uses default values to build the solution passed using pipes.
.EXAMPLE
   Invoke-VSBuild Build.sln -Target "Clean"
   The example uses the Target parameter to clean invoke the Clean msbuild target.
.EXAMPLE
   Invoke-VSBuild Build.sln -MaxCpuCount 8
   The sample uses the max cpu count property to build in parallel using 8 msbuild processes.
.EXAMPLE
   Invoke-VSBuild Build.sln -Properties "/p:SkipMerge=True" -Verbosity normal
   The samples passes a customer msbuild property using the Properties parameter and set msbuild verbosity to normal.
.EXAMPLE
   Invoke-VSBuild Build.sln -Properties "/p:Platform=x86"
   The sample uses the platform property to build e.g. a universal windows app for x86 platform.
#>
Function Invoke-VSBuild {
    [CmdletBinding()]
    Param(
        # The solution to be build.
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)]
        [Alias("FullName")]
        [string]$Solution,

        # The msbuild configuration. Default is "Debug".
        [Parameter(Mandatory=$false)]
        [string]$Configuration = "Debug",

        # The msbuild target to be build. Default is "Build".
        [Parameter(Mandatory=$false)]
        [string[]]$Target = "Build",

        # The msbuild verbosity. Default is minimal.
        [Parameter(Mandatory=$false)]
        [ValidateSet('quiet','minimal','normal','detailed','diagnostics')]
        [string]$Verbosity = "minimal",

        # Additional msbuild properties like "/p:Platform=x86". The string can contain multiple properties. Use a semicolon or a comma to separate multiple properties.
        [Parameter(Mandatory=$false)]
        [string]$Properties,

        # Specifies how many cpu to use for executing msbuild. Default is 4.
        [Parameter(Mandatory=$false)]
        [string]$MaxCpuCount=4,

        # Specifiy the build output directory.
        [Parameter(Mandatory=$false)]
        [string]$OutDir
    )
    
    Process {  
        $sw = [system.diagnostics.stopwatch]::startNew();
    
        $SolutionFileInfo = Get-Item $Solution;

        $targets = $Target -join ";";
        
        $msbuild = "MSBuild.exe";
        
        $cmdlineArguments = @("$($SolutionFileInfo.FullName)", "/v:$Verbosity", "/p:Configuration=$Configuration", "/t:$targets", "/m:$MaxCpuCount");
    
        If ($Properties){$cmdlineArguments += "$Properties"}
      
        If ($OutDir){$cmdlineArguments += "/p:OutDir=$OutDir"}
        
        Write-Verbose("Commandline: $msbuild $cmdlineArguments");
    
        & $msbuild $cmdlineArguments; 
    
        $sw.Stop();
    
        Write-Host $(("Finished in {0:0.00} seconds." -f $sw.Elapsed.TotalSeconds)) -ForegroundColor Cyan
    }
}

Set-Alias ivsb Invoke-VSBuild;

<#
.Synopsis
   Executes the tests for the specified solution
   The cmdlet default alias is: ivst
.DESCRIPTION
   Uses VSTest.Console.exe to excute tests
   Assemblies containing tests are identified by default using a match on the file names. See the FileMatch parameter for default settings.
.EXAMPLE
   Invoke-VSTest -TestCaseFilter "TestCategory!=LongRunningTests"
   The example executes the tests and ignores tests marked with TestCategoryAttribute "LongRunningTests".
.EXAMPLE
   Invoke-VSTest -Parallel
   The example executes the tests in parallel.
.EXAMPLE
   Invoke-VSTest -Settings local.runsettings
   The example executes the tests using local.runsettings file.
#>
Function Invoke-VSTest {
    [CmdletBinding()]
    Param(
        # Pattern to match test files.
        # Default is set to "*tests.dll".
        [Parameter(Mandatory=$false)]
        [string]$FileMatch = "*tests.dll",

        # Pattern to match test file path.
        # Default is set to ".*\\bin\\debug\\".
        [Parameter(Mandatory=$false)]
        [string]$PathMatch = ".*\\bin\\debug\\",

        # Filter for tests. Default is set to "TestCategory!=Integrated&TestCategory!=Integration&TestCategory!=Evaluation".
        [Parameter(Mandatory=$false)]
        [string]$TestCaseFilter = "TestCategory!=Integrated&TestCategory!=Integration&TestCategory!=Evaluation",

        # Path to a runsettings file.
        [Parameter(Mandatory=$false)]
        [string]$Settings,

        # Switch to specifiy whether the tests should be excuted in parallel.
        [Switch]$Parallel
    )
    $sw = [system.diagnostics.stopwatch]::startNew();

    Write-Host "Searching for test files: Path:$PathMatch File:$FileMatch";
    
    $testAssemblies = Get-ChildItem -Filter $FileMatch -File -Recurse -ErrorAction SilentlyContinue | Where-Object {$_.FullName -match $PathMatch};
    
    Write-Host "$($testAssemblies.Length) test files found.";

    $mstest = "VSTest.Console.exe";

    $cmdlineArguments = @($testAssemblies.FullName) + @("/TestCaseFilter:`"$TestCaseFilter`"");
   
    If ($Parallel){$cmdlineArguments += "/Parallel"}

    If ($Settings){$cmdlineArguments += "/Settings:$Settings"}
    
    Write-Verbose("Commandline: $mstest $cmdlineArguments");
    
    & $mstest $cmdlineArguments; 
    
    $sw.Stop();

    Write-Host $(("Finished in {0:0.00} seconds." -f $sw.Elapsed.TotalSeconds)) -ForegroundColor Cyan
}

Set-Alias ivst Invoke-VSTest;

<#
.Synopsis
    Restores nuget packages of a specific Visual Studio solution, or based on a packages.config file.
    The cmdlet default alias is: rvss

.DESCRIPTION
    The cmdlet downloads the latest nuget.exe to the temp folder ($env:TEMP) and uses the restore switch to restore packages.
    If a solution file was passed to the cmdlet, it will look for packages.config files recursively under the solution's path, and will restore every package found in all config files.
    If a packages.config is passed, then it will use it for restoring packages.

    The cmdlets accepts either -Solution or -PackagesConfig parameter. If both are defined, the -Solution parameter will be used and -PackagesConfig will be ignored.
    If both -Solution and -PackagesConfig are missing or do not exist, an error will be displayed.

    The return value of the cmdlet is the -Solution, to support the concept of VS specific cmdlets within this module.

.EXAMPLE
    Consider the following file system structure:

       Directory: R:\Source\MySolution

    Mode                LastWriteTime         Length Name
    ----                -------------         ------ ----
    d-----        6/27/2017   5:57 PM                en-US
    d-----        6/27/2017   4:12 PM                CSharpProject1
    d-----        6/27/2017   3:53 PM                CSharpProject2
    -a----        6/27/2017   5:19 PM            999 MySolution.sln
   
    The following cmdlet:
        PS R:\Source\MySolution> Restore-VSSolutionNugetPackages -Solution MySolution.sln

        - checks whether $env:TEMP\nuget.exe exits. If not, it will download it.
        - looks for packages.config files under en-US, CSharpProject1 and CSharpProject2 folder, 
        - and calls nuget retore with the result.

.EXAMPLE
    Consider the following file system structure:

       Directory: R:\Source\MySolution

    Mode                LastWriteTime         Length Name
    ----                -------------         ------ ----
    d-----        6/27/2017   5:57 PM                en-US
    d-----        6/27/2017   4:12 PM                CSharpProject1
    d-----        6/27/2017   3:53 PM                CSharpProject2
    -a----        6/27/2017   5:19 PM            999 MySolution.sln
   
    The following cmdlet:
        PS R:\> Get-VSSolution MySolution | Restore-VSSolutionNugetPackages

        - Get-VSSolution will look for solution files recursively, and will pass them to Restore-VSSolutionPackages
        Restore-VSSolutionPackages then
        - checks once, whether $env:TEMP\nuget.exe exits. If not, it will download it,
        - looks for packages.config files under en-US, CSharpProject1 and CSharpProject2 folder,
        - and calls nuget retore with the result.

        Note that the Restore-VSSolutionPackages logic, except the first point, is executed for each solution, which is passed to the pipeline.

.EXAMPLE
    Consider the following file system structure and assume, that CSharpProject1 and CSharpProject2 contains one packages.config file:

       Directory: R:\Source\MySolution

    Mode                LastWriteTime         Length Name
    ----                -------------         ------ ----
    d-----        6/27/2017   5:57 PM                en-US
    d-----        6/27/2017   4:12 PM                CSharpProject1
    d-----        6/27/2017   3:53 PM                CSharpProject2
   
    The following cmdlet:
        PS R:\Source\MySolution> Get-ChildItem -Filter packages.config -Recursive | Foreach-Object { Restore-VSSolutionNugetPackages -PackagesConfig $_.FullName }

        - looks for every packages.config recursively and passes them to Foreach-Object.
        - Foreach-Object invokes the Restore-VSSolutionNugetPackages cmdlet for each packages.config one by one.
        Restore-VSSolutionNugetPackages 
        - checks on each call, whether $env:TEMP\nuget.exe exits. If not, it will download it,
        - looks for packages.config files under en-US, CSharpProject1 and CSharpProject2 folder,
        - and calls nuget retore with the result.
#>
function Restore-VSSolutionNugetPackages {
    [CmdletBinding()]
    param (
        # The solution for which nuget packages should be restored.
        [Parameter(ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)]
        [Alias("FullName")]
        [string]$Solution,

        # The packages.config to use for restoring nuget packages.
        [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [string]$PackagesConfig
    )

    begin {
        $nugetExe = "$($env:TEMP)\nuget.exe";
        if (-not (Test-Path $nugetExe)) {        
            Invoke-WebRequest "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile $nugetExe;
        }
        Set-Alias nuget $nugetExe -Scope Global -Verbose;
    }

    process {
        if ($Solution.Length -eq 0 -and $PackagesConfig.Length -eq 0) {
            Write-Error "Either -Solution or -PackagesConfig parameter should be passed to the cmdlet.";
        }
        else {
            if (($Solution.Length -gt 0) -and (Test-Path $Solution)) {
                Get-ChildItem -Filter packages.config -Path (Split-Path $Solution) -Recurse | ForEach-Object { nuget restore $_.FullName -Verbosity Detailed } | Out-Null;
            } elseif (($PackagesConfig.Length -gt 0) -and (Test-Path $PackagesConfig)) {
                nuget restore $PackagesConfig -Verbosity Detailed;
            } else {
                Write-Error "Either -Solution or -PackagesConfig should be an existing file.";
            }
        }

        return $Solution;
    }
}

Set-Alias rvss Restore-VSSolutionNugetPackages;

VSCommandPrompt;
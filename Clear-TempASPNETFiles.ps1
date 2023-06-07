<#
.SYNOPSIS

Deletes the unused files in the Temporary ASP.NET Files folder based on the modules deployed by the OutSystems Platform server.

.DESCRIPTION

The Clear-TempASPNETFiles.ps1 script deletes unused files in the Temporary ASP.NET Files folder based on the modules deployed by the OutSystems Platform server.
At least one folder will be kept per module deployed by the OutSystems Platform server.
More folders can be kepp by optionally passing a higher value to the -ToKeep flag.
Any unused folder that do not match the deployed modules will be removed.
The output of the operation is logged to ".\Clear-TempASPNETFiles.log" by default.

.PARAMETER InputPath
[string] -ASPNetPath - Path for the 'Temporary ASP.NET Files' folder. Defaults to "C:\WINDOWS\Microsoft.NET\Framework64\v4.0.30319\Temporary ASP.NET Files")
[string] -OSPath - Path for the 'OutSystems Platform Server' folder. Defaults to "C:\Program Files\OutSystems\Platform Server")
[int] -ToKeep - Number of in use versions to keep for folders in use. Value needs to be bigger or equal to 1
[string] -LogfilePath - Optional path for the log file with the execution. Defaults to ".\Clear-TempASPNETFiles.log"

.INPUTS

None. You cannot pipe objects to Clear-TempASPNETFiles.ps1.

.OUTPUTS

A log file is generated with the output of the operation. Defaults to ".\Clear-TempASPNETFiles.log"

.EXAMPLE

PS> .\Clear-TempASPNETFiles.ps1

.EXAMPLE

PS> .\Clear-TempASPNETFiles.ps1 -ASPNetPath "C:\WINDOWS\Microsoft.NET\Framework64\v4.0.30319\Temporary ASP.NET Files" -OSPath "C:\Program Files\OutSystems\Platform Server" -ToKeep 1 -LogfilePath ".\Clear-TempASPNETFiles.log"

#>

param
(

    # Enter the path for the 'Temporary ASP.NET Files' folder. Defaults to C:\WINDOWS\Microsoft.NET\Framework64\v4.0.30319\Temporary ASP.NET Files")
    [string] $ASPNetPath = (Join-Path -Path ([environment]::getfolderpath("Windows")) -ChildPath "Microsoft.NET\Framework64\v4.0.30319\Temporary ASP.NET Files"),
    # Enter the path for the 'OutSystems Platform Server' folder. Defaults to C:\Program Files\OutSystems\Platform Server")
    [string] $OSPath = (Join-Path -Path ([environment]::getfolderpath("ProgramFiles")) -ChildPath "OutSystems\Platform Server"),
    # Number of in use versions to keep for folders in use. Value needs to be bigger or equal to 1
    [int] $ToKeep = 1,
    # Optional path for the log file with the execution. Defaults to ".\Clear-TempASPNETFiles.log"
    [string] $LogfilePath = ".\Clear-TempASPNETFiles.log"
)
if (-not(Test-Path -Path $ASPNetPath)) {
    Write-Error "'Temporary ASP.NET Files' folder not found at '$($ASPNetPath)', please provide it using the -ASPNetPath flag"
    return
}
if (-not(Test-Path -Path $OSPath)) {
    Write-Error "'Outsystems\Platform Server' folder not found at '$($OSPath)', please provide it using the -OSPath flag"
    return
}
if ( $ToKeep -lt 1) {
    Write-Error " Minimum versions to keep is one. Please provide a value greater or equal than one using the -ToKeep flag"
    return
}

# Helper funtion to write in the log file
function WriteLog {
    Param ([string]$LogString)
    $Stamp = (Get-Date).toString("[yyyy-MM-dd HH:mm:ss.fff]")
    $LogMessage = "$Stamp $LogString"
    Add-content $LogfilePath -value $LogMessage
}

<#
Helper funtion that will get the list of folders by LastWriteTime in descending order and skip X amount of files passed as parameter
The folders returned will then be deleted.
#>
function Get-Folders-To-Delete {
    Param (
        [Parameter(Mandatory = $true)] [string] $FolderPath,
        [Parameter(Mandatory = $true)] [int] $FoldersToSkip
    )

    $tempFolders = Get-ChildItem -Path $FolderPath |
    Where-Object { $_.PSIsContainer } |
    Sort-Object LastWriteTime  -desc |
    Select-Object -Skip $FoldersToSkip

    if ($tempFolders.count -eq 0) {
        return 0
    }
    $size = ($tempFolders | Get-ChildItem -Recurse | Measure-Object -Sum Length).Sum 
    WriteLog "Cleaning $("{0:N2} MB" -f ($size/ 1MB)) of folder: $($FolderPath)"
    foreach ($file in $tempFolders) {
        $path = Join-Path -Path $FolderPath -ChildPath $file
        Remove-Item -Recurse -Force $path
        WriteLog "Removed old folder: $($file)"
    }
    return $size
}

#Get the list of folders inside the "Temporary ASP.NET Files" folder 
$tempFolders = Get-ChildItem -Path $ASPNetPath |
Where-Object { $_.PSIsContainer } | 
Foreach-Object { $_.Name.ToLower().Split('.')[0] }

#Get the list of folders inside the "Platfrom Server Running" folder 
$running = Join-Path -Path $OSPath -ChildPath "running"
$apps = Get-ChildItem -Path $running |
Where-Object { $_.PSIsContainer } | 
Foreach-Object { $_.Name.ToLower().Split('.')[0] }

$UsedApps = @()
$unused = @()
# Calculate the number of folders with the same name in both the "Temporary ASP.NET Files" and "Platfrom Server Running" folders 
foreach ($folder in $tempFolders) {
    if ($apps.Contains($folder)) {
        $UsedApps += $folder 
    }
    else {
        $unused += $folder 
    }
}
WriteLog "Total App folders: $($UsedApps.count)"
WriteLog "Total Unused Folders: $($unused.count)"

if( $UsedApps.count -gt 0){
    $AppSize = 0;
    WriteLog "App folders to be deleted:"
    foreach ($folder in $UsedApps) {
        $path = Join-Path -Path $ASPNetPath -ChildPath $folder
        $AppSize += Get-Folders-To-Delete $path $ToKeep
    }
    WriteLog "Total space to be freed: $("{0:N2} MB" -f ($AppSize/ 1MB))"
}

# Check if there are folders that only exist on the "Temporary ASP.NET Files" folder and delete them
if($unused.count -gt 0){
    $UnusedSize = 0;
    WriteLog "Unused folders to be deleted:"
    foreach ($folder in $unused) {
        $path = Join-Path -Path $ASPNetPath -ChildPath $folder
        $UnusedSize += Get-Folders-To-Delete $path 0
        Remove-Item -Recurse -Force $path
    }
    WriteLog "Space to be freed: $("{0:N2} MB" -f ($UnusedSize/ 1MB))"
}



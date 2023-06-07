# Clear-TempASPNETFiles

PowerShell Script to clear the Temporary ASP Net files on an OutSystems Instalation.

## Description

The Clear-TempASPNETFiles.ps1 script deletes unused files in the Temporary ASP.NET Files folder based on the modules deployed by the OutSystems Platform server.\
At least one folder will be kept per module deployed by the OutSystems Platform server.\
More folders can be kepp by optionally passing a higher value to the -ToKeep flag.\
Unused folders that do not match any module deployed will be removed.\
The output of the operation is logged to ".\Clear-TempASPNETFiles.log" by default.

## Parameters

[string] $ASPNetPath

- Path for the 'Temporary ASP.NET Files' folder. Defaults to "C:\WINDOWS\Microsoft.NET\Framework64\v4.0.30319\Temporary ASP.NET Files")

[string] $OSPath

- Path for the 'OutSystems Platform Server' folder. Defaults to "C:\Program Files\OutSystems\Platform Server")

[int] $ToKeep

- Number of in use versions to keep for folders in use. Value needs to be bigger or equal to 1

[string] $LogfilePath

- Optional path for the log file with the execution. Defaults to ".\Clear-TempASPNETFiles.log"

## Examples

### Using defauls

```powershell
PS> .\Clear-TempASPNETFiles.ps1
```

### Changing defaults

```powershell
PS> .\Clear-TempASPNETFiles.ps1 -ASPNetPath "C:\WINDOWS\Microsoft.NET\Framework64\v4.0.30319\Temporary ASP.NET Files" -OSPath "C:\Program Files\OutSystems\Platform Server" -ToKeep 1 -LogfilePath ".\Clear-TempASPNETFiles.log"
```

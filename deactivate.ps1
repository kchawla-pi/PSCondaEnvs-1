<#
.SYNOPSIS
Deactivates an existing Conda virtual environment.

.DESCRIPTION
Deactivates previously activated Conda environment.
During deactivation, PS1 scripts in etc/conda/deactivate.d will be run as well.
If no active environment is present, no action will be taken.

The command does not produce any output on success.
Use parameter -Verbose to trace the execution.

.PARAMETER Hold
Internal use by activate.ps1

.LINK
activate.ps1
https://github.com/BCSharp/PSCondaEnvs

.EXAMPLE
(TestEnv) PS C:> deactivate
PS C:>

This command deactivates the active Conda environment named "TestEnv".

#>

Param(
    [Parameter()]
    [Switch] $Hold
)


if (-not (Test-Path Env:CONDA_DEFAULT_ENV))
{    
    Write-Warning 'No active Conda environment detected.'
    exit
}

Write-Verbose "Deactivating environment ""$Env:CONDA_DEFAULT_ENV""..."

$deactivate_d = "${Env:CONDA_PREFIX}/etc/conda/deactivate.d"
if (Test-Path $deactivate_d) {
    Write-Verbose "Running deactivate scripts in '$deactivate_d'..."
    Push-Location $deactivate_d
    Get-ChildItem -Filter *.ps1 | Select-Object -ExpandProperty FullName  | Invoke-Expression
    Pop-Location
}

# This removes the previous Env from the path and restores the original path
$pathSep = [System.IO.Path]::PathSeparator
if ($CondaEnvPaths) {
    [System.Collections.ArrayList]$pathArray = $Env:PATH -split $pathSep
    if ($Hold) {
        Write-Verbose "Setting CONDA_PATH_PLACEHOLDER where current environment paths are..."
        $position = @($pathArray).IndexOf($CondaEnvPaths[0])
        if ($position -ge 0) {
            $pathArray[$position] = 'CONDA_PATH_PLACEHOLDER'
        }
    }

    Write-Verbose 'Removing environment search paths from $PATH...'
    # Remove the first occurance of each of the env paths
    foreach ($element in $CondaEnvPaths) {
	    $pathArray.Remove($element)
    }
    $Env:PATH = $pathArray -join $pathSep
    Write-Verbose 'Restored $PATH is:'
    Write-Verbose ('-' * 20)
    $Env:PATH -split $pathSep | Write-Verbose
    Write-Verbose ('-' * 20)
} else {
    Write-Error 'Cannot determine original path, $PATH not restored'
}

if (Test-Path Function:CondaUserPrompt) {
    Write-Verbose 'Restoring original user prompt...'
    $Function:prompt = $Function:CondaUserPrompt
}

# Clean up 
Write-Verbose 'Deleting environment-specific variables and functions...'
Remove-Item Env:CONDA_DEFAULT_ENV
Remove-Item Env:CONDA_PREFIX
Remove-Item Function:condaUserPrompt
Remove-Variable CondaEnvPaths -Scope Global

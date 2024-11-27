param(
     [Parameter(Position=0,Mandatory)]
     [string]$GAME,

     [Parameter(Position=1,Mandatory)]
     [string]$MODNAME,
     [Parameter(Position=2,Mandatory=$false)]
     [string]$DISPLAYNAME
 )
 if (!$DISPLAYNAME){$DISPLAYNAME=$MODNAME}
##########################
##HELPER FUNCTIONS START##
##########################
#stole it from here:
#https://www.reddit.com/r/SteamDeck/comments/15seajp/comment/kfbjc48/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
function Get-AllGameInstallDirs {
    $SteamRegKey = Get-ItemProperty -Path "HKCU:\Software\Valve\Steam"
    $SteamPath = [System.IO.Path]::GetDirectoryName($SteamRegKey.SteamExe)
    $LibraryFoldersFile = Join-Path -Path $SteamPath -ChildPath "steamapps\libraryfolders.vdf"
    $LibraryPaths = @("$SteamPath\steamapps")
    if (Test-Path $LibraryFoldersFile) {
        $LibraryFoldersContent = Get-Content $LibraryFoldersFile -Raw
        $lines = $LibraryFoldersContent -split '\r?\n'
        #$inAppSection = $false
        foreach ($line in $lines) {
            if ($line -match '^\s*"path"\s*"(.+)"') {
                $path = $Matches[1]
                if ($path -notmatch 'totalsize') {
                    $LibraryPaths += $path
                }
            }
        }
    }
    $LibraryPaths = $LibraryPaths -replace '\\\\', '\'
    $InstalledGames = @()
    foreach ($libPath in $LibraryPaths) {
        $AppManifestPaths = Get-ChildItem -Path "$libPath\steamapps" -Filter "appmanifest_*.acf" -File -ErrorAction SilentlyContinue
        foreach ($AppManifestPath in $AppManifestPaths) {
            $AppID = $AppManifestPath.Name -replace '\D', ''
            $ManifestContent = Get-Content $AppManifestPath.FullName -Raw
            if ($ManifestContent -match '"installdir"\s*"(.*?)"') {
                $GameSubDir = $Matches[1]
                $GameInstallDir = Join-Path -Path $libPath -ChildPath "steamapps\common\$GameSubDir"
                $GameInstallDir = $GameInstallDir -replace '\\\\', '\'
                $InstalledGames += [PSCustomObject]@{
                    AppID = $AppID
                    InstallDir = $GameInstallDir
                }
            }
        }
    }
    return $InstalledGames
}
##########################
###HELPER FUNCTIONS END###
##########################
$gamePath = (Get-AllGameInstallDirs).InstallDir -match $GAME

if (!$gamePath) {
    write-host $GAME NOT DETECTED IN ANY LOCAL STEAM LIBRARIES. Terminating Setup.
    return 1
}
if (!(Test-Path .\backup)) {New-Item .\backup -ItemType Directory}
copy-item (".\MODID.csproj","MODID.sln","Info.json") .\backup
Get-ChildItem .\backup | ForEach-Object {Rename-Item $_.fullname $($_.name + ".bak")}

rename-item ".\MODID.csproj" ".\$MODNAME.csproj"
rename-item ".\MODID.sln" ".\$MODNAME.sln"

[xml]$projectManifest = get-content ".\$MODNAME.csproj"
[string]$assemblyDir = "$gamePath\NuclearOption_Data\Managed"
[string]$modDeployDir = "$gamePath\Mods\$MODNAME"

$projectManifest.Project.PropertyGroup.AssemblyName = $MODNAME
$projectManifest.Project.PropertyGroup.ModDeployDir.'#text' = $modDeployDir
$projectManifest.Project.PropertyGroup.AssemblyDir.'#text' = $assemblyDir

$projectManifest.save("$MODNAME.csproj")

(get-content ".\$MODNAME.sln") -replace "MODID.csproj","$MODNAME.csproj" -replace "MODID","$MODNAME" | set-content ".\$MODNAME.sln"

$JSON = get-content .\Info.json | convertfrom-json

$JSON.Id = $MODNAME
$JSON.DisplayName = $DISPLAYNAME
$JSON.AssemblyName = "$MODNAME.dll"
$JSON.EntryMethod = "$MODNAME.Main.Load"

$JSON | convertto-json | Set-Content .\Info.json
param(
     [Parameter(Position=0,Mandatory)]
     [string]$GAME,

     [Parameter(Position=1,Mandatory)]
     [string]$MODID,
     [Parameter(Position=2,Mandatory=$false)]
     [string]$DISPLAYNAME
 )
 if (!$DISPLAYNAME){$DISPLAYNAME=$MODID}
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

rename-item ".\MODID.csproj" ".\$MODID.csproj"
rename-item ".\MODID.sln" ".\$MODID.sln"

$assemblyPath = (get-childitem -Path $path -Recurse -Filter "Assembly-Csharp.dll" | select -ExpandProperty fullname) -replace "\\Managed\\Assembly-Csharp.dll",""
[xml]$projectManifest = get-content ".\$MODID.csproj"
[string]$assemblyDir = $assemblyPath
[string]$modDeployDir = "$gamePath\Mods\$MODID"

$projectManifest.Project.PropertyGroup.AssemblyName = $MODID
$projectManifest.Project.PropertyGroup.ModDeployDir.'#text' = $modDeployDir
$projectManifest.Project.PropertyGroup.AssemblyDir.'#text' = $assemblyDir

$projectManifest.save("$MODID.csproj")

(get-content ".\$MODID.csproj") -replace "MODID.dll","$MODID.dll" -replace "MODID.pdb","$MODID.pdb" | set-content ".\$MODID.csproj"

(get-content ".\$MODID.sln") -replace "MODID.csproj","$MODID.csproj" -replace "MODID","$MODID" | set-content ".\$MODID.sln"

(get-content ".\Main.cs") -replace "MODID","$MODID" | set-content ".\Main.cs"

$JSON = get-content .\Info.json | convertfrom-json

$JSON.Id = $MODID
$JSON.DisplayName = $DISPLAYNAME
$JSON.AssemblyName = "$MODID.dll"
$JSON.EntryMethod = "$MODID.Main.Load"

$JSON | convertto-json | Set-Content .\Info.json
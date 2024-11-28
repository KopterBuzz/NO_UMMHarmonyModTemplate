# Unity Mod Manager + Harmony Template
A minimal template for Unity Mod Manager + Harmony mods, configured to be reloadable (remove if not wanted :) )

## Instructions
run setup.ps1. you might have to change your powershell execution policy
It is going to ask for a Game name, and a Mod name.
It will try to find the Game in your local Steam library folders.
If it can find the game it is going to set up the project and solution with the right assembly paths so all Unity and Unity Mod Manager assemblies required to compile your mod are set up correctly.

Example:

.\setup.ps1 -GAME "Nuclear Option" -MODID "SampleMod" -DISPLAYNAME "Sample Mod For Nuclear Option"

You can also just edit the project template manually if you wish.
When starting out: Search and Replace:
- `MODID` with a unique Camel Case no spaces name for your mod
- `ASSEMBLYPATH` with the path to where your Assembly-CSharp.dll of your game are stored, add and remove assemblies as needed (for example Mirror networking and such)
- `DISPLAYNAME` and `AUTHOR` are only for your Info file and only change what is displayed in the Unity Mod Manager when selecting the mod.

To build:
- Use `dotnet build`. Install dotnet versions as needed. I will not handhold this process.
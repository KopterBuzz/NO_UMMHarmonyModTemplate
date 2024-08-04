# Unity Mod Manager + Harmony Template
A minimal template for Unity Mod Manager + Harmony mods, configured to be reloadable (remove if not wanted :) )

## Instructions
When starting out: Search and Replace:
- `MODID` with a unique Camel Case no spaces name for your mod
- `ASSEMBLYPATH` with the path to where your Assembly-CSharp.dll of your game are stored, add and remove assemblies as needed (for example Mirror networking and such)
- `DISPLAYNAME` and `AUTHOR` are only for your Info file and only change what is displayed in the Unity Mod Manager when selecting the mod.

To build:
- Use `dotnet build`. Install dotnet versions as needed. I will not handhold this process.
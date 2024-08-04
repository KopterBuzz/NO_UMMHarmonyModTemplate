using HarmonyLib;
using UnityModManagerNet;
using System;
using System.Reflection;
using static UnityModManagerNet.UnityModManager.ModEntry;

namespace MODID {
    [EnableReloading]
    static class Main
    {
        public static ModLogger modLogger;
        static void Load(UnityModManager.ModEntry modEntry) 
        {
            modLogger = modEntry.Logger;
            modEntry.OnUnload = Unload;
            var harmony = new Harmony("MODID");
            harmony.PatchAll();
        }

        static bool Unload(UnityModManager.ModEntry modEntry)
        {
            new Harmony("MODID").UnpatchAll();
            
            return true;
        }
    }
}
using HarmonyLib;
using UnityModManagerNet;
using System;
using System.Reflection;
using static UnityModManagerNet.UnityModManager.ModEntry;
using UnityEngine;

namespace MODID {
    public class Settings : UnityModManager.ModSettings {
        public string someSetting;
        public override void Save(UnityModManager.ModEntry modEntry)
        {
            Save(this, modEntry);
        }

        public void OnChange()
        {
        }
    }

    #if DEBUG
    [EnableReloading]
    #endif
    static class Main
    {
        public static ModLogger modLogger;
        public static Settings settings;
        static void Load(UnityModManager.ModEntry modEntry) 
        {
            settings = Settings.Load<Settings>(modEntry);
            modEntry.OnGUI = OnGUI;
            modEntry.OnSaveGUI = OnSaveGUI;

            modLogger = modEntry.Logger;

            #if DEBUG
            modEntry.OnUnload = Unload;
            #endif

            var harmony = new Harmony("MODID");
            harmony.PatchAll();
        }

        #if DEBUG
        static bool Unload(UnityModManager.ModEntry modEntry)
        {
            new Harmony("MODID").UnpatchAll();
            
            return true;
        }
        #endif

        static bool OnToggle(UnityModManager.ModEntry modEntry, bool value)
        {
            // for example have a static active variable that is checked from many points
            // active = value
            return true;
        }

        public static void OnGUI(UnityModManager.ModEntry modEntry) {
            GUILayout.BeginVertical();

            GUILayout.Label($"<color=white>Some setting</color>", 
                new GUIStyle { richText = true, fontSize = 14 }
            );
            settings.someSetting = GUILayout.TextField(settings.someSetting);

            GUILayout.EndVertical();
        }

        public static void OnSaveGUI(UnityModManager.ModEntry modEntry) {
            settings.Save(modEntry);
        }
    }

    [HarmonyPatch(typeof(SomeGameClass), "SomeClassMethod")]
    internal static class SGCMethodPatch {
        private static int exampleCounter;

        public static void Prefix(/* SomeGameClass __instance is one example of special arguments, there are quite a few, refer to docs*/) {
            exampleCounter += 1; // counts up whenever the method is called
        }
    }
}
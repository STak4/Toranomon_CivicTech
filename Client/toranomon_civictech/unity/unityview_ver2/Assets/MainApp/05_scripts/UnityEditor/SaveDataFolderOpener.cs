using System.IO;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif
public class SaveDataFolderOpener
{
#if UNITY_EDITOR    
    [MenuItem("TORANOMON_Civic_Tech / Open save data folder")]
    private static void Open()
    {
        string path = Application.persistentDataPath;
        if (!Directory.Exists(path)) Directory.CreateDirectory(path);

#if UNITY_EDITOR_WIN
        System.Diagnostics.Process.Start("explorer.exe", path.Replace('/', '\\'));
#elif UNITY_EDITOR_OSX
        EditorUtility.RevealInFinder(path);
#else
        Debug.LogWarning("この機能はWindowsとMacのみ対応しています。");
#endif
    }
#endif
}

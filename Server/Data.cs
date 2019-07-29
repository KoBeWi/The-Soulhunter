using System;
using System.Collections.Generic;

public class Data {
    public const ushort MAX_GAME_OVER_TIME = 30;

    public enum TYPE {
        U8,
        U16,
        STRING
    }

    public enum CHATS {
        SYSTEM,
        GLOBAL,
        LOCAL,
        WHISPER
    }

    public enum ABILITIES {
        AUTO_JUMP,
        DOUBLE_JUMP,
        MAX
    }

    public static bool[] CompareStateVectors(Godot.Collections.Array oldVec, Godot.Collections.Array newVec) {
        bool[] isChanged = new bool[oldVec.Count];

        for (int i = 0; i < isChanged.Length; i++) {
            isChanged[i] = !newVec[i].Equals(oldVec[i]);
        }

        return isChanged;
    }

    public static void ApplyEnchantmentSoul(Dictionary<string, object> item, Dictionary<string, object> soul) {
        if (soul == null) return;

        switch (soul["name"] as string) {
            case "Sharpness":
            if (item["type"] as string == "weapon" && item.ContainsKey("attribute") && item["attribute"] as string == "sharp")
                item["attack"] = Data.Int(item["attack"]) + 2;
            break;
        }
    }

    public static void ApplyExtensionSoul(Dictionary<string, object> soul, Dictionary<string, object> extension) {
        if (extension == null || soul == null) return;

        switch (extension["name"] as string) {
            case "Lunar Blood":
            if (soul["name"] as string == "Strong Blood") soul["max_hp"] = 40;
            break;
        }
    }

    public static void ApplyAugmentSoul(Dictionary<string, ushort> stats, Dictionary<string, object> soul) {
        if (soul == null) return;

        switch (soul["name"] as string) {
            case "Strong Blood":
            stats["max_hp"] += (ushort)Int(soul["max_hp"]);
            break;

            case "Shadow Veil":
            stats["magic_defense"] += 5;
            break;
        }
    }

    public static int Int(object whatever) {
        return (int)Godot.GD.Convert(whatever, Godot.Variant.Type.Int);
    }
}
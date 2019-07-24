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

    }

    public static void ApplyExtensionSoul(Dictionary<string, object> soul, Dictionary<string, object> extension) {
        if (extension == null) return;

    }

    public static void ApplyAugmentSoul(Dictionary<string, ushort> stats, Dictionary<string, object> soul) {
        if (soul == null) return;

    }
}
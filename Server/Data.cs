public class Data {
    public const ushort MAX_GAME_OVER_TIME = 120;

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

    public static bool[] CompareStateVectors(Godot.Collections.Array oldVec, Godot.Collections.Array newVec) {
        bool[] isChanged = new bool[oldVec.Count];

        for (int i = 0; i < isChanged.Length; i++) {
            isChanged[i] = !newVec[i].Equals(oldVec[i]);
        }

        return isChanged;
    }
}
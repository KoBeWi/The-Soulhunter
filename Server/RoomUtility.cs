using Godot;
using System;

public class RoomUtility {
    public enum DATA {
        CHEST
    }

    public static bool IsChestOpened(Character player, string chestId) {
        return Array.Exists(player.GetChests(), id => id == chestId);
    }
}

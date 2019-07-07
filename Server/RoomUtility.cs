using Godot;
using System;

public class RoomUtility {
    public enum DATA {
        CHEST
    }

    public static bool IsChestOpened(Character player, string chestId) {
        return Array.Exists(player.GetChests(), id => id == chestId);
    }

    public static void OpenChest(string chestId, ushort item, Character player) {
        if (IsChestOpened(player, chestId)) {
            return;
        }

        player.AddItem(item);
        player.SetChestOpened(chestId);
        player.GetPlayer().SendPacket(new Packet(Packet.TYPE.ITEM_GET).AddU16(item));
    }
}

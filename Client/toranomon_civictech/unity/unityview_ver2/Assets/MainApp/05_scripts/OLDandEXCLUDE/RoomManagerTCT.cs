// based on: Assets\Samples\OnDevicePersistence\Scripts\RoomManager.cs

using System;
using System.Collections.Generic;
using Niantic.Lightship.SharedAR.Datastore;
using Niantic.Lightship.SharedAR.Rooms;
using UnityEngine;

/// <summary>
/// RoomManagerTCT
/// このクラスは、ネットワーク上のルーム（部屋）の作成・参加・退出・削除などを管理します。
/// ルームの初期化後にネットワークやデータストアのイベントリスナーを設定できるようにします。
/// </summary>
public class RoomManagerTCT : MonoBehaviour
{
    /// <summary>
    /// デフォルトのルーム説明文
    /// </summary>
    public string _roomDescription;

    /// <summary>
    /// デフォルトのルーム収容人数
    /// </summary>
    [SerializeField]
    private int _roomCapacity = 10;

    /// <summary>
    /// ルームオブジェクト。CreateNewRoom()またはJoinRoomById()呼び出し前はnull
    /// </summary>
    public IRoom Room { get; private set; }

    /// <summary>
    /// ルーム初期化時のイベント。ネットワークやデータストアのリスナー設定に利用
    /// </summary>
    public event Action<IRoom> OnRoomInitialized;

    private readonly List<string> _roomIdsToDelete = new List<string>();

    /// <summary>
    /// CreateNewRoom(string roomName, bool deleteRoomOnQuit)
    /// 新しいルームを作成します。deleteRoomOnQuitがtrueなら退出時にルームも削除します。
    /// </summary>
    /// <param name="roomName">Name of the Room to create. No need to be unique name.</param>
    /// <param name="deleteRoomOnQuit">Delete the room when quit or not</param>
    public virtual void CreateNewRoom(string roomName, bool deleteRoomOnQuit = false)
    {
        var roomParams = new RoomParams(
            _roomCapacity,
            roomName,
            _roomDescription
        );

        // TODO: For now, room from CreateRoom() cannot be found in GetOrCreate
        var status = RoomManagementService.CreateRoom(roomParams, out var room);
        if (status != RoomManagementServiceStatus.Ok)
        {
            Debug.LogWarning($"Error in join room by name {roomName}, {status}");
            return;
        }
        Debug.Log($"ROOMID:{room.RoomParams.RoomID}");

        if (deleteRoomOnQuit)
        {
            _roomIdsToDelete.Add(room.RoomParams.RoomID);
        }

        Room = room;
        Room.Initialize();
        PostRoomInitialization();
        OnRoomInitialized?.Invoke(Room);
    }

    /// <summary>
    /// JoinRoomById(string roomId)
    /// 指定したRoomIDのルームに参加します。
    /// </summary>
    /// <param name="roomId">Room ID string</param>
    public virtual void JoinRoomById(string roomId)
    {
        var status = RoomManagementService.GetRoom(roomId, out var room);
        if (status != RoomManagementServiceStatus.Ok)
        {
            Debug.LogWarning($"Error in join room by id {roomId}, {status}");
            return;
        }
        Debug.Log($"ROOMID:{room.RoomParams.RoomID}");
        Room = room;
        Room.Initialize();
        PostRoomInitialization();
        OnRoomInitialized?.Invoke(Room);
    }
    
    /// <summary>
    /// JoinRoomByName(string name)
    /// 指定した名前のルームに参加（なければ作成）します。
    /// </summary>
    /// <param name="name">参加または作成するルームの名前</param>
    public virtual void JoinRoomByName(string name)
    {
        var roomParams = new RoomParams(
            _roomCapacity,
            name,
            _roomDescription
        );
        var status = RoomManagementService.GetOrCreateRoomForName(roomParams, out var room);
            //RoomManagementService.GetRoom(roomId, out var room);
        if (status != RoomManagementServiceStatus.Ok)
        {
            Debug.LogWarning($"Error in join room by id {room?.RoomParams.RoomID}, {status}");
            return;
        }
        Debug.Log($"ROOMID:{room?.RoomParams.RoomID}");
        Room = room;
        Room.Initialize();
        PostRoomInitialization();
        OnRoomInitialized?.Invoke(Room);
    }

    /// <summary>
    /// LeaveRoom()
    /// ルームから退出し、必要に応じてルームを削除します。
    /// </summary>
    public void LeaveRoom()
    {
        // No guarantee that network requests will succeed before shutdown
        // This is best effort for now, needs to be explicitly cleaned before shutdown for
        //  better reliability
        Room?.Leave();

        // TODO: check if no one else in the room before deleting it
        foreach (var roomId in _roomIdsToDelete)
        {
            var res = RoomManagementService.DeleteRoom(roomId);
            if (res != RoomManagementServiceStatus.Ok)
            {
                Debug.LogWarning($"Failed to delete room {roomId} with status {res}");
            }
            else
            {
                Debug.Log($"Deleted room: {roomId}");
            }
        }
    }

    /// <summary>
    /// OnDestroy()
    /// オブジェクト破棄時にルームから退出します。
    /// </summary>
    protected void OnDestroy()
    {
        LeaveRoom();
    }
    
    /// <summary>
    /// PostRoomInitialization()
    /// ルーム初期化後の追加処理（このクラスでは未実装）
    /// </summary>
    protected virtual void PostRoomInitialization(){}
}
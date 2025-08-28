// based on: Assets\Samples\OnDevicePersistence\Scripts\DataStoreManager.cs

using System;
using System.Text;
using Niantic.Lightship.SharedAR.Datastore;
using Niantic.Lightship.SharedAR.Networking;
using UnityEngine;

/// <summary>
/// DatastoreManagerTCT
/// このクラスは、データストアへのオブジェクト保存・同期・削除などを管理し、全クライアント間でデータを共有します。
/// </summary>
public class DatastoreManagerTCT : MonoBehaviour
{
    //struct to hold data we we want to store
    public struct ObjectData
    {
        public Vector3 _position;
        public Color _color;
        public byte[] _data;
    };
    
    [Header("Managers")]
    [SerializeField]
    private RoomManagerTCT _roomManager;

    [SerializeField]
    private TrackerTCT _tracker;
    
    [SerializeField]
    private MapperTCT _mapper;
    
    private IDatastore _datastore;
    private INetworking _network;
    
    public bool _networkRunning;
    private bool _inRoom=false;
    
    private bool _sendNewMap=false;
    private bool _waitForMap=false;

    private Transform _tempRoot = null;
    
    /// <summary>
    /// CreateOrJoinDataStore(string storeName)
    /// 指定した名前のデータストア（ルーム）を作成または参加し、ネットワーク・データストアの初期化とイベント登録を行います。
    /// </summary>
    /// <param name="storeName"></param>
    public void CreateOrJoinDataStore(string storeName)
    {
        //am i already in the room
        if (_inRoom == true)
            return;
        
        _inRoom = true;
        
        //make a new room
        _roomManager.JoinRoomByName(storeName);

        if (_roomManager.Room == null)
            Debug.Log( "Network not found, do you have internet? and is your api key set");
        
        //cache datastore & network for easy access.
        _datastore = _roomManager.Room.Datastore;
        _network = _roomManager.Room.Networking;
        
        //hook callbacks to manage the data store
        _datastore.DatastoreCallback += DatastoreUpdated;
        _network.NetworkEvent += NetworkUpdate;
        
        //start the network to enable messaging.
        _network.Join();
    }

    /// <summary>
    /// LeaveDataStore()
    /// データストア（ルーム）から退出し、イベント登録を解除します。
    /// </summary>
    public void LeaveDataStore()
    {
        _roomManager.LeaveRoom();
        _network?.Leave();
        
        if(_datastore != null)
            _datastore.DatastoreCallback -= DatastoreUpdated;
        
        if(_network != null)
            _network.NetworkEvent -= NetworkUpdate;
        
        _datastore = null;
        _network = null;
        _inRoom = false;
    }
    
    /// <summary>
    /// DatastoreUpdated(DatastoreCallbackArgs args)
    /// データストアの更新イベントを受け取り、ローカルオブジェクトの追加・削除・更新を行います。
    /// </summary>
    /// <param name="args"></param>
    private void DatastoreUpdated(DatastoreCallbackArgs args)
    {
        //as a simple way to identify the message type in the data store we are adding a prefix to the messages.
        //e.g. CUBE_ MAP_ this helps us know what type of object we are receiving a message about.
        if (!args.Key.StartsWith("MAP") && !args.Key.StartsWith("CUBE"))
            return;
        
        // newly added or changed
        if (args.OperationType == DatastoreOperationType.ServerChangeUpdated)
        {
            var dataAsString = Encoding.Unicode.GetString(args.Value);
            var objectData = JsonUtility.FromJson<ObjectData>(dataAsString);
            
            //is this a the map?
            if (args.Key.StartsWith("MAP"))
            {
                //load this map
                _tracker.LoadMap(objectData._data);
            }
            else
            {
                // Debug.Log($"Key:{args.Key} Data:{dataAsString}");
                //do we already have this object?
                if (_tracker.Anchor.Find(args.Key))
                {
                    // object already exists as gameobject locally exists 
                    //if we had update logic it would go here.
                }
                else
                {
                    //object does not exist on this client so we make it.
                    CreateAndPlaceCube(objectData._position, objectData._color, args.Key);
                }
            }
        }
        else if (args.OperationType == DatastoreOperationType.ServerChangeDeleted)
        {
            //an object has been deleted from the server so we need to clean up the client.
            //find the correct root.
            var anchor = _tracker.Anchor;
            if (_tracker.Anchor)
            {
                var ob = anchor.transform.Find(args.Key);
                if (ob)
                {
                    Destroy(ob.gameObject);
                }
            }
        }
    }

    /// <summary>
    /// NetworkUpdate(NetworkEventArgs obj)
    /// ネットワークイベント（接続・切断など）を受け取り、状態を管理します。
    /// </summary>
    /// <param name="obj"></param>
    private void NetworkUpdate(NetworkEventArgs obj)
    { 
        switch(obj.networkEvent)
        {
            case NetworkEvents.Connected:
                _networkRunning = true;
                break;
            case NetworkEvents.ArdkShutdown:
                _networkRunning = false;
            break;
        }
    }

    /// <summary>
    /// OnDestroy()
    /// オブジェクト破棄時にデータストアから退出します。
    /// </summary>
    private void OnDestroy()
    {
      LeaveDataStore();
    }
    
    /// <summary>
    /// CreateAndPlaceCube(Vector3 localPos, Color color, string name = "Cube")
    /// 指定位置・色・名前でキューブを生成し、アンカーの子として配置します。
    /// </summary>
    /// <param name="localPos"></param>
    /// <param name="color"></param>
    /// <param name="name"></param>
    /// <returns></returns>
    public GameObject CreateAndPlaceCube(Vector3 localPos, Color color, string name = "Cube")
    {
        var go = GameObject.CreatePrimitive(PrimitiveType.Cube);
        go.name = name;
        go.GetComponent<Renderer>().material.color = color;
        
        //add it under the anchor on our map.
        _tracker.AddObjectToAnchor(go);
        go.transform.localPosition = localPos;
        //make it smaller.
        go.transform.localScale = new Vector3(0.2f,0.2f,0.2f);
        return go;
    }

    /// <summary>
    /// PlaceCube()
    /// カメラ前方2mにキューブを配置し、データストアに保存します。
    /// </summary>
    public void PlaceCube()
    {
        //place a cube 2m in front of the camera.
        var pos = Camera.main.transform.position + (Camera.main.transform.forward*2.0f);
        
        //each cube will have a unique name so you can update or delete them on the data store.
        var cubeName = "CUBE_" +  Guid.NewGuid().ToString();
        
        //randomise cube color for each peer
        var color = Color.magenta;
        if (_inRoom)
        {
            Color []colors =
            {
                Color.red,
                Color.green,
                Color.blue,
                Color.black,
                Color.grey, 
                Color.cyan,
                Color.white,
                Color.yellow
            };
            //will pick a color based on your network id.
            int code = Math.Abs(_network.SelfPeerID.GetHashCode());
            code = code % (colors.Length-1);
            color = colors[code];
        }
        
        //place a cube in the scene
        var go = CreateAndPlaceCube(_tracker.GetAnchorRelativePosition(pos),color, cubeName);
        
        //store it in the data store.
        DatastoreManagerTCT.ObjectData objectData = new DatastoreManagerTCT.ObjectData();
        objectData._position = go.transform.localPosition;
        objectData._color = color;
        
        //turn it into bytes and send it datastore.
        string json = JsonUtility.ToJson(objectData);
        Debug.Log($"json : {json}");
        _datastore.SetData(1, cubeName,Encoding.Unicode.GetBytes(json));
    }
    
    /// <summary>
    /// DeleteCubes()
    /// データストアおよびシーン上の全キューブを削除します。
    /// </summary>
    public void DeleteCubes()
    {
        //delete from in game.
        if (_tracker.Anchor)
        {
            for (int i = 0; i < _tracker.Anchor.transform.childCount; i++)
            {
                Destroy(_tracker.Anchor.transform.GetChild(i).gameObject);
                _datastore.DeleteData(3, _tracker.Anchor.transform.GetChild(i).name);
            }
        }
    }

    /// <summary>
    /// SaveMapToDatastore()
    /// 現在のマップデータをデータストアに保存します。
    /// </summary>
    public void SaveMapToDatastore()
    {
        ObjectData objectData = new ObjectData();
        objectData._data = _mapper.GetMap().Serialize();

        string json = JsonUtility.ToJson(objectData);
        _datastore.SetData(2, "MAP_DeviceMap", Encoding.Unicode.GetBytes(json));
    }
}

using UnityEngine;

namespace FlutterUnityPlugin.Runtime
{
    [DefaultExecutionOrder(int.MaxValue)]
    public class FlutterMessageReceiver : MonoBehaviour
    {
        public delegate void MessageFromFlutterHandler(Message message);

        public MessageFromFlutterHandler OnMessageFromFlutter { get; set; } = default;

        private static FlutterMessageReceiver _instance;

        public static FlutterMessageReceiver Instance
        {
            get
            {
                if (_instance != null) return _instance;

                _instance = FindObjectOfType<FlutterMessageReceiver>();

                if (_instance != null) return _instance;

                _instance = new GameObject("FlutterMessageReceiver").AddComponent<FlutterMessageReceiver>();
                DontDestroyOnLoad(_instance);

                return _instance;
            }
        }

        private void Awake()
        {
            if (Instance != null && Instance != this)
            {
                DestroyImmediate(this);
            }
        }

        /// <summary>
        /// This method is called from Flutter
        /// </summary>
        /// <param name="json"></param>
        public void OnReceive(string json)
        {
            var message = Message.FromJson(json);

            if (OnMessageFromFlutter.GetInvocationList().Length > 0)
            {
                OnMessageFromFlutter(message);
            }
        }
    }
}
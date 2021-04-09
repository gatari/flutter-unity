using UnityEngine;

namespace FlutterUnityPlugin.Runtime
{
    public class FlutterMessageManager : MonoBehaviour
    {
        public delegate void MessageFromFlutterHandler(Message message);

        public static MessageFromFlutterHandler OnMessageFromFlutter { get; set; } = default;
        
        /// <summary>
        /// This method is called from Flutter
        /// </summary>
        /// <param name="json"></param>
        public void OnMessage(string json)
        {
            var message = Message.FromJson(json);
            
            if (OnMessageFromFlutter.GetInvocationList().Length > 0)
            {
                OnMessageFromFlutter(message);
            }
        }
    }
}
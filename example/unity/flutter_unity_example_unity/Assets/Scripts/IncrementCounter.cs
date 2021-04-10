using FlutterUnityPlugin.Runtime;
using TMPro;
using UnityEngine;

namespace UnityTemplateProjects
{
    public class IncrementCounter : MonoBehaviour
    {
        [SerializeField] private TMP_Text textMesh;
        private int _count = 0;
        
        private void Start()
        {
            FlutterMessageReceiver.Instance.OnMessageFromFlutter += OnMessageFromFlutter;
            textMesh.text = _count.ToString();
        }

        private void OnMessageFromFlutter(Message message)
        {
            if (message.data != "increment") return;
            _count++;
            textMesh.text = _count.ToString();
        }
    }
}
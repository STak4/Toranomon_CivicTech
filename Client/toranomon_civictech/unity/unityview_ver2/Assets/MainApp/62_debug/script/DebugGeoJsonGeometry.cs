using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DebugGeoJsonGeometry
{
    /// <summary>
    /// List<List<Vector3[]>> の各RingをDebugGeometry.MakeLineObjectFromListで描画
    /// </summary>
    public static void DrawLines(List<List<Vector3[]>> vectorList, string groupName = "VectorList", Material material = null, int addHeight = 0)
    {
        if (vectorList == null) return;

        for (int polyIdx = 0; polyIdx < vectorList.Count; polyIdx++)
        {
            var rings = vectorList[polyIdx];
            if (rings == null) continue;
            for (int ringIdx = 0; ringIdx < rings.Count; ringIdx++)
            {
                var vecs = new List<Vector3>();
                foreach (var v in rings[ringIdx]) vecs.Add(new Vector3(v.x, v.y + addHeight, v.z));
                DebugGeometry.MakeLineObjectFromList(vecs, $"{groupName}-poly{polyIdx}-ring{ringIdx}", material, false);
            }
        }
    }
}

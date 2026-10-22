// A stroked icon drawn from SVG path data on a 24x24 grid.
// Usage: IconSvg { path: Icons.power; color: "white"; size: 28 }

import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property string path: ""
    property color color: "white"
    property real size: 28
    property real strokeWidth: 2

    implicitWidth: size
    implicitHeight: size

    Shape {
        anchors.centerIn: parent
        width: 24
        height: 24
        scale: root.size / 24
        preferredRendererType: Shape.CurveRenderer // remove this line on Qt < 6.6

        ShapePath {
            strokeColor: root.color
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: root.path }
        }
    }
}

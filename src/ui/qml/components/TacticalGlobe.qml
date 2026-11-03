import QtQuick
import "WorldData.js" as WorldData
import ".."

Item {
    id: root

    property real homeLat: 50.45
    property real homeLon: 30.52
    property string homeCity: "Kyiv"
    property string homeCountry: "Ukraine"
    property string homeLabel: (homeCity ? homeCity.toUpperCase() : "KYIV") + (homeCountry ? (", " + (homeCountry === "Ukraine" ? "UA" : homeCountry.slice(0, 2).toUpperCase())) : "")

    property real targetLat: 41.26
    property real targetLon: -95.86
    property string targetCity: "Council Bluffs"
    property string targetCountry: "United States"
    property string targetLabel: (targetCity ? targetCity.toUpperCase() : "NODE") + (targetCountry ? (", " + (targetCountry === "United States" ? "US" : targetCountry.slice(0, 2).toUpperCase())) : "")
    property bool isConnected: false

    implicitWidth: 220
    implicitHeight: 248

    property real rotationAngle: 0
    property real pitchAngle: -12
    property real targetZoom: 1.0
    property real zoomLevel: 1.0
    Behavior on zoomLevel { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }

    property real pulseScale: 1.0
    property real packetProgress: 0.0

    property bool isGreen: (typeof appController !== "undefined" && appController) ? appController.globeGreenColor : true
    property bool isFilled: (typeof appController !== "undefined" && appController) ? appController.globeFilled : true
    property bool showTelemetry: true
    property bool showZoomControls: true
    property bool showBadges: true
    property bool showArc: true
    property bool active: true

    onActiveChanged: {
        if (!active) {
            autoRotAnim.stop();
            lockAnim.stop();
            pitchResetAnim.stop();
            zoomResetAnim.stop();
            resumeTimer.stop();
        } else {
            if (root.isConnected) {
                lockOnConnection();
            } else {
                startAutoRotation();
            }
            canvas.requestPaint();
        }
    }

    onIsGreenChanged: canvas.requestPaint()
    onIsFilledChanged: canvas.requestPaint()
    onShowBadgesChanged: canvas.requestPaint()
    onShowArcChanged: canvas.requestPaint()

    NumberAnimation {
        id: autoRotAnim
        target: root
        property: "rotationAngle"
        from: 0
        to: 360
        duration: 26000
        loops: Animation.Infinite
        running: false
    }

    ParallelAnimation {
        id: lockAnim
        NumberAnimation {
            id: lockRotAnim
            target: root
            property: "rotationAngle"
            duration: 950
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            id: lockPitchAnim
            target: root
            property: "pitchAngle"
            duration: 950
            easing.type: Easing.OutCubic
        }
    }

    function lockOnConnection() {
        if (!root.active || !root.isConnected) return;
        autoRotAnim.stop();

        var r = Math.PI / 180;
        var lat1 = root.homeLat * r;
        var lon1 = root.homeLon * r;
        var lat2 = root.targetLat * r;
        var lon2 = root.targetLon * r;

        var x1 = Math.cos(lat1) * Math.cos(lon1);
        var y1 = Math.cos(lat1) * Math.sin(lon1);
        var z1 = Math.sin(lat1);

        var x2 = Math.cos(lat2) * Math.cos(lon2);
        var y2 = Math.cos(lat2) * Math.sin(lon2);
        var z2 = Math.sin(lat2);

        var xm = (x1 + x2) / 2;
        var ym = (y1 + y2) / 2;
        var zm = (z1 + z2) / 2;

        var hyp = Math.sqrt(xm * xm + ym * ym);
        var midLat = Math.atan2(zm, hyp) / r;
        var midLon = Math.atan2(ym, xm) / r;

        var targetRot = ((-midLon) % 360 + 360) % 360;
        var targetPitch = Math.max(-28, Math.min(15, -midLat * 0.5));

        var currentRot = root.rotationAngle;
        var diff = (targetRot - (currentRot % 360)) % 360;
        if (diff > 180) diff -= 360;
        if (diff < -180) diff += 360;
        var destRot = currentRot + diff;

        lockRotAnim.from = currentRot;
        lockRotAnim.to = destRot;

        lockPitchAnim.from = root.pitchAngle;
        lockPitchAnim.to = targetPitch;

        lockAnim.start();
    }

    function startAutoRotation() {
        lockAnim.stop();
        if (!root.active || root.isConnected) return;
        pitchResetAnim.start();
        var currentMod = ((root.rotationAngle % 360) + 360) % 360;
        root.rotationAngle = currentMod;
        autoRotAnim.from = currentMod;
        autoRotAnim.to = currentMod + 360;
        autoRotAnim.duration = 26000;
        autoRotAnim.start();
    }

    Component.onCompleted: {
        if (root.isConnected) {
            lockOnConnection();
        } else {
            startAutoRotation();
        }
    }

    Timer {
        id: resumeTimer
        interval: 3500
        onTriggered: {
            if (root.isConnected) {
                lockOnConnection();
            } else {
                startAutoRotation();
            }
        }
    }

    NumberAnimation {
        id: pitchResetAnim
        target: root
        property: "pitchAngle"
        to: -12
        duration: 750
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: zoomResetAnim
        target: root
        property: "targetZoom"
        to: 1.0
        duration: 350
        easing.type: Easing.OutQuad
    }

    SequentialAnimation on pulseScale {
        loops: Animation.Infinite
        running: root.active && root.showBadges
        NumberAnimation { from: 1.0; to: 2.2; duration: 1600; easing.type: Easing.OutQuad }
        NumberAnimation { from: 2.2; to: 1.0; duration: 0 }
    }

    NumberAnimation on packetProgress {
        from: 0.0
        to: 1.0
        duration: 1600
        loops: Animation.Infinite
        running: root.active && root.isConnected && root.showArc
    }

    Timer {
        id: renderTimer
        interval: 33
        running: root.active && (autoRotAnim.running || lockAnim.running || root.isConnected || globeMouse.pressed || pitchResetAnim.running || zoomResetAnim.running)
        repeat: true
        onTriggered: canvas.requestPaint()
    }

    onZoomLevelChanged: canvas.requestPaint()
    onTargetZoomChanged: root.zoomLevel = root.targetZoom
    onHomeLatChanged: {
        canvas.requestPaint();
        if (root.isConnected) lockOnConnection();
    }
    onHomeLonChanged: {
        canvas.requestPaint();
        if (root.isConnected) lockOnConnection();
    }
    onHomeLabelChanged: canvas.requestPaint()
    onTargetLatChanged: {
        canvas.requestPaint();
        if (root.isConnected) lockOnConnection();
    }
    onTargetLonChanged: {
        canvas.requestPaint();
        if (root.isConnected) lockOnConnection();
    }
    onTargetLabelChanged: canvas.requestPaint()
    onIsConnectedChanged: {
        canvas.requestPaint();
        if (root.isConnected) {
            lockOnConnection();
        } else {
            startAutoRotation();
        }
    }

    Item {
        id: globeContainer
        width: Math.min(parent.width, parent.height - (root.showTelemetry ? 28 : 0))
        height: width
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        Canvas {
            id: canvas
            anchors.fill: parent
            antialiasing: true
            renderTarget: Canvas.FramebufferObject

            readonly property var precomputedOcean: {
                var pts = WorldData.oceanPoints;
                var len = pts.length;
                var out = new Array(len);
                var rad = Math.PI / 180;
                for (var i = 0; i < len; ++i) {
                    var p = pts[i];
                    var latR = p[0] * rad;
                    out[i] = {
                        cosLat: Math.cos(latR),
                        sinLat: Math.sin(latR),
                        lonRad: p[1] * rad
                    };
                }
                return out;
            }

            readonly property var precomputedCoastlines: {
                var raw = WorldData.coastlines;
                var pCount = raw.length;
                var out = new Array(pCount);
                var rad = Math.PI / 180;
                for (var c = 0; c < pCount; ++c) {
                    var poly = raw[c];
                    var pLen = poly.length;
                    var polyOut = new Array(pLen);
                    for (var k = 0; k < pLen; ++k) {
                        var pt = poly[k];
                        var latR = pt[0] * rad;
                        polyOut[k] = {
                            cosLat: Math.cos(latR),
                            sinLat: Math.sin(latR),
                            lonRad: pt[1] * rad
                        };
                    }
                    out[c] = polyOut;
                }
                return out;
            }

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                var cx = width / 2;
                var cy = height / 2;
                var baseRadius = Math.min(cx, cy) - 14;
                if (baseRadius <= 0) return;

                var effectiveRadius = baseRadius * root.zoomLevel;

                var rad = Math.PI / 180;
                var rot = root.rotationAngle * rad;
                var pitch = root.pitchAngle * rad;
                var cosPitch = Math.cos(pitch);
                var sinPitch = Math.sin(pitch);

                ctx.strokeStyle = "#222222";
                ctx.lineWidth = 1;
                ctx.beginPath();
                ctx.arc(cx, cy, baseRadius, 0, Math.PI * 2);
                ctx.stroke();

                ctx.strokeStyle = "#383838";
                ctx.beginPath();
                ctx.moveTo(cx, cy - baseRadius - 4); ctx.lineTo(cx, cy - baseRadius + 2);
                ctx.moveTo(cx, cy + baseRadius - 2); ctx.lineTo(cx, cy + baseRadius + 4);
                ctx.moveTo(cx - baseRadius - 4, cy); ctx.lineTo(cx - baseRadius + 2, cy);
                ctx.moveTo(cx + baseRadius - 2, cy); ctx.lineTo(cx + baseRadius + 4, cy);
                ctx.stroke();

                if (root.zoomLevel > 1.2) {
                    ctx.strokeStyle = "rgba(255, 255, 255, 0.05)";
                    ctx.lineWidth = 1;
                    ctx.beginPath();
                    ctx.arc(cx, cy, baseRadius * 0.5, 0, Math.PI * 2);
                    ctx.stroke();
                }

                ctx.save();
                ctx.beginPath();
                ctx.arc(cx, cy, baseRadius - 0.5, 0, Math.PI * 2);
                ctx.clip();

                ctx.fillStyle = root.isConnected ? "rgba(255, 255, 255, 0.22)" : "rgba(255, 255, 255, 0.12)";
                var dotSize = 1.8;
                var halfDot = dotSize / 2;
                var baseRadSq = baseRadius * baseRadius;

                var oList = canvas.precomputedOcean;
                var oCount = oList.length;
                ctx.beginPath();
                for (var o = 0; o < oCount; ++o) {
                    var opt = oList[o];
                    var olon = opt.lonRad + rot;

                    var ox1 = effectiveRadius * opt.cosLat * Math.sin(olon);
                    var oy1 = -effectiveRadius * opt.sinLat;
                    var oz1 = effectiveRadius * opt.cosLat * Math.cos(olon);

                    var oy2 = oy1 * cosPitch - oz1 * sinPitch;
                    var oz2 = oy1 * sinPitch + oz1 * cosPitch;

                    if (oz2 > 0) {
                        if (ox1 * ox1 + oy2 * oy2 <= baseRadSq) {
                            ctx.rect(cx + ox1 - halfDot, cy + oy2 - halfDot, dotSize, dotSize);
                        }
                    }
                }
                ctx.fill();

                var landFill = root.isGreen ? (root.isConnected ? "#CCFF00" : "#446600") : (root.isConnected ? "#FFFFFF" : "#555555");
                var landStroke = root.isGreen ? (root.isConnected ? "#CCFF00" : "#557700") : (root.isConnected ? "#FFFFFF" : "#777777");

                ctx.fillStyle = landFill;
                ctx.strokeStyle = landStroke;
                ctx.lineWidth = root.isFilled ? 1.0 : (root.isConnected ? 1.2 : 1.0);

                var cList = canvas.precomputedCoastlines;
                var cCount = cList.length;
                for (var c = 0; c < cCount; ++c) {
                    var seg = cList[c];
                    var segLen = seg.length;
                    if (segLen < 2) continue;

                    var prevX = 0, prevY = 0, prevZ = 0;
                    var hasPrev = false;
                    var firstPointDrawn = false;
                    var lastExitAngle = 0;
                    var hasExit = false;
                    var firstEntryAngle = 0;
                    var hasFirstEntry = false;

                    ctx.beginPath();

                    for (var k = 0; k < segLen; ++k) {
                        var cpt = seg[k];
                        var clon = cpt.lonRad + rot;

                        var cx1 = effectiveRadius * cpt.cosLat * Math.sin(clon);
                        var cy1 = -effectiveRadius * cpt.sinLat;
                        var cz1 = effectiveRadius * cpt.cosLat * Math.cos(clon);

                        var cy2 = cy1 * cosPitch - cz1 * sinPitch;
                        var cz2 = cy1 * sinPitch + cz1 * cosPitch;

                        var curX = cx1;
                        var curY = cy2;
                        var curZ = cz2;

                        if (hasPrev) {
                            if (prevZ > 0 && curZ > 0) {
                                ctx.lineTo(cx + curX, cy + curY);
                            } else if (prevZ > 0 && curZ <= 0) {

                                var tOut = prevZ / (prevZ - curZ);
                                var hxOut = prevX + tOut * (curX - prevX);
                                var hyOut = prevY + tOut * (curY - prevY);
                                ctx.lineTo(cx + hxOut, cy + hyOut);
                                lastExitAngle = Math.atan2(hyOut, hxOut);
                                hasExit = true;
                            } else if (prevZ <= 0 && curZ > 0) {

                                var tIn = -prevZ / (curZ - prevZ);
                                var hxIn = prevX + tIn * (curX - prevX);
                                var hyIn = prevY + tIn * (curY - prevY);
                                var enterAngle = Math.atan2(hyIn, hxIn);

                                if (!hasFirstEntry) {
                                    firstEntryAngle = enterAngle;
                                    hasFirstEntry = true;
                                }

                                if (hasExit) {
                                    var diff = enterAngle - lastExitAngle;
                                    while (diff < -Math.PI) diff += Math.PI * 2;
                                    while (diff > Math.PI) diff -= Math.PI * 2;
                                    ctx.arc(cx, cy, effectiveRadius, lastExitAngle, enterAngle, diff < 0);
                                    hasExit = false;
                                } else {
                                    ctx.moveTo(cx + hxIn, cy + hyIn);
                                }
                                ctx.lineTo(cx + curX, cy + curY);
                                firstPointDrawn = true;
                            }
                        } else {
                            if (curZ > 0) {
                                ctx.moveTo(cx + curX, cy + curY);
                                firstPointDrawn = true;
                            }
                        }

                        prevX = curX;
                        prevY = curY;
                        prevZ = curZ;
                        hasPrev = true;
                    }

                    if (hasExit && hasFirstEntry) {
                        var finalDiff = firstEntryAngle - lastExitAngle;
                        while (finalDiff < -Math.PI) finalDiff += Math.PI * 2;
                        while (finalDiff > Math.PI) finalDiff -= Math.PI * 2;
                        ctx.arc(cx, cy, effectiveRadius, lastExitAngle, firstEntryAngle, finalDiff < 0);
                    }

                    if (firstPointDrawn || hasFirstEntry) {
                        ctx.closePath();
                        if (root.isFilled) {
                            ctx.fill();
                        }
                        ctx.stroke();
                    }
                }

                var hLat = root.homeLat * rad;
                var hLon = root.homeLon * rad;
                var sLat = root.targetLat * rad;
                var sLon = root.targetLon * rad;

                var v1x = Math.cos(hLat) * Math.sin(hLon);
                var v1y = -Math.sin(hLat);
                var v1z = Math.cos(hLat) * Math.cos(hLon);

                var v2x = Math.cos(sLat) * Math.sin(sLon);
                var v2y = -Math.sin(sLat);
                var v2z = Math.cos(sLat) * Math.cos(sLon);

                var dot = Math.max(-1.0, Math.min(1.0, v1x*v2x + v1y*v2y + v1z*v2z));
                var omega = Math.acos(dot);
                var sinOmega = Math.sin(omega);

                var arcSteps = 16;
                var cosRot = Math.cos(rot);
                var sinRot = Math.sin(rot);

                if (root.showArc && sinOmega > 1e-4) {
                    ctx.beginPath();
                    var firstPoint = true;

                    for (var s = 0; s <= arcSteps; ++s) {
                        var t = s / arcSteps;
                        var w1 = Math.sin((1 - t) * omega) / sinOmega;
                        var w2 = Math.sin(t * omega) / sinOmega;

                        var vx = w1 * v1x + w2 * v2x;
                        var vy = w1 * v1y + w2 * v2y;
                        var vz = w1 * v1z + w2 * v2z;

                        var mag = Math.sqrt(vx*vx + vy*vy + vz*vz);
                        var lift = 1.0 + 0.12 * Math.sin(t * Math.PI);
                        var rCur = effectiveRadius * lift;

                        var nx = (vx / mag) * rCur;
                        var ny = (vy / mag) * rCur;
                        var nz = (vz / mag) * rCur;

                        var rx = nx * cosRot + nz * sinRot;
                        var ry = ny;
                        var rz = -nx * sinRot + nz * cosRot;

                        var ry2 = ry * cosPitch - rz * sinPitch;
                        var rz2 = ry * sinPitch + rz * cosPitch;

                        if (rz2 > 0) {
                            var px = cx + rx;
                            var py = cy + ry2;
                            if (firstPoint) {
                                ctx.moveTo(px, py);
                                firstPoint = false;
                            } else {
                                ctx.lineTo(px, py);
                            }
                        } else {
                            firstPoint = true;
                        }
                    }

                    var arcColor = root.isGreen ?
                        (root.isConnected ? "rgba(255, 255, 255, 0.9)" : "rgba(255, 255, 255, 0.3)") :
                        (root.isConnected ? "rgba(204, 255, 0, 0.9)" : "rgba(204, 255, 0, 0.3)");
                    ctx.strokeStyle = arcColor;
                    ctx.lineWidth = root.isConnected ? 1.5 : 1.0;
                    ctx.stroke();

                    if (root.isConnected) {
                        var ptT = root.packetProgress;
                        var pw1 = Math.sin((1 - ptT) * omega) / sinOmega;
                        var pw2 = Math.sin(ptT * omega) / sinOmega;

                        var pvx = pw1 * v1x + pw2 * v2x;
                        var pvy = pw1 * v1y + pw2 * v2y;
                        var pvz = pw1 * v1z + pw2 * v2z;

                        var pMag = Math.sqrt(pvx*pvx + pvy*pvy + pvz*pvz);
                        var pLift = 1.0 + 0.12 * Math.sin(ptT * Math.PI);
                        var prCur = effectiveRadius * pLift;

                        var pnx = (pvx / pMag) * prCur;
                        var pny = (pvy / pMag) * prCur;
                        var pnz = (pvz / pMag) * prCur;

                        var prx = pnx * cosRot + pnz * sinRot;
                        var pry = pny;
                        var prz = -pnx * sinRot + pnz * cosRot;

                        var pry2 = pry * cosPitch - prz * sinPitch;
                        var prz2 = pry * sinPitch + prz * cosPitch;

                        if (prz2 > 0) {
                            ctx.fillStyle = "#CCFF00";
                            ctx.fillRect(cx + prx - 2, cy + pry2 - 2, 4, 4);
                        }
                    }
                }

                ctx.restore();

                if (root.showBadges) {

                var hCosLat = Math.cos(hLat);
                var hRotLon = hLon + rot;
                var hx = effectiveRadius * hCosLat * Math.sin(hRotLon);
                var hy = -effectiveRadius * Math.sin(hLat);
                var hz = effectiveRadius * hCosLat * Math.cos(hRotLon);
                var hy2 = hy * cosPitch - hz * sinPitch;
                var hz2 = hy * sinPitch + hz * cosPitch;
                var hpx = cx + hx;
                var hpy = cy + hy2;
                var hDist = Math.sqrt(hx * hx + hy2 * hy2);
                var hVisible = (hz2 > 0) && (hDist <= baseRadius + 18);

                var sCosLat = Math.cos(sLat);
                var sRotLon = sLon + rot;
                var sx = effectiveRadius * sCosLat * Math.sin(sRotLon);
                var sy = -effectiveRadius * Math.sin(sLat);
                var sz = effectiveRadius * sCosLat * Math.cos(sRotLon);
                var sy2 = sy * cosPitch - sz * sinPitch;
                var sz2 = sy * sinPitch + sz * cosPitch;
                var spx = cx + sx;
                var spy = cy + sy2;
                var sDist = Math.sqrt(sx * sx + sy2 * sy2);
                var sVisible = (sz2 > 0) && (sDist <= baseRadius + 18);

                if (hVisible) {
                    ctx.strokeStyle = "#FFFFFF";
                    ctx.lineWidth = 1;
                    ctx.beginPath();
                    ctx.moveTo(hpx - 6, hpy); ctx.lineTo(hpx + 6, hpy);
                    ctx.moveTo(hpx, hpy - 6); ctx.lineTo(hpx, hpy + 6);
                    ctx.stroke();

                    ctx.strokeRect(hpx - 3, hpy - 3, 6, 6);
                    ctx.fillStyle = "#FFFFFF";
                    ctx.fillRect(hpx - 1.5, hpy - 1.5, 3, 3);
                }

                if (sVisible) {
                    var rSize = 8 * root.pulseScale;
                    ctx.strokeStyle = "#CCFF00";
                    ctx.lineWidth = 1;
                    ctx.strokeRect(spx - rSize/2, spy - rSize/2, rSize, rSize);

                    ctx.beginPath();
                    ctx.moveTo(spx - 6, spy); ctx.lineTo(spx + 6, spy);
                    ctx.moveTo(spx, spy - 6); ctx.lineTo(spx, spy + 6);
                    ctx.stroke();

                    ctx.fillStyle = "#CCFF00";
                    ctx.fillRect(spx - 2, spy - 2, 4, 4);
                }

                ctx.font = "bold 9px Monospace";

                var hText = "▲ YOU: " + root.homeLabel;
                var hbw = ctx.measureText(hText).width + 8;
                var hbh = 15;
                var hToLeft = (hpx > cx);
                var hbx = hToLeft ? (hpx - hbw - 10) : (hpx + 10);
                hbx = Math.max(4, Math.min(width - hbw - 4, hbx));
                var hby = Math.max(4, Math.min(height - hbh - 4, hpy - hbh / 2));

                var sText = "■ " + root.targetLabel;
                var sbw = ctx.measureText(sText).width + 8;
                var sbh = 15;
                var sToLeft = (spx > cx);
                var sbx = sToLeft ? (spx - sbw - 10) : (spx + 10);
                sbx = Math.max(4, Math.min(width - sbw - 4, sbx));
                var sby = Math.max(4, Math.min(height - sbh - 4, spy - sbh / 2));

                if (hVisible && sVisible) {
                    var xOverlap = (hbx < sbx + sbw + 6) && (hbx + hbw + 6 > sbx);
                    var yOverlap = (hby < sby + sbh + 4) && (hby + hbh + 4 > sby);

                    if (xOverlap && yOverlap) {

                        if (hpx < spx) {
                            hToLeft = true;
                            hbx = Math.max(4, hpx - hbw - 10);
                            sToLeft = false;
                            sbx = Math.min(width - sbw - 4, spx + 10);
                        } else {
                            sToLeft = true;
                            sbx = Math.max(4, spx - sbw - 10);
                            hToLeft = false;
                            hbx = Math.min(width - hbw - 4, hpx + 10);
                        }

                        var stillXOverlap = (hbx < sbx + sbw + 6) && (hbx + hbw + 6 > sbx);
                        if (stillXOverlap) {

                            var spacing = 4;
                            if (hpy <= spy) {
                                hby = Math.max(4, hpy - hbh - 6);
                                sby = Math.min(height - sbh - 4, hby + hbh + spacing);
                            } else {
                                sby = Math.max(4, spy - sbh - 6);
                                hby = Math.min(height - hbh - 4, sby + sbh + spacing);
                            }
                        }
                    }
                }

                if (hVisible) {
                    ctx.strokeStyle = "#FFFFFF";
                    ctx.lineWidth = 1;
                    ctx.beginPath();
                    ctx.moveTo(hpx, hpy);
                    ctx.lineTo(hToLeft ? (hbx + hbw) : hbx, hby + hbh / 2);
                    ctx.stroke();

                    ctx.fillStyle = "#FFFFFF";
                    ctx.fillRect(hbx, hby, hbw, hbh);

                    ctx.fillStyle = "#000000";
                    ctx.textAlign = "left";
                    ctx.fillText(hText, hbx + 4, hby + 11);
                }

                if (sVisible) {
                    ctx.strokeStyle = "#CCFF00";
                    ctx.lineWidth = 1;
                    ctx.beginPath();
                    ctx.moveTo(spx, spy);
                    ctx.lineTo(sToLeft ? (sbx + sbw) : sbx, sby + sbh / 2);
                    ctx.stroke();

                    ctx.fillStyle = "#CCFF00";
                    ctx.fillRect(sbx, sby, sbw, sbh);
                    ctx.strokeStyle = "#000000";
                    ctx.lineWidth = 1;
                    ctx.strokeRect(sbx, sby, sbw, sbh);

                    ctx.fillStyle = "#000000";
                    ctx.textAlign = "left";
                    ctx.fillText(sText, sbx + 4, sby + 11);
                }
            }
        }
        }

        MouseArea {
            id: globeMouse
            anchors.fill: parent
            hoverEnabled: true
            preventStealing: true
            cursorShape: pressed ? Qt.ClosedHandCursor : (containsMouse ? Qt.OpenHandCursor : Qt.ArrowCursor)

            property real lastX: 0
            property real lastY: 0

            onPressed: function(mouse) {
                lastX = mouse.x;
                lastY = mouse.y;
                autoRotAnim.stop();
                lockAnim.stop();
                pitchResetAnim.stop();
                resumeTimer.stop();
            }

            onPositionChanged: function(mouse) {
                if (pressed) {
                    var dx = mouse.x - lastX;
                    var dy = mouse.y - lastY;
                    lastX = mouse.x;
                    lastY = mouse.y;
                    root.rotationAngle += dx * 0.55;
                    var targetPitch = root.pitchAngle - dy * 0.45;
                    root.pitchAngle = Math.max(-55, Math.min(55, targetPitch));
                    canvas.requestPaint();
                }
            }

            onReleased: function() {
                resumeTimer.restart();
            }

            onCanceled: function() {
                resumeTimer.restart();
            }

            onWheel: function(wheel) {
                var step = wheel.angleDelta.y > 0 ? 0.25 : -0.25;
                root.targetZoom = Math.max(1.0, Math.min(3.5, root.targetZoom + step));
                wheel.accepted = true;
            }

            onDoubleClicked: {
                if (root.isConnected) {
                    lockOnConnection();
                } else {
                    pitchResetAnim.start();
                }
                zoomResetAnim.start();
            }
        }

        Column {
            visible: root.showZoomControls
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 4
            anchors.rightMargin: 4
            spacing: 3
            z: 10
            opacity: globeMouse.containsMouse || root.targetZoom > 1.0 ? 0.9 : 0.2
            Behavior on opacity { NumberAnimation { duration: 150 } }

            Rectangle {
                width: 18
                height: 18
                color: zoomInMouse.containsMouse ? "#2A2A2A" : "#121212"
                border.color: root.targetZoom >= 3.5 ? "#242424" : (zoomInMouse.containsMouse ? "#CCFF00" : "#383838")
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    font.pixelSize: 12
                    font.bold: true
                    font.family: Theme.fontMono
                    color: root.targetZoom >= 3.5 ? "#444444" : (zoomInMouse.containsMouse ? "#CCFF00" : "#FFFFFF")
                }

                MouseArea {
                    id: zoomInMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.targetZoom = Math.min(3.5, root.targetZoom + 0.35);
                    }
                }
            }

            Rectangle {
                width: 18
                height: 18
                color: zoomOutMouse.containsMouse ? "#2A2A2A" : "#121212"
                border.color: root.targetZoom <= 1.0 ? "#242424" : (zoomOutMouse.containsMouse ? "#CCFF00" : "#383838")
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "–"
                    font.pixelSize: 12
                    font.bold: true
                    font.family: Theme.fontMono
                    color: root.targetZoom <= 1.0 ? "#444444" : (zoomOutMouse.containsMouse ? "#CCFF00" : "#FFFFFF")
                }

                MouseArea {
                    id: zoomOutMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.targetZoom = Math.max(1.0, root.targetZoom - 0.35);
                    }
                }
            }
        }
    }

    Row {
        visible: root.showTelemetry
        anchors.top: globeContainer.bottom
        anchors.topMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 6
        opacity: globeMouse.containsMouse || globeMouse.pressed ? 1.0 : 0.35
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Text {
            text: {
                var yaw = Math.round(((root.rotationAngle % 360) + 360) % 360);
                var pit = (root.pitchAngle >= 0 ? "+" : "") + Math.round(root.pitchAngle);
                var zm = root.zoomLevel.toFixed(1) + "X";
                return globeMouse.pressed ? ("DRAG: " + yaw + "° / " + pit + "°  " + zm) : ("ROT " + yaw + "°  TILT " + pit + "°  ZOOM " + zm);
            }
            font.pixelSize: 10
            font.family: Theme.fontMono
            color: globeMouse.pressed ? "#CCFF00" : "#777777"
        }
    }
}

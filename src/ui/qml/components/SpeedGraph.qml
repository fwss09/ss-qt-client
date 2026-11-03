import QtQuick

Canvas {
    id: canvas

    property var historyData: []
    property color lineColor: "#FFFFFF"
    property color fillColorStart: "#25FFFFFF"
    property color fillColorEnd: "#00000000"

    antialiasing: true
    renderTarget: Canvas.FramebufferObject

    onHistoryDataChanged: {
        requestPaint()
    }

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        if (!historyData || historyData.length < 2) return;

        var count = historyData.length;
        var maxVal = 1024;
        for (var i = 0; i < count; ++i) {
            if (historyData[i] > maxVal) {
                maxVal = historyData[i];
            }
        }

        var stepX = width / (count - 1);
        var bottomY = height - 4;
        var topMargin = 8;
        var usableHeight = height - topMargin - 4;

        ctx.strokeStyle = "#1AFFFFFF";
        ctx.lineWidth = 1;
        ctx.beginPath();
        for (var g = 1; g <= 3; ++g) {
            var gridY = Math.round(bottomY - (g * 0.25 * usableHeight));
            ctx.moveTo(0, gridY);
            ctx.lineTo(width, gridY);
        }
        ctx.stroke();

        ctx.beginPath();
        ctx.moveTo(0, bottomY);

        for (var j = 0; j < count; ++j) {
            var val = historyData[j];
            var norm = val / maxVal;
            var x = j * stepX;
            var y = bottomY - (norm * usableHeight);
            ctx.lineTo(x, y);
        }

        ctx.lineTo(width, bottomY);
        ctx.closePath();

        var gradient = ctx.createLinearGradient(0, topMargin, 0, height);
        gradient.addColorStop(0.0, fillColorStart);
        gradient.addColorStop(1.0, fillColorEnd);
        ctx.fillStyle = gradient;
        ctx.fill();

        ctx.beginPath();
        for (var k = 0; k < count; ++k) {
            var valK = historyData[k];
            var normK = valK / maxVal;
            var xK = k * stepX;
            var yK = bottomY - (normK * usableHeight);
            if (k === 0) {
                ctx.moveTo(xK, yK);
            } else {
                ctx.lineTo(xK, yK);
            }
        }

        ctx.lineWidth = 1.5;
        ctx.strokeStyle = lineColor;
        ctx.stroke();
    }
}

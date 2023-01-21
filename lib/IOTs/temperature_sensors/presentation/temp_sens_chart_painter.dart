
import 'dart:ui';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:iots_manager/common/def_types.dart';
import 'package:iots_manager/IOTs/temperature_sensors/data/temp_sens_constants.dart';
import 'package:iots_manager/IOTs/temperature_sensors/data/repository/temp_sens_repository.dart';

class TempSensChartPainter extends CustomPainter {
  final TempSensRepository sensRepo;
  final ListElemIndex? iTouchedTimeStamp;

  TempSensChartPainter(this.sensRepo, this.iTouchedTimeStamp);

  @override
  void paint(Canvas canvas, Size size) {
    final fullW = size.width;
    final fullH = size.height;

    var paintBackRect = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, fullW, fullH), paintBackRect);

    if(sensRepo.chartRepo.chartDataSize > 0) {
      final double stepX = fullW / (CHART_NUM_POINTS-1);
      final offsetY = fullH * (1 + sensRepo.chartRepo.chartMinY /sensRepo.chartRepo.chartRangeY);
      final scaleY = fullH/sensRepo.chartRepo.chartRangeY;

      drawGridTimeCols (canvas, CHART_NUM_POINTS, stepX, fullW, fullH);
      drawGridChartsEdges (canvas, CHART_NUM_POINTS, stepX, offsetY, scaleY, fullW);
      drawCharts (canvas, CHART_NUM_POINTS, stepX, offsetY, scaleY);

      if(iTouchedTimeStamp != null) {
        final dX = stepX * iTouchedTimeStamp!;
        drawTouchPointer(canvas, iTouchedTimeStamp!, dX, offsetY, scaleY, fullH);
      }
    }
  }

  void drawTouchPointer(Canvas canvas, ListElemIndex iTS, double x, double offsetY, double scaleY, double fullH) {
    final paintPointerLine = Paint()
      ..color = Colors.white38
      ..strokeWidth = 2;

    final curTS = sensRepo.chartRepo.chartTimeStamps[iTS];
    const offset = Offset(0, 0);
    canvas.drawLine(offset.translate(x, 0), offset.translate(x, fullH), paintPointerLine);

    final List<Offset> controlPoints = <Offset>[];

    for(ListElemIndex iSens = 0; iSens < sensRepo.numSensors; iSens++) {
      final SplayTreeMap<TimeStamp, SensorValue> sensorData = sensRepo.chartRepo.getChartDataAt(iSens);
      final Color chartColor = CHART_COLORS[iSens];

      if(sensorData.containsKey(curTS)) {
        final valueTemp = sensorData[curTS]!;
        final y = offsetY - scaleY * valueTemp;
        controlPoints.add(Offset(x, y));

        final paintPointerPoints = Paint()
          ..color = chartColor
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.plus;

        canvas.drawPoints(PointMode.points, controlPoints, paintPointerPoints);

        final textStyle = TextStyle(
          color: chartColor,
          fontSize: 14,
        );
        TextSpan textSpan = TextSpan( text: "${valueTemp.toStringAsFixed(2)} ", style: textStyle,);
        TextPainter textPainter = TextPainter(textAlign: TextAlign.start, text: textSpan, textDirection: TextDirection.ltr,);
        textPainter.layout(minWidth: 0, maxWidth: fullH,);

        var paintBackRect = Paint()
          ..color = Colors.black45
          ..style = PaintingStyle.fill;

        final xL = x - textPainter.width/2;
        final yT = y - 1.5*textPainter.height;
        canvas.drawRect(Rect.fromLTWH(xL, yT, textPainter.width, textPainter.height), paintBackRect);
        textPainter.paint(canvas, offset.translate(x-textPainter.width/2, y - 1.5*textPainter.height));
        controlPoints.clear();
      }
    }
  }

  void drawGridChartsEdges(Canvas canvas, QuantityElements numPoints, double stepX, double offsetY, double scaleY, fullW) {
    const offset = Offset(0, 0);
    double y;

    for(ListElemIndex iSens = 0; iSens < sensRepo.numSensors; iSens++) {
      final Color chartColor = CHART_COLORS[iSens];
      SensorValue chartMinVal = double.infinity;
      SensorValue chartMaxVal = double.negativeInfinity;
      final SplayTreeMap<TimeStamp, SensorValue> sensorData = sensRepo.chartRepo.getChartDataAt(iSens);
      for(ListElemIndex iTS = 0; iTS < numPoints; iTS++) {
        final curTS = sensRepo.chartRepo.chartTimeStamps[iTS];
        if(sensorData.containsKey(curTS)) {
          final value = sensorData[curTS]!;
          if(chartMinVal > value) { chartMinVal = value; }
          if(chartMaxVal < value) { chartMaxVal = value; }
        }
      }
      final textStyle = TextStyle(
        color: chartColor,
        fontSize: 14,
      );
      final paintEdge = Paint()
        ..color = chartColor.withOpacity(0.7)
        ..strokeWidth = 0.5;

      y = offsetY - scaleY * chartMinVal;
      canvas.drawLine(offset.translate(0, y), offset.translate(fullW, y), paintEdge);

      TextSpan textSpan = TextSpan(text: "${chartMinVal.toStringAsFixed(2)} ", style: textStyle,);
      TextPainter textPainter = TextPainter(textAlign: TextAlign.start, text: textSpan, textDirection: TextDirection.ltr, );
      textPainter.layout(minWidth: 0, maxWidth: fullW,);
      textPainter.paint(canvas, offset.translate(- textPainter.width, y - textPainter.height/2));

      y = offsetY - scaleY * chartMaxVal;
      canvas.drawLine(offset.translate(0, y), offset.translate(fullW, y), paintEdge);

      textSpan = TextSpan(text: " ${chartMaxVal.toStringAsFixed(2)}", style: textStyle,);
      textPainter = TextPainter(textAlign: TextAlign.start, text: textSpan, textDirection: TextDirection.ltr, );
      textPainter.layout(minWidth: 0, maxWidth: fullW,);
      textPainter.paint(canvas, offset.translate(fullW, y - textPainter.height/2));
    }
  }

  void drawGridTimeCols(Canvas canvas, QuantityElements numPoints, double stepX, double fullW, double fullH) {
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
    );

    final paintGrid = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1;

    const offset = Offset(0, 0);

    // Columns
    for(ListElemIndex iTS = 1; iTS < numPoints-1; iTS++) {
      final TimeStamp curTS = sensRepo.chartRepo.chartTimeStamps[iTS];
      final dX = stepX * iTS;
      canvas.drawLine(offset.translate(dX, 0), offset.translate(dX, fullH), paintGrid);

      String strTime = sensRepo.timeStampToTime(curTS, iTS%2 == 1);
      final textSpan = TextSpan( text: strTime, style: textStyle,);

      final textPainter = TextPainter( textAlign: TextAlign.center, text: textSpan, textDirection: TextDirection.ltr, );
      textPainter.layout( minWidth: 0, maxWidth: fullW,);

      final yText = iTS%2 == 0? fullH: -textPainter.height;
      textPainter.paint(canvas, offset.translate(dX - textPainter.width/2, yText));
    }
  }

  void drawCharts(Canvas canvas, QuantityElements numPoints, double stepX, double offsetY, double scaleY) {
    for(ListElemIndex iSens = 0; iSens < sensRepo.numSensors; iSens++) {
      final SplayTreeMap<TimeStamp, SensorValue> sensorData = sensRepo.chartRepo.getChartDataAt(iSens);
      final Color chartColor = CHART_COLORS[iSens];

      /// This method generates control points, the x = 50*index(+1)
      /// the y is set to random values between half of the screen and bottom of the screen
      final List<Offset> controlPoints = <Offset>[];
      for(ListElemIndex iTS = 0; iTS < numPoints; iTS++) {
        final curTS = sensRepo.chartRepo.chartTimeStamps[iTS];

        if(sensorData.containsKey(curTS)) {
          final value = sensorData[curTS]!;
          controlPoints.add( Offset(stepX * iTS, offsetY - scaleY * value) );
        }
      }

      final bezierPaint = Paint()
      // set the edges of stroke to be rounded
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.5
        ..color = chartColor;

      if(controlPoints.length > 3) {
        final spline = CatmullRomSpline(controlPoints, tension: 0.0);
        // This method accepts a list of offsets and draws points for all offset
        canvas.drawPoints(
          PointMode.polygon,
          spline.generateSamples().map((e) => e.value).toList(),
          bezierPaint,
        );
      }

      if(controlPoints.length > 2) {
        final paintPoints = Paint()
          ..color = chartColor
          ..strokeWidth = 8
          ..blendMode = BlendMode.plus
          ..strokeCap = StrokeCap.round;

        controlPoints.removeAt(0);
        controlPoints.removeLast();

        canvas.drawPoints(PointMode.points, controlPoints, paintPoints);
      }
    }
  }

  @override
  bool shouldRepaint(TempSensChartPainter oldDelegate) {
    return oldDelegate.iTouchedTimeStamp != iTouchedTimeStamp;
  }
}

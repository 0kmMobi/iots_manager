
import 'package:iots_manager/IOTs/temperature_sensors/presentation/temp_sens_chart_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iots_manager/common/def_types.dart';
import 'package:iots_manager/IOTs/temperature_sensors/data/temp_sens_constants.dart';
import 'package:iots_manager/IOTs/temperature_sensors/data/repository/temp_sens_chart_repository.dart';

class TempSensChartWidget extends StatefulWidget {
  final bool hasChartData;

  const TempSensChartWidget({Key? key, required this.hasChartData}) : super(key: key);

  @override
  State<TempSensChartWidget> createState() => _TempSensChartWidgetState();
}

class _TempSensChartWidgetState extends State<TempSensChartWidget> {
  ListElemIndex? iTouchedTimeStamp;

  @override
  Widget build(BuildContext context) {
    final TempSensChartRepository chartRepo = RepositoryProvider.of<TempSensChartRepository>(context);
    if (widget.hasChartData) {
      return
          GestureDetector(
              child: CustomPaint(
                size: Size.infinite,
                painter: TempSensChartPainter(chartRepo, iTouchedTimeStamp),
              ),
              onPanStart: (details) { if(context.size != null) { setNewIndexTouchedTimeStamp(chartRepo, context.size!.width, details.localPosition.dx.toInt()); } },
              onPanEnd: (details) { if(iTouchedTimeStamp != null) { setState(() { iTouchedTimeStamp = null; }); } },
              onPanUpdate: (details) { if(context.size != null) { setNewIndexTouchedTimeStamp(chartRepo, context.size!.width, details.localPosition.dx.toInt()); } }
          );
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }

  void setNewIndexTouchedTimeStamp(TempSensChartRepository chartRepo, double contWidth, int touchX) {
    if(chartRepo.chartDataSize > 0) {
      final double stepX = contWidth / (CHART_NUM_POINTS-1);
      ListElemIndex iTS = (touchX / stepX).round();
      if(iTS >= CHART_NUM_POINTS) {
        iTS = CHART_NUM_POINTS-1;
      }
      else if(iTS < 0) {
        iTS = 0;
      }
      if(iTouchedTimeStamp == null || iTouchedTimeStamp != iTS) {
        setState(() {
          iTouchedTimeStamp = iTS;
        });
      }
    }
  }
}


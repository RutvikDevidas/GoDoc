import 'package:flutter/material.dart';

class DateTimeFmt {
  static String date(DateTime dt) =>
      "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";

  static String time(BuildContext context, DateTime dt) =>
      TimeOfDay(hour: dt.hour, minute: dt.minute).format(context);

  static String nice(BuildContext context, DateTime dt) =>
      "${date(dt)} • ${time(context, dt)}";
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlarmScreen extends StatefulWidget {
  final String time;
  final String label;

  const AlarmScreen({
    super.key,
    required this.time,
    required this.label,
  });

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  double _dragValue = 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // ⏰ TIME
            Text(
              widget.time,
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 8),

            // 📅 DATE
            Text(
              'Today',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),

            const SizedBox(height: 32),

            // 📝 LABEL
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white70,
              ),
            ),

            const Spacer(flex: 3),

            // 🎚 SLIDE TO STOP
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Center(
                      child: Text(
                        'Slide to stop',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 16,
                        ),
                      ),
                    ),

                    GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _dragValue += details.delta.dx;
                          _dragValue =
                              _dragValue.clamp(0, width - 120);
                        });
                      },
                      onHorizontalDragEnd: (_) {
                        if (_dragValue > width * 0.6) {
                          _onStop();
                        } else {
                          setState(() => _dragValue = 0);
                        }
                      },
                      child: Transform.translate(
                        offset: Offset(_dragValue, 0),
                        child: Container(
                          width: 56,
                          height: 56,
                          margin: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: const Icon(
                            Icons.chevron_right,
                            size: 32,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 😴 SNOOZE
            TextButton(
              onPressed: _onSnooze,
              child: Text(
                'Snooze',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 16,
                ),
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  void _onStop() {
    // acknowledgeAlarm(alarmId);
    // TODO: stop alarm sound + close screen
    Navigator.pop(context);
  }

  void _onSnooze() {
    // TODO: schedule snooze alarm
    Navigator.pop(context);
  }
}


Future<void> acknowledgeAlarm(String alarmId) async {
  await Supabase.instance.client
      .from('alarm_instances')
      .update({
    'status': 'acknowledged',
    'acknowledged_at': DateTime.now().toIso8601String(),
  })
      .eq('id', alarmId);
}





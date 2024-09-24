import 'package:flutter/material.dart';

void main() {
  runApp(StatusSliderApp());
}

class StatusSliderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Rental Status Slider'),
        ),
        body: StatusSliderScreen(),
      ),
    );
  }
}

class StatusSliderScreen extends StatefulWidget {
  @override
  _StatusSliderScreenState createState() => _StatusSliderScreenState();
}

class _StatusSliderScreenState extends State<StatusSliderScreen> {
  double _statusValue = 0.0; // 0.0 for Not Paid, 1.0 for Paid

  void _updateStatus(double value) {
    setState(() {
      _statusValue = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rental Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              // Slider with gradient background
              Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          Colors.redAccent.withOpacity(0.6),
                          Colors.green.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.transparent,
                      inactiveTrackColor: Colors.transparent,
                      thumbColor: _statusValue == 1.0 ? Colors.green : Colors.redAccent,
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 16.0),
                      trackHeight: 50,
                    ),
                    child: Slider(
                      value: _statusValue,
                      min: 0.0,
                      max: 1.0,
                      divisions: 1,
                      onChanged: _updateStatus,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // Display the current status
              Center(
                child: Text(
                  _statusValue == 1.0 ? "Paid" : "Not Paid",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _statusValue == 1.0 ? Colors.green : Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: file_names
import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String text = "Stop Service";

  @override
  void initState() {
    super.initState();
    initializeBgApp();
  }

  Future<void> initializeBgApp() async {
    try {
      // initialize the service
      final service = FlutterBackgroundService();
      await service.configure(
        iosConfiguration: IosConfiguration(
          onForeground: onStart,
        ),
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: true,
          isForegroundMode: true,
        ),
      );
    } catch (error) {
      log(error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StreamBuilder<Map<String, dynamic>?>(
          stream: FlutterBackgroundService().on('update'),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final data = snapshot.data!;
            int? count = data["count"];
            return Column(
              children: [
                Text(
                  'Count: ${count ?? 0}',
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Colors.red,
                      ),
                ),
              ],
            );
          },
        ),
        ElevatedButton(
          child: const Text("LOCATION"),
          onPressed: () async {
            // Fetch user location and update UI
            fetchUserLocation();
          },
        ),
        const SizedBox(
          height: 20,
        ),
        ElevatedButton(
          child: Text(text),
          onPressed: () async {
            final service = FlutterBackgroundService();
            var isRunning = await service.isRunning();
            if (isRunning) {
              service.invoke("stopService");
            } else {
              service.startService();
            }

            if (!isRunning) {
              text = 'Stop Service';
            } else {
              text = 'Start Service';
            }
            setState(() {});
          },
        ),
      ],
    );
  }
}

@pragma('vm:entry-point')
Future<void> onBackground() async {
  int localCount = 0;
  Timer.periodic(const Duration(seconds: 2), (timer) async {
    localCount += 1;
    log('Count: $localCount');

    FlutterBackgroundService().invoke(
      'update',
      {
        "count": localCount,
      },
    );
  });
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Call your onStart logic here
  ourServiceFunction(service);
}

void ourServiceFunction(ServiceInstance service) {
  int value = 0;
  // STARTING A COUNTDOWN TO CHECK HOW MANY SECONDS LEFT FOR THE NEXT CALL
  Timer.periodic(Duration(seconds: 1), (timer) {
    if (value == 0) {}

    print("${3 - value} ${value <= 1 ? "seconds" : "second"} left");
    value += 1;

    if (value == 3) {
      value = 0;
      fetchUserLocation();
    }
  });
}

// FOR LOCATION
Future<void> fetchUserLocation() async {
  try {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
    log("Location: ${position.latitude}, ${position.longitude}");
  } catch (e) {
    print("Error fetching location: $e");
  }
}

import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  static const notificationChannelId = 'my_foreground';
  static const notificationId = 888;
}

class _MyAppState extends State<MyApp> {
  String text = "Stop Service";

  @override
  void initState() {
    super.initState();
    initializeBgApp();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: Column(
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
      ),
    );
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
}

@pragma('vm:entry-point')
Future<void> onBackground() async {
  int localCount = 0;
  Timer.periodic(const Duration(seconds: 2), (timer) async {
    localCount += 1;
    print('Count: $localCount');

    FlutterBackgroundService().invoke(
      'update',
      {
        "count": localCount,
      },
    );
  });
}

void onStart(ServiceInstance service) async {
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // TODO: Call your location fetching logic here
  int value = 0;
  Timer.periodic(Duration(seconds: 5), (timer) {
    print("Tick $value");
    value += 1;
  });
}

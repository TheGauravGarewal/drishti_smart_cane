import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'blind_user_home_page.dart';
import 'companion_code_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(DrishtiApp());
}

class DrishtiApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drishti',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlutterTts tts = FlutterTts();

  final List<_DrishtiOption> options = [
    _DrishtiOption(
      label: 'Blind User',
      description: 'Use this if you are the cane user',
      iconPath: 'assets/blind.png',
    ),
    _DrishtiOption(
      label: 'Guardian / Companion',
      description: 'Monitor or guide your companion',
      iconPath: 'assets/guardian.png',
    ),
    _DrishtiOption(
      label: 'Settings',
      description: '',
      iconPath: 'assets/settings.png',
    ),
    _DrishtiOption(
      label: 'About',
      description: '',
      iconPath: 'assets/information.png',
    ),
  ];

  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _speak('Drishti');
  }

  Future _speak(String text) async {
    await tts.setLanguage('en-IN');
    await tts.speak(text);
  }

  void _onSwipeLeft() {
    setState(() {
      selectedIndex = (selectedIndex - 1 + options.length) % options.length;
    });
    _speak(options[selectedIndex].label);
  }

  void _onSwipeRight() {
    setState(() {
      selectedIndex = (selectedIndex + 1) % options.length;
    });
    _speak(options[selectedIndex].label);
  }

  void _onSwipeDown() {
    // No action on first page
  }

  void _onDoubleTap() {
    _speak('Selected ${options[selectedIndex].label}');
    if (selectedIndex == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BlindUserHomePage()),
      );
    } else if (selectedIndex == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CompanionCodePage()),
      );
    }
    // You can add navigation for Settings/About as needed later
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < 0) {
            _onSwipeLeft();
          } else if (details.primaryVelocity! > 0) {
            _onSwipeRight();
          }
        },
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            _onSwipeDown();
          }
        },
        onDoubleTap: _onDoubleTap,
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 32),
              Text(
                'Drishti',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Guided Navigation for the Visually Impaired',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              Spacer(),
              ...options.asMap().entries.map((entry) {
                int idx = entry.key;
                _DrishtiOption option = entry.value;
                bool selected = idx == selectedIndex;
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: selected ? Colors.yellow : Colors.white,
                        width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: option.iconPath != null
                        ? Image.asset(option.iconPath!,
                        color: Colors.white, width: 32, height: 32)
                        : null,
                    title: Text(option.label,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        )),
                    subtitle: option.description.isNotEmpty
                        ? Text(option.description,
                        style: TextStyle(color: Colors.white70))
                        : null,
                  ),
                );
              }).toList(),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrishtiOption {
  final String label;
  final String description;
  final String? iconPath;

  _DrishtiOption({
    required this.label,
    required this.description,
    this.iconPath,
  });
}

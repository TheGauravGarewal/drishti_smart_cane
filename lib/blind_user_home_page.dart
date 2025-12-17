import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';

import 'blind_user_navigation_page.dart';
import 'favourite_locations.dart';
import 'my_account_page.dart';

class BlindUserHomePage extends StatefulWidget {
  @override
  _BlindUserHomePageState createState() => _BlindUserHomePageState();
}

class _BlindUserHomePageState extends State<BlindUserHomePage> {
  final FlutterTts tts = FlutterTts();
  String currentAddress = 'Fetching location...';
  bool isFavourite = false;
  StreamSubscription<Position>? _posStream;

  final List<_BlindUserOption> options = [
    _BlindUserOption(label: "Current Location", icon: Icons.my_location),
    _BlindUserOption(label: "Add to Favourite", icon: Icons.star),
    _BlindUserOption(label: "Share Location", icon: Icons.share),
    _BlindUserOption(label: "Favourite Locations", icon: Icons.list),
    _BlindUserOption(label: "Navigation", icon: Icons.navigation),
    _BlindUserOption(label: "SOS",), // SOS added here below Navigation
    _BlindUserOption(label: "Home", icon: Icons.home, isBottomNav: true),
    _BlindUserOption(label: "Smart Cane", assetPath: "assets/cane.png", isBottomNav: true),
    _BlindUserOption(label: "My Account", icon: Icons.account_circle, isBottomNav: true),
  ];

  int selectedIndex = 0;
  int get mainOptionsLength => options.where((opt) => !opt.isBottomNav).length;
  int get bottomOptionsStart => mainOptionsLength;

  @override
  void initState() {
    super.initState();
    _getAddress();
    _speakScreenTitle();
    _startUploadingLocation();
  }

  @override
  void dispose() {
    _posStream?.cancel();
    super.dispose();
  }

  Future<void> _getAddress() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        setState(() {
          currentAddress = 'Location permission denied';
        });
        await _speak("Location permission denied");
        return;
      }
    }
    Position position =
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks =
    await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark place = placemarks.first;
    setState(() {
      currentAddress =
          "${place.name ?? ""} ${place.thoroughfare ?? ""} ${place.subLocality ?? ""} "
              "${place.locality ?? ""} ${place.postalCode ?? ""} "
              "${place.administrativeArea ?? ""} ${place.country ?? ""}".trim();
    });
  }

  void _startUploadingLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? code = prefs.getString('companion_code');
    print('Companion code for upload: $code');
    if (code == null) {
      print('No companion code found for Firebase upload!');
      return;
    }

    await Geolocator.requestPermission();
    _posStream = Geolocator.getPositionStream().listen((pos) {
      print('Uploading location to Firebase for code $code: ${pos.latitude}, ${pos.longitude}');
      FirebaseDatabase.instance.ref('users/$code/location').set({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'timestamp': ServerValue.timestamp,
      });
    });
  }

  Future _speak(String text) async {
    await tts.setLanguage('en-IN');
    await tts.speak(text);
  }

  void _speakScreenTitle() {
    _speak("Home. Current location: $currentAddress");
  }

  void _onSwipeLeft() {
    setState(() {
      selectedIndex = (selectedIndex + 1) % options.length;
    });
    _speak(options[selectedIndex].label);
  }

  void _onSwipeRight() {
    setState(() {
      selectedIndex = (selectedIndex - 1 + options.length) % options.length;
    });
    _speak(options[selectedIndex].label);
  }

  void _onDoubleTap() async {
    final option = options[selectedIndex];
    _speak('Selected ${option.label}');
    if (option.isBottomNav) {
      switch (option.label) {
        case "My Account":
          Navigator.push(context, MaterialPageRoute(builder: (_) => MyAccountPage()));
          break;
      }
    } else {
      switch (option.label) {
        case "Current Location":
          _speak("Current location: $currentAddress");
          break;
        case "Add to Favourite":
          SharedPreferences prefs = await SharedPreferences.getInstance();
          List<String> favourites = prefs.getStringList('favourite_locations') ?? [];
          if (!favourites.contains(currentAddress)) {
            favourites.add(currentAddress);
            await prefs.setStringList('favourite_locations', favourites);
            _speak("Added to Favourites");
          } else {
            _speak("Already added");
          }
          break;
        case "Favourite Locations":
          Navigator.push(context, MaterialPageRoute(builder: (_) => FavouriteLocationsPage()));
          break;
        case "Share Location":
          _shareLocation();
          break;
        case "Navigation":
          Navigator.push(context, MaterialPageRoute(builder: (_) => BlindUserNavigationPage()));
          break;
        case "SOS":
          _speak("SOS alert activated");
          // Add further SOS action if needed
          break;
        default:
          break;
      }
    }
  }

  void _toggleFavourite() {
    setState(() {
      isFavourite = !isFavourite;
    });
    if (isFavourite) {
      _speak("Location added to Favourites");
    } else {
      _speak("Location removed from Favourites");
    }
  }

  void _shareLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    String googleMapsUrl =
        "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";
    Share.share("My current location: $googleMapsUrl");
    _speak("Sharing Google Maps location");
  }

  void _onSwipeDown() {
    Navigator.of(context).maybePop();
    _speak("Going back");
  }

  @override
  Widget build(BuildContext context) {
    final mainOptions = options.take(mainOptionsLength).toList();
    final bottomNavOptions = options.skip(bottomOptionsStart).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 24),
            Center(
              child: Text(
                "Home",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 14),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 18),
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "Current Location:\n$currentAddress",
                style: TextStyle(color: Colors.white, fontSize: 18),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 18),
            Expanded(
              child: GestureDetector(
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
                child: ListView(
                  children: [
                    ...mainOptions.asMap().entries.map((entry) {
                      int idx = entry.key;
                      _BlindUserOption option = entry.value;
                      bool selected = selectedIndex == idx;
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 35),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selected ? Colors.yellow : Colors.white,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: option.assetPath != null
                              ? Image.asset(option.assetPath!, width: 36, height: 36)
                              : Icon(option.icon, color: Colors.white, size: 36),
                          title: Center(
                            child: Text(
                              option.label,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: bottomNavOptions.asMap().entries.map((entry) {
                  int idx = entry.key + mainOptionsLength;
                  var option = entry.value;
                  bool selected = selectedIndex == idx;
                  return GestureDetector(
                    onTap: () {
                      setState(() => selectedIndex = idx);
                      _speak(option.label);
                    },
                    onDoubleTap: _onDoubleTap,
                    child: Column(
                      children: [
                        option.assetPath != null
                            ? Image.asset(
                          option.assetPath!,
                          width: 32,
                          height: 32,
                          color: selected ? Colors.yellow : Colors.white,
                        )
                            : Icon(
                          option.icon,
                          color: selected ? Colors.yellow : Colors.white,
                          size: 32,
                        ),
                        Text(
                          option.label,
                          style: TextStyle(
                            color: selected ? Colors.yellow : Colors.white,
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlindUserOption {
  final String label;
  final IconData? icon;
  final String? assetPath;
  final bool isBottomNav;
  _BlindUserOption({
    required this.label,
    this.icon,
    this.assetPath,
    this.isBottomNav = false,
  });
}

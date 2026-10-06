import 'dart:async';

import 'package:flutter/material.dart';

void main() {
  runApp(const DigitalPetApp());
}

class DigitalPetApp extends StatelessWidget {
  const DigitalPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Pet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
        ),
        useMaterial3: true,
      ),
      home: const DigitalPetScreen(),
    );
  }
}

class DigitalPetScreen extends StatefulWidget {
  const DigitalPetScreen({super.key});

  @override
  State<DigitalPetScreen> createState() => _DigitalPetScreenState();
}

class _DigitalPetScreenState extends State<DigitalPetScreen> {
  // -------------------------
  // Pet state
  // -------------------------

  String _petName = 'Pip';

  int _happiness = 50;
  int _hunger = 50;

  bool _gameOver = false;
  bool _hasWon = false;
  bool _isPaused = false;

  Timer? _hungerTimer;
  Timer? _highMoodTimer;

  Timer? _bounceTimer;

  bool _isBouncing = false;

  final TextEditingController _nameController =
      TextEditingController();

  // -------------------------
  // Helper functions
  // -------------------------

  int _clampMeter(int value) {
    return value.clamp(0, 100).toInt();
  }

  Color get _moodColor {
    if (_happiness > 70) {
      return Colors.green;
    } else if (_happiness >= 30) {
      return Colors.yellow.shade700;
    } else {
      return Colors.red;
    }
  }

  String get _moodLabel {
    if (_happiness > 70) {
      return 'Happy';
    } else if (_happiness >= 30) {
      return 'Neutral';
    } else {
      return 'Unhappy';
    }
  }

  String get _petMessage {
    if (_gameOver) {
      return 'I need some rest. 😴';
    }

    if (_hasWon) {
      return 'Best day ever! 🎉';
    }

    if (_hunger > 80) {
      return "I'm starving! 🍖";
    }

    if (_happiness <= 30) {
      return 'Play with me? 🎾';
    }

    if (_isPaused) {
      return 'I am taking a little break. 💤';
    }

    return "Hi, I'm $_petName!";
  }

  double get _petScale {
    if (_isBouncing) {
      return 1.10;
    }

    if (_happiness > 70) {
      return 1.06;
    }

    if (_happiness < 30) {
      return 0.94;
    }

    return 1.0;
  }

  // -------------------------
  // Lifecycle
  // -------------------------

  @override
  void initState() {
    super.initState();

    _startHungerTimer();
  }

  void _startHungerTimer() {
    _hungerTimer?.cancel();

    _hungerTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) {
        if (!mounted || _gameOver || _hasWon) {
          timer.cancel();
          return;
        }

        if (_isPaused) {
          return;
        }

        setState(() {
          if (_hunger + 5 > 100) {
            _hunger = 100;
            _happiness = _clampMeter(_happiness - 20);
          } else {
            _hunger += 5;
          }
        });

        _updateOutcome();
      },
    );
  }

  @override
  void dispose() {
    _hungerTimer?.cancel();
    _highMoodTimer?.cancel();
    _bounceTimer?.cancel();
    _nameController.dispose();

    super.dispose();
  }

  // -------------------------
  // Pet actions
  // -------------------------

  void _feedPet() {
    if (_gameOver || _hasWon || _isPaused) {
      return;
    }

    final nextHunger = _clampMeter(_hunger - 10);

    final happinessChange =
        nextHunger < 30 ? -20 : 10;

    final nextHappiness =
        _clampMeter(_happiness + happinessChange);

    setState(() {
      _hunger = nextHunger;
      _happiness = nextHappiness;
    });

    _bouncePet();

    _showSnackBar(
      '$_petName was fed! 🍖',
    );

    _updateOutcome();
  }

  void _playWithPet() {
    if (_gameOver || _hasWon || _isPaused) {
      return;
    }

    setState(() {
      _happiness = _clampMeter(_happiness + 10);
      _hunger = _clampMeter(_hunger + 5);
    });

    _bouncePet();

    _showSnackBar(
      'You played with $_petName! 🎾',
    );

    _updateOutcome();
  }

  // -------------------------
  // Name
  // -------------------------

  void _changePetName() {
    final enteredName =
        _nameController.text.trim();

    if (enteredName.isEmpty) {
      _showSnackBar(
        'Please enter a pet name.',
      );
      return;
    }

    setState(() {
      _petName = enteredName;
    });

    _nameController.clear();

    _showSnackBar(
      'Your pet is now called $_petName!',
    );
  }

  // -------------------------
  // Pause / Resume
  // -------------------------

  void _togglePause() {
    if (_gameOver || _hasWon) {
      return;
    }

    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      _highMoodTimer?.cancel();
      _highMoodTimer = null;

      _showSnackBar(
        'Game paused.',
      );
    } else {
      _showSnackBar(
        'Game resumed.',
      );

      _updateOutcome();
    }
  }

  // -------------------------
  // Reset
  // -------------------------

  void _resetGame() {
    _hungerTimer?.cancel();
    _highMoodTimer?.cancel();

    _hungerTimer = null;
    _highMoodTimer = null;

    setState(() {
      _happiness = 50;
      _hunger = 50;

      _gameOver = false;
      _hasWon = false;
      _isPaused = false;

      _isBouncing = false;
    });

    _startHungerTimer();

    _showSnackBar(
      '$_petName has been reset! 🔄',
    );
  }

  // -------------------------
  // Win / loss system
  // -------------------------

  void _updateOutcome() {
    if (!mounted || _gameOver || _hasWon) {
      return;
    }

    // LOSS
    if (_hunger == 100 && _happiness <= 10) {
      _highMoodTimer?.cancel();
      _highMoodTimer = null;

      _hungerTimer?.cancel();
      _hungerTimer = null;

      setState(() {
        _gameOver = true;
      });

      _showSnackBar(
        'Game over! $_petName needs some rest.',
      );

      return;
    }

    // If paused, don't start the win timer.
    if (_isPaused) {
      return;
    }

    // Happiness must be STRICTLY greater than 80.
    if (_happiness <= 80) {
      _highMoodTimer?.cancel();
      _highMoodTimer = null;
      return;
    }

    // Start the three-minute win timer.
    _highMoodTimer ??= Timer(
      const Duration(minutes: 3),
      () {
        _highMoodTimer = null;

        if (!mounted ||
            _gameOver ||
            _isPaused ||
            _happiness <= 80) {
          return;
        }

        setState(() {
          _hasWon = true;
        });

        _hungerTimer?.cancel();
        _hungerTimer = null;

        _showSnackBar(
          'You won! $_petName had a great day! 🎉',
        );
      },
    );
  }

  // -------------------------
  // Visual polish
  // -------------------------

  void _bouncePet() {
    _bounceTimer?.cancel();

    if (!mounted) {
      return;
    }

    setState(() {
      _isBouncing = true;
    });

    _bounceTimer = Timer(
      const Duration(milliseconds: 250),
      () {
        if (!mounted) {
          return;
        }

        setState(() {
          _isBouncing = false;
        });
      },
    );
  }

  // -------------------------
  // SnackBar helper
  // -------------------------

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // -------------------------
  // UI helpers
  // -------------------------

  Widget _buildMeter({
    required String label,
    required int value,
    required IconData icon,
  }) {
    final reduceMotion =
        MediaQuery.of(context).disableAnimations;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
                ),
                const Spacer(),
                Text(
                  '$value / 100',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: value / 100,
              ),
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              builder:
                  (context, animatedValue, child) {
                return LinearProgressIndicator(
                  value: animatedValue,
                  minHeight: 10,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 4),
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
        ),
      ),
    );
  }

  // -------------------------
  // Main UI
  // -------------------------

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.of(context).disableAnimations;

    final imageWidget = AnimatedScale(
      scale: _petScale,
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          _moodColor,
          BlendMode.modulate,
        ),
        child: Image.asset(
          'assets/images/pet.jpg',
          width: 220,
          height: 220,
          fit: BoxFit.contain,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Pet'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Pet name
              Text(
                _petName,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 4),

              // Mood
              AnimatedSwitcher(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 300),
                child: Text(
                  _moodLabel,
                  key: ValueKey(_moodLabel),
                  style: TextStyle(
                    color: _moodColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Pet image
              imageWidget,

              const SizedBox(height: 10),

              // Pet message
              AnimatedSwitcher(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 300),
                child: Card(
                  key: ValueKey(_petMessage),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      _petMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Status meters
              _buildMeter(
                label: 'Happiness',
                value: _happiness,
                icon: Icons.favorite,
              ),

              const SizedBox(height: 8),

              _buildMeter(
                label: 'Hunger',
                value: _hunger,
                icon: Icons.restaurant,
              ),

              const SizedBox(height: 16),

              // Name input
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Pet name',
                  hintText: 'Enter a new name',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: _changePetName,
                    tooltip: 'Confirm pet name',
                  ),
                ),
                onSubmitted: (_) {
                  _changePetName();
                },
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  _buildActionButton(
                    label: 'Feed',
                    icon: Icons.restaurant,
                    onPressed:
                        (_gameOver ||
                                _hasWon ||
                                _isPaused)
                            ? null
                            : _feedPet,
                  ),
                  _buildActionButton(
                    label: 'Play',
                    icon: Icons.sports_tennis,
                    onPressed:
                        (_gameOver ||
                                _hasWon ||
                                _isPaused)
                            ? null
                            : _playWithPet,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Pause + Reset
              Row(
                children: [
                  _buildActionButton(
                    label: _isPaused
                        ? 'Resume'
                        : 'Pause',
                    icon: _isPaused
                        ? Icons.play_arrow
                        : Icons.pause,
                    onPressed:
                        (_gameOver || _hasWon)
                            ? null
                            : _togglePause,
                  ),
                  _buildActionButton(
                    label: 'Reset',
                    icon: Icons.restart_alt,
                    onPressed: _resetGame,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Game status
              if (_isPaused)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pause_circle),
                        SizedBox(width: 8),
                        Text(
                          'Game Paused',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (_hasWon)
                Card(
                  color: Colors.green.shade100,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          size: 40,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'YOU WON! 🎉',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your pet stayed happy for 3 minutes!',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

              if (_gameOver)
                Card(
                  color: Colors.red.shade100,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.sentiment_dissatisfied,
                          size: 40,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'GAME OVER',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Reset the game to take care of your pet again.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Rules
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How to Play',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Feed your pet to lower hunger.\n'
                        '• Play to increase happiness.\n'
                        '• Hunger increases every 30 seconds.\n'
                        '• Keep happiness above 80 for 3 minutes to win.\n'
                        '• Game over occurs at hunger 100 and happiness 10 or lower.',
                      ),
                    ],
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
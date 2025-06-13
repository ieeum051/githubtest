import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'package:webos_ui/webos_ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const BrickBreakerGame());
}

class BrickBreakerGame extends StatelessWidget {
  const BrickBreakerGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '벽돌깨기 게임',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const int rows = 5;
  static const int columns = 8;
  static const double brickWidth = 80.0;
  static const double brickHeight = 30.0;
  static const double paddleWidth = 100.0;
  static const double paddleHeight = 20.0;
  static const double ballSize = 20.0;
  static const double paddleSpeed = 15.0;

  late List<List<bool>> bricks;
  double paddleX = 0.0;
  double ballX = 0.0;
  double ballY = 0.0;
  double ballSpeedX = 5.0;
  double ballSpeedY = -5.0;
  int score = 0;
  Timer? gameTimer;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    resetGame();
  }

  void resetGame() {
    if (gameTimer != null) {
      gameTimer!.cancel();
    }
    
    setState(() {
      bricks = List.generate(
        rows,
        (_) => List.generate(columns, (_) => true),
      );
      paddleX = 0.0;
      ballX = 0.0;
      ballY = -0.8; // 공의 초기 위치를 더 위로 조정
      ballSpeedX = 3.0; // 공의 속도를 줄임
      ballSpeedY = -3.0;
      score = 0;
    });
    
    startGame();
  }

  void startGame() {
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      updateGame();
    });
  }

  void updateGame() {
    if (!mounted) return;

    setState(() {
      // 공 이동
      ballX += ballSpeedX;
      ballY += ballSpeedY;

      // 벽 충돌 체크
      if (ballX <= -1.0 || ballX >= 1.0) {
        ballSpeedX = -ballSpeedX;
      }
      if (ballY <= -1.0) {
        ballSpeedY = -ballSpeedY;
      }

      // 패들 충돌 체크
      if (ballY >= 0.8 && 
          ballX >= paddleX - 0.1 && 
          ballX <= paddleX + 0.1) {
        ballSpeedY = -ballSpeedY;
        // 패들에 맞은 위치에 따라 공의 방향 조정
        double hitPosition = (ballX - paddleX) / 0.1;
        ballSpeedX = hitPosition * 3.0;
      }

      // 벽돌 충돌 체크
      for (int i = 0; i < rows; i++) {
        for (int j = 0; j < columns; j++) {
          if (bricks[i][j]) {
            double brickX = (j - columns / 2) * (brickWidth / 400);
            double brickY = (i - rows / 2) * (brickHeight / 300);

            if ((ballX - brickX).abs() < 0.1 &&
                (ballY - brickY).abs() < 0.1) {
              bricks[i][j] = false;
              ballSpeedY = -ballSpeedY;
              score += 10;
            }
          }
        }
      }

      // 게임 오버 체크
      if (ballY >= 1.0) {
        gameTimer?.cancel();
        showGameOverDialog();
      }

      // 승리 체크
      bool allBricksCleared = true;
      for (var row in bricks) {
        for (var brick in row) {
          if (brick) {
            allBricksCleared = false;
            break;
          }
        }
      }
      if (allBricksCleared) {
        gameTimer?.cancel();
        showWinDialog();
      }
    });
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('게임 오버'),
        content: Text('점수: $score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              resetGame();
            },
            child: const Text('다시 시작'),
          ),
        ],
      ),
    );
  }

  void showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('승리!'),
        content: Text('점수: $score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              resetGame();
            },
            child: const Text('다시 시작'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: const Text('벽돌깨기 게임'),
      ),
      body: RawKeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKey: (event) {
          if (event is RawKeyDownEvent) {
            setState(() {
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                paddleX = max(-0.9, paddleX - 0.1);
              } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                paddleX = min(0.9, paddleX + 0.1);
              }
            });
          }
        },
        child: Center(
          child: AspectRatio(
            aspectRatio: 4/3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.white),
              ),
              child: Stack(
                children: [
                  // 벽돌
                  ...List.generate(rows, (i) {
                    return List.generate(columns, (j) {
                      if (!bricks[i][j]) return const SizedBox.shrink();
                      return Positioned(
                        left: (j - columns / 2) * brickWidth + 200,
                        top: (i - rows / 2) * brickHeight + 150,
                        child: Container(
                          width: brickWidth,
                          height: brickHeight,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    });
                  }).expand((widgets) => widgets),

                  // 패들
                  Positioned(
                    left: paddleX * 400 + 200 - paddleWidth / 2,
                    bottom: 20,
                    child: Container(
                      width: paddleWidth,
                      height: paddleHeight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // 공
                  Positioned(
                    left: ballX * 400 + 200 - ballSize / 2,
                    top: ballY * 300 + 150 - ballSize / 2,
                    child: Container(
                      width: ballSize,
                      height: ballSize,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // 점수
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Text(
                      '점수: $score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }
}

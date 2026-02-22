import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '天球のからくり儀',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        primaryColor: AppColors.gold,
        fontFamily: 'serif',
      ),
      home: const KarakuriStudioApp(),
    );
  }
}

// ─── 定数・カラー定義 ───
class AppColors {
  static const Color spaceBg = Color(0xFF070A13);
  static const Color winBg = Color(0xD90A0F19); // rgba(10, 15, 25, 0.85)
  static const Color gold = Color(0xFFD4AF37);
  static const Color silver = Color(0xFFA0AAB5);
  static const Color textMain = Color(0xFFF0F4F8);
  static const Color textDim = Color(0xFF7A8A9E);
  static const Color accent = Color(0xFFB33939);

  static const Color sealRed = Color(0xFFE74C3C);
  static const Color sealWhite = Color(0xFFF5F6FA);
  static const Color sealBlue = Color(0xFF3498DB);
  static const Color sealYellow = Color(0xFFF1C40F);
}

enum AppState { home, loading, result }

// ─── メインUI ───
class KarakuriStudioApp extends StatefulWidget {
  const KarakuriStudioApp({super.key});

  @override
  State<KarakuriStudioApp> createState() => _KarakuriStudioAppState();
}

class _KarakuriStudioAppState extends State<KarakuriStudioApp>
    with TickerProviderStateMixin {
  AppState _currentState = AppState.home;
  DateTime _birthDate = DateTime(2000, 1, 1);
  MayaResult? _result;

  // アニメーション用
  late AnimationController _bgAnimController;
  int _loadingStep = 0;
  Timer? _loadingTimer;
  bool _showHanko = false;

  final List<String> _loadingMsgs = [
    "星辰の歯車を同調中...",
    "魂の波長を解析中...",
    "古代の叡智へ接続...",
    "運命の軌道を算出...",
  ];

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 100),
    )..repeat();
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    _loadingTimer?.cancel();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.gold,
              onPrimary: AppColors.spaceBg,
              surface: AppColors.spaceBg,
              onSurface: AppColors.textMain,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  void _startCalculation() {
    setState(() {
      _currentState = AppState.loading;
      _loadingStep = 0;
    });

    _loadingTimer?.cancel();
    _loadingTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      setState(() {
        _loadingStep++;
      });
      if (_loadingStep >= 4) {
        timer.cancel();
        _finishCalculation();
      }
    });
  }

  void _finishCalculation() {
    setState(() {
      _result = MayaLogic.calculate(_birthDate);
      _currentState = AppState.result;
      _showHanko = false;
    });

    // 結果表示後にハンコのアニメーションをトリガー
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showHanko = true);
    });
  }

  void _retry() {
    setState(() {
      _currentState = AppState.home;
      _result = null;
      _showHanko = false;
    });
  }

  void _shareResult() {
    if (_result == null) return;
    final r = _result!;
    final text =
        '【天球のからくり儀】\n私の星宿は「KIN ${r.kin}」でした。\n表: ${r.sunSeal.jp}\n裏: ${r.waveSeal.jp}\n音: ${r.tone.num} (${r.tone.name})\n#マヤ暦占い #KarakuriStudio';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '瓦版（クリップボード）に記録しました。',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'sans-serif',
          ),
        ),
        backgroundColor: AppColors.gold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 900),
          decoration: BoxDecoration(
            color: AppColors.spaceBg,
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.1),
                blurRadius: 100,
                spreadRadius: 20,
              ),
            ],
            border: MediaQuery.of(context).size.width > 480
                ? Border.all(color: const Color(0xFF111111), width: 8)
                : null,
            borderRadius: MediaQuery.of(context).size.width > 480
                ? BorderRadius.circular(20)
                : BorderRadius.zero,
          ),
          child: Stack(
            children: [
              // 背景アニメーション
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _bgAnimController,
                  builder: (_, __) => CustomPaint(
                    painter: AstrolabePainter(
                      _bgAnimController.value,
                      _currentState == AppState.loading,
                    ),
                  ),
                ),
              ),
              // 画面遷移
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 1.05,
                        end: 1.0,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _buildCurrentScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentState) {
      case AppState.home:
        return _buildHome();
      case AppState.loading:
        return _buildLoading();
      case AppState.result:
        return _buildResult();
    }
  }

  // ─── 各画面ビルド ───

  Widget _buildHome() {
    return Padding(
      key: const ValueKey('home'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          const SizedBox(height: 60),
          const Text(
            'CELESTIAL KARAKURI GLOBE',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 13,
              letterSpacing: 5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '天球のからくり儀',
            style: TextStyle(
              color: AppColors.textMain,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              height: 1.1,
              shadows: [
                Shadow(color: AppColors.gold.withOpacity(0.4), blurRadius: 15),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '古代マヤの叡智とからくりが交差する。\n生誕の刻を刻み、汝の星宿を読み解け。',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.silver,
              fontSize: 13,
              height: 2,
              fontFamily: 'sans-serif',
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.winBg,
              border: Border.all(color: AppColors.gold.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '生誕の日 (Date of Birth)',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.gold)),
                    ),
                    child: Text(
                      "${_birthDate.year.toString().padLeft(4, '0')}-${_birthDate.month.toString().padLeft(2, '0')}-${_birthDate.day.toString().padLeft(2, '0')}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textMain,
                        fontSize: 24,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _startCalculation,
                  style:
                      ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: AppColors.gold,
                        side: const BorderSide(color: AppColors.gold),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: 0,
                      ).copyWith(
                        overlayColor: MaterialStateProperty.resolveWith(
                          (states) => AppColors.gold.withOpacity(0.2),
                        ),
                      ),
                  child: const Text(
                    '星の軌道を計算する',
                    style: TextStyle(
                      fontSize: 16,
                      letterSpacing: 4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    final msgIndex = _loadingStep % _loadingMsgs.length;
    return Center(
      key: const ValueKey('loading'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: AnimatedBuilder(
              animation: _bgAnimController,
              builder: (_, __) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: _bgAnimController.value * math.pi * 20,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.gold,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                      ),
                    ),
                    Transform.rotate(
                      angle: -_bgAnimController.value * math.pi * 15,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.accent),
                        ),
                      ),
                    ),
                    Transform.rotate(
                      angle: _bgAnimController.value * math.pi * 10,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.silver),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 30),
          Text(
            _loadingMsgs[msgIndex],
            style: const TextStyle(
              color: AppColors.silver,
              fontSize: 14,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'PHASE ${_loadingStep + 1} / ALIGNING',
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 10,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    if (_result == null) return const SizedBox();
    final r = _result!;

    return SingleChildScrollView(
      key: const ValueKey('result'),
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 60),
      child: Column(
        children: [
          // ヘッダー部
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.1),
                      border: Border.all(color: AppColors.gold),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      'KIN ${r.kin}',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 16,
                        letterSpacing: 3,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'これが貴方の魂に刻まれた\n星々の羅針盤です。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.silver,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
              Positioned(
                top: -10,
                right: 0,
                child: AnimatedScale(
                  scale: _showHanko ? 1.0 : 3.0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack,
                  child: AnimatedOpacity(
                    opacity: _showHanko ? 0.8 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Transform.rotate(
                      angle: 15 * math.pi / 180,
                      child: Container(
                        width: 65,
                        height: 65,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.accent, width: 2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '星読\n完了',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // カード群
          _buildSealCard(
            '顕在意識 / 表の顔',
            r.sunSeal,
            subLabel: '✦ 隠された才能・天職',
            subText: r.sunSeal.talent,
          ),
          _buildSealCard('潜在意識 / 裏の顔', r.waveSeal),
          _buildToneCard(r.tone),
          _buildSealCard(
            '運命の道標 / ガイドKIN',
            r.guideSeal,
            descOverride:
                '貴方の人生が迷った時、この「${r.guideSeal.jp}」の持つエネルギー（${r.guideSeal.keyword.split('・').length > 1 ? r.guideSeal.keyword.split('・')[1] : r.guideSeal.keyword}こと）を意識するか、この紋章を持つ人がキーパーソンとなります。',
            titleSuffix: r.guideSeal.jp == r.sunSeal.jp ? ' (自らが導き手)' : '',
          ),

          // 相性
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '星の相関関係 (相性)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildCompatItem(
            '惹かれ合う星 (神秘KIN)',
            '予期せぬ刺激を与え、潜在能力を引き出し合う関係。',
            r.compatOccult,
            AppColors.sealRed,
          ),
          _buildCompatItem(
            '似た者同士 (類似KIN)',
            '感覚が似ており、一緒にいて最もリラックスできる親友。',
            r.compatAnalog,
            AppColors.sealBlue,
          ),
          _buildCompatItem(
            '学びの対象 (反対KIN)',
            '価値観は真逆だが、自分にないものを見せてくれる師。',
            r.compatAntipode,
            AppColors.sealYellow,
          ),

          // 託宣（オラクル）
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: AppColors.gold.withOpacity(0.3),
                  style: BorderStyle.none,
                ),
              ), // dashed is hard in standard container, use normal
            ),
            child: Column(
              children: [
                Divider(color: AppColors.gold.withOpacity(0.3)),
                const SizedBox(height: 16),
                const Text(
                  '宿命の託宣',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 13,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _generateOracle(r),
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 14,
                    height: 2,
                  ),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 16),
                Divider(color: AppColors.gold.withOpacity(0.3)),
              ],
            ),
          ),

          // アクションボタン
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _shareResult,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.spaceBg,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text(
              '瓦版に記録する (Share)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _retry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textDim,
              side: const BorderSide(color: AppColors.textDim),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text(
              '天球儀を巻き戻す',
              style: TextStyle(fontSize: 16, letterSpacing: 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSealCard(
    String label,
    SealData seal, {
    String? subLabel,
    String? subText,
    String? descOverride,
    String titleSuffix = '',
  }) {
    final colors = _getColorsForClass(seal.colorClass);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xCC0F141E),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // 左のカラーライン
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: Container(color: colors[1]),
          ),
          // 背景の大きなドット絵
          Positioned(
            right: -20,
            bottom: -20,
            child: Opacity(
              opacity: 0.08,
              child: CustomPaint(
                size: const Size(128, 128),
                painter: SealPainter(
                  seal.index,
                  colors[0],
                  colors[1],
                  isBackground: true,
                ),
              ),
            ),
          ),
          // コンテンツ
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              color: AppColors.textDim,
                              fontSize: 10,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            seal.jp + titleSuffix,
                            style: TextStyle(
                              color: colors[1],
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CustomPaint(
                      size: const Size(40, 40),
                      painter: SealPainter(
                        seal.index,
                        colors[0],
                        colors[1],
                        isBackground: false,
                      ),
                    ),
                  ],
                ),
                Text(
                  seal.en,
                  style: const TextStyle(
                    color: AppColors.silver,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    seal.keyword,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'sans-serif',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  descOverride ?? seal.desc,
                  style: const TextStyle(
                    color: Color(0xFFCCCCCC),
                    fontSize: 14,
                    height: 1.8,
                  ),
                ),
                if (subLabel != null && subText != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                          style: BorderStyle.solid,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subLabel,
                          style: const TextStyle(
                            color: AppColors.silver,
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subText,
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToneCard(ToneData tone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xCC0F141E),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: Container(color: AppColors.gold),
          ),
          Positioned(
            right: -20,
            bottom: -20,
            child: Opacity(
              opacity: 0.08,
              child: CustomPaint(
                size: const Size(128, 128),
                painter: MayaNumberPainter(tone.num, isBackground: true),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '人生の役割 / 天の音',
                          style: TextStyle(
                            color: AppColors.textDim,
                            fontSize: 10,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '音 ${tone.num} : ${tone.name}',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    CustomPaint(
                      size: const Size(40, 40),
                      painter: MayaNumberPainter(tone.num, isBackground: false),
                    ),
                  ],
                ),
                Text(
                  tone.en,
                  style: const TextStyle(
                    color: AppColors.silver,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tone.keyword,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'sans-serif',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  tone.desc,
                  style: const TextStyle(
                    color: Color(0xFFCCCCCC),
                    fontSize: 14,
                    height: 1.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatItem(
    String label,
    String desc,
    String val,
    Color valColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            val,
            style: TextStyle(
              color: valColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _generateOracle(MayaResult r) {
    final isSame = r.sunSeal.jp == r.waveSeal.jp;
    String text = '貴方の魂は「${r.sunSeal.keyword}」という表面的な性質を通じて世界と交わります。';
    if (isSame) {
      text += '表と裏が同じ紋章であるため、裏表のない純粋さと、その紋章の極めて強力なエネルギーを持っています。';
    } else {
      text +=
          'しかし、その根底には「${r.waveSeal.keyword}」という強い潜在意識が流れており、年齢を重ねるごとに裏の紋章の性質が表れてきます。';
    }
    final talentSplit = r.sunSeal.talent.split('、');
    final talentShort = talentSplit.isNotEmpty
        ? talentSplit.first
        : r.sunSeal.talent;
    text +=
        '\n\nまた、銀河の音「${r.tone.num}」は貴方に「${r.tone.keyword}」という役割を与えました。時には『${r.compatAntipode}』を持つ人との摩擦から学びを得て、運命の道標である『${r.guideSeal.jp}』の力を意識することで、貴方の持つ「$talentShort」といった才能が最も美しく開花するでしょう。';
    return text;
  }

  List<Color> _getColorsForClass(String colorClass) {
    switch (colorClass) {
      case 'c-yellow':
        return [const Color(0xFFD4AC0D), AppColors.sealYellow];
      case 'c-red':
        return [const Color(0xFFC0392B), AppColors.sealRed];
      case 'c-white':
        return [const Color(0xFFA0AAB5), AppColors.sealWhite];
      case 'c-blue':
        return [const Color(0xFF2980B9), AppColors.sealBlue];
      case 'c-gold':
        return [const Color(0xFFB8962E), AppColors.gold];
      default:
        return [const Color(0xFFB8962E), AppColors.gold];
    }
  }
}

// ─── カスタムペインター (Canvas描画) ───

class AstrolabePainter extends CustomPainter {
  final double time;
  final bool isFast;
  AstrolabePainter(this.time, this.isFast);

  @override
  void paint(Canvas canvas, Size size) {
    final speed = isFast ? 15.0 : 1.0;
    final t = time * 200000 * speed;

    // 星屑
    final particlePaint = Paint()
      ..color = AppColors.gold.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 30; i++) {
      final px = (math.sin(i * 123 + t * 0.0001) * 0.5 + 0.5) * size.width;
      final py = (math.cos(i * 321 + t * 0.00015) * 0.5 + 0.5) * size.height;
      final s = (math.sin(i + t * 0.002) * 0.5 + 0.5) * 1.5;
      canvas.drawCircle(Offset(px, py), s, particlePaint);
    }

    // 天球儀
    final cx = size.width / 2;
    final cy = size.height / 2 - 50;
    final r = math.min(size.width, size.height) * 0.35;

    canvas.save();
    canvas.translate(cx, cy);

    final linePaint = Paint()
      ..color = AppColors.gold.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawCircle(Offset.zero, r, linePaint);
    canvas.drawCircle(
      Offset.zero,
      r * 1.05,
      linePaint..color = AppColors.gold.withOpacity(0.1),
    );

    final orbitPaint = Paint()
      ..color = AppColors.gold.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.save();
    canvas.rotate(t * 0.0005);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 0.4),
      orbitPaint,
    );
    canvas.restore();

    canvas.save();
    canvas.rotate(-t * 0.0004);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 0.6, height: r * 2),
      orbitPaint,
    );
    canvas.restore();

    canvas.save();
    canvas.rotate(t * 0.00025);
    // Path for dashed line manually drawing is complex, use simple thin line for Flutter adaptation
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 1.6, height: r * 1.6),
      orbitPaint..color = AppColors.gold.withOpacity(0.2),
    );
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AstrolabePainter oldDelegate) => true;
}

class SealPainter extends CustomPainter {
  final int index;
  final Color c1;
  final Color c2;
  final bool isBackground;

  SealPainter(this.index, this.c1, this.c2, {this.isBackground = false});

  @override
  void paint(Canvas canvas, Size size) {
    final pSize = isBackground ? 16.0 : 5.0;
    final pattern = MayaData.sealShapes[index % MayaData.sealShapes.length];

    final paint1 = Paint()..color = c1;
    final paint2 = Paint()..color = c2;

    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        int code = pattern[y][x];
        if (code == 0) continue;
        Paint p = code == 1 ? paint1 : paint2;
        canvas.drawRect(Rect.fromLTWH(x * pSize, y * pSize, pSize, pSize), p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MayaNumberPainter extends CustomPainter {
  final int number;
  final bool isBackground;

  MayaNumberPainter(this.number, {this.isBackground = false});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = isBackground ? 2.5 : 1.0;
    canvas.scale(scale, scale);

    final paint = Paint()..color = AppColors.gold;
    final int bars = number ~/ 5;
    final int dots = number % 5;

    double startY = 35.0;

    // Draw bars
    for (int i = 0; i < bars; i++) {
      canvas.drawRect(Rect.fromLTWH(4, startY - i * 10, 32, 5), paint);
    }

    // Draw dots
    final dotY = startY - bars * 10 - 6;
    const dotSpacing = 8.0;
    final startX = (40.0 - (dots * dotSpacing) + 2) / 2;

    for (int i = 0; i < dots; i++) {
      canvas.drawCircle(Offset(startX + i * dotSpacing, dotY), 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── ロジック・データ群 ───

class MayaResult {
  final int kin;
  final SealData sunSeal;
  final SealData waveSeal;
  final ToneData tone;
  final SealData guideSeal;
  final String compatOccult;
  final String compatAnalog;
  final String compatAntipode;

  MayaResult(
    this.kin,
    this.sunSeal,
    this.waveSeal,
    this.tone,
    this.guideSeal,
    this.compatOccult,
    this.compatAnalog,
    this.compatAntipode,
  );
}

class MayaLogic {
  static MayaResult calculate(DateTime target) {
    final baseDate = DateTime.utc(2012, 12, 21, 12, 0, 0); // KIN 207
    final targetDate = DateTime.utc(
      target.year,
      target.month,
      target.day,
      12,
      0,
      0,
    );

    final diffDays = targetDate.difference(baseDate).inDays;

    int kin = ((207 + diffDays) % 260 + 260) % 260;
    if (kin == 0) kin = 260;

    final sunIndex = kin % 20;
    final sunSeal = MayaData.seals[sunIndex];

    final toneIndex = kin % 13;
    final tone = MayaData.tones[toneIndex];

    int waveStartKin = kin - tone.num + 1;
    if (waveStartKin <= 0) waveStartKin += 260;
    final waveIndex = waveStartKin % 20;
    final waveSeal = MayaData.seals[waveIndex];

    final guideShifts = {
      1: 0,
      2: 12,
      3: 4,
      4: 16,
      5: 8,
      6: 0,
      7: 12,
      8: 4,
      9: 16,
      10: 8,
      11: 0,
      12: 12,
      13: 4,
    };
    final guideIndex = (sunIndex + guideShifts[tone.num]!) % 20;
    final guideSeal = MayaData.seals[guideIndex];

    final occultIndex = (21 - sunIndex) % 20;
    final analogIndex = (19 - sunIndex + 20) % 20;
    final antipodeIndex = (sunIndex + 10) % 20;

    return MayaResult(
      kin,
      sunSeal.copyWith(
        index: sunIndex,
        colorClass: MayaData.colorClasses[sunIndex % 4],
      ),
      waveSeal.copyWith(
        index: waveIndex,
        colorClass: MayaData.colorClasses[waveIndex % 4],
      ),
      tone,
      guideSeal.copyWith(
        index: guideIndex,
        colorClass: MayaData.colorClasses[guideIndex % 4],
      ),
      MayaData.seals[occultIndex].jp,
      MayaData.seals[analogIndex].jp,
      MayaData.seals[antipodeIndex].jp,
    );
  }
}

class SealData {
  final int index;
  final String jp;
  final String en;
  final String keyword;
  final String desc;
  final String talent;
  final String colorClass;

  const SealData(
    this.jp,
    this.en,
    this.keyword,
    this.desc,
    this.talent, {
    this.index = 0,
    this.colorClass = '',
  });

  SealData copyWith({int? index, String? colorClass}) {
    return SealData(
      jp,
      en,
      keyword,
      desc,
      talent,
      index: index ?? this.index,
      colorClass: colorClass ?? this.colorClass,
    );
  }
}

class ToneData {
  final int num;
  final String name;
  final String en;
  final String keyword;
  final String desc;
  const ToneData(this.num, this.name, this.en, this.keyword, this.desc);
}

class MayaData {
  static const List<String> colorClasses = [
    'c-yellow',
    'c-red',
    'c-white',
    'c-blue',
  ];

  static const List<SealData> seals = [
    SealData(
      "黄太陽",
      "Yellow Sun",
      "普遍的な火・啓蒙する・生命",
      "周囲を明るく照らす太陽のような存在です。分け隔てなく愛を注ぎ、リーダーシップを発揮します。ただし、責任感が強すぎて一人で抱え込みがちな点には注意が必要です。",
      "経営者、プロデューサー、教育者など、全体をまとめるポジションで輝きます。",
    ),
    SealData(
      "紅龍",
      "Red Dragon",
      "誕生の力・育む・存在",
      "生命力に溢れ、新しいことを始めるエネルギーに満ちています。母性愛が強く、人を育てることに喜びを感じます。過去の血脈や伝統を重んじる傾向もあります。",
      "ゼロからイチを生み出す起業家や、後進を育成するコンサルタントに向いています。",
    ),
    SealData(
      "白風",
      "White Wind",
      "霊・伝える・呼吸",
      "目に見えない想いやメッセージを伝えるメッセンジャー。感受性が豊かで、共感能力が高いのが特徴です。繊細ゆえに傷つきやすい一面も持ち合わせています。",
      "音楽、メディア、スピリチュアル関連など、目に見えないものを伝える仕事が適職。",
    ),
    SealData(
      "蒼夜",
      "Blue Night",
      "豊かさ・夢見る・直感",
      "マイペースで独自の豊かな精神世界を持っています。夢や目標を語ることで共感者を増やします。金銭感覚に優れていますが、秘密主義になりがちな面もあります。",
      "金融関係、プランナー、独自の感性を活かしたクリエイターとして大成します。",
    ),
    SealData(
      "黄種",
      "Yellow Seed",
      "開花・目指す・気づき",
      "知的好奇心が旺盛で、根本的な理屈を知りたがる探求者です。納得するまで動かない頑固さもありますが、一度のめり込むと素晴らしい花を咲かせます。",
      "学者、研究者、専門分野のスペシャリストなど、深く掘り下げる仕事に向いています。",
    ),
    SealData(
      "紅蛇",
      "Red Serpent",
      "生命力・生き残る・本能",
      "直感と本能に従って行動する情熱家。自己主張が強く、真実を暴き出す力を持ちます。オンオフの差が激しく、リフレッシュする時間がないと倒れてしまいます。",
      "スポーツ選手、営業職、神経を使う精密な仕事など、短期集中型の環境が適しています。",
    ),
    SealData(
      "白界橋",
      "White Worldbridger",
      "死・等しくする・機会",
      "異なる世界や人と人を繋ぐ「橋渡し」の役割を持ちます。スケールの大きな視野を持ち、おもてなしの精神に溢れています。執着を手放すことが人生の鍵です。",
      "外交官、貿易関係、イベント企画など、人と人を繋ぐコミュニティ運営の才能。",
    ),
    SealData(
      "蒼手",
      "Blue Hand",
      "遂行・知る・癒し",
      "献身的で、手を動かすことで人々を癒やし、物事を成し遂げる職人肌です。体験から学ぶことを重視しますが、手抜きができないため抱え込みすぎに注意です。",
      "料理人、整体師、外科医、ハンドメイド作家など「手」を使う仕事が文字通り天職。",
    ),
    SealData(
      "黄星",
      "Yellow Star",
      "気品・美しくする・芸術",
      "美意識が高く、プロ意識に溢れた完璧主義者。環境や外見を美しく整えることで運気が上がります。妥協を許さないため、他者にも厳しくなりがちな点に注意。",
      "デザイナー、美容業界、芸術家など、美しさを創造し整えるプロフェッショナル。",
    ),
    SealData(
      "紅月",
      "Red Moon",
      "普遍的な水・清める・流れ",
      "新しい流れを生み出す浄化の力を持っています。使命感を持つことで爆発的なエネルギーを発揮します。流行に敏感で華やかな魅力を持ちます。",
      "トレンドを生み出すインフルエンサー、ファッション、清算・浄化を伴う仕事。",
    ),
    SealData(
      "白犬",
      "White Dog",
      "ハート・愛する・忠誠",
      "家族や仲間を誰よりも大切にする忠誠心の塊。一度信頼した相手にはどこまでも尽くします。直感力にも優れますが、身内を贔屓しすぎる傾向があります。",
      "秘書、マネージャー、信頼関係が重視されるチームでのサポート役で才能が開花。",
    ),
    SealData(
      "蒼猿",
      "Blue Monkey",
      "魔術・遊ぶ・幻想",
      "高い知性とユーモアで困難すらも遊びに変える天才肌。枠に囚われない自由な発想を持ちます。真面目になりすぎると良さが消えるため、常に楽しむ心を忘れないで。",
      "エンターテイメント業、ゲームクリエイター、アイデア勝負の企画職に最適です。",
    ),
    SealData(
      "黄人",
      "Yellow Human",
      "自由意志・感化する・知恵",
      "道理を重んじ、自立心が強く、束縛を嫌う自由人です。論理的な説得力で人を感化します。自分の信念を曲げないため、時には柔軟さを持つことが大切です。",
      "フリーランス、評論家、自らの専門知識で道を切り開く独立したポジション。",
    ),
    SealData(
      "紅空歩",
      "Red Skywalker",
      "空間・探求する・目覚め",
      "未知の世界へ飛び込んでいく冒険家。体験を通じて学び、人々の成長を助ける教育者の素質を持ちます。常に動き回っていないとエネルギーが滞ります。",
      "旅行関係、ジャーナリスト、ボランティア活動など、現場の体験を伝える仕事。",
    ),
    SealData(
      "白魔術",
      "White Wizard",
      "永遠・魅惑する・受容性",
      "真面目で純粋、ベストを尽くす魔法使い。高い受容性を持ち、人を許し受け入れることで運が開けます。想定外の事態に弱いというナイーブな一面も。",
      "カウンセラー、占い師、ヒーラーなど、人を魅了し精神的な救済を与える仕事。",
    ),
    SealData(
      "蒼鷲",
      "Blue Eagle",
      "ヴィジョン・創り出す・心",
      "高い視点から物事を見通す先見の明を持ちます。戦略的で客観的な判断が得意。心がネガティブになると批判的になるため、モチベーション管理が重要です。",
      "経営コンサルタント、投資家、パイロットなど、大局を見る目が必要なポジション。",
    ),
    SealData(
      "黄戦士",
      "Yellow Warrior",
      "知性・問う・大胆さ",
      "困難な壁があるほど燃え上がる、不屈のチャレンジャー。実直で嘘がつけず、常に「なぜ？」という問いを持ちます。思いやりと優しさを忘れないことが鍵です。",
      "新規開拓の営業、実業家、困難な課題に挑むプロジェクトリーダー。",
    ),
    SealData(
      "紅地球",
      "Red Earth",
      "ナビゲーション・発展させる・共時性",
      "リズム感とバランス感覚に優れ、人を惹きつけ導く力があります。シンクロニシティ（意味のある偶然）を多く体験します。自然と触れ合うことでエネルギーを充電します。",
      "司会業、カウンセラー、環境保護活動など、人の心をオープンにし導く仕事。",
    ),
    SealData(
      "白鏡",
      "White Mirror",
      "果てしなさ・映し出す・秩序",
      "物事の真実をありのままに映し出す、礼儀正しく秩序を重んじる人。約束を守らない人を許せない厳しさがあります。枠を外すことで無限の可能性が広がります。",
      "法律関係、経理、正確さや公平性が求められるシステム管理などの分野。",
    ),
    SealData(
      "蒼嵐",
      "Blue Storm",
      "自己発生・触発する・エネルギー",
      "周囲を巻き込む強力なエネルギーの持ち主。変化を恐れず、むしろ困難な状況でこそ本領を発揮します。良き理解者を得ることで、その嵐は恵みの雨となります。",
      "企業改革者、料理人（火と水を扱う）、既存の枠組みを壊して再構築する仕事。",
    ),
  ];

  static const List<ToneData> tones = [
    ToneData(13, "宇宙", "Cosmic", "存在・越える", "器が大きく、すべてを包み込む包容力。予期せぬ変化を楽しめる天才肌。"),
    ToneData(
      1,
      "磁気",
      "Magnetic",
      "目的・統一する",
      "強い意思で目標に向かって真っ直ぐ進むリーダーシップ。人を惹きつける引力。",
    ),
    ToneData(
      2,
      "月",
      "Lunar",
      "挑戦・極性にする",
      "直感力があり、白黒はっきりさせる。対立する二つのもののバランスを取る役割。",
    ),
    ToneData(
      3,
      "電気",
      "Electric",
      "奉仕・つなぎ合わせる",
      "未知のもの同士を繋ぎ合わせ、新しいものを生み出すクリエイティブなエネルギー。",
    ),
    ToneData(
      4,
      "自己存在",
      "Self-Existing",
      "形・測る",
      "物事を論理的に分析し、システムやルールを構築する探求者。職人気質。",
    ),
    ToneData(
      5,
      "倍音",
      "Overtone",
      "輝き・力を与える",
      "底知れぬパワーを持ち、高い目標を掲げて周囲を巻き込みながら達成する。",
    ),
    ToneData(
      6,
      "律動",
      "Rhythmic",
      "同等・組織する",
      "マイペースで確固たる自分の世界を持つ。平等と心の動揺を鎮めるバランサー。",
    ),
    ToneData(
      7,
      "共振",
      "Resonant",
      "調律・合わせる",
      "情報収集能力が高く、宇宙とチューニングを合わせる神秘主義者。直感が鋭い。",
    ),
    ToneData(
      8,
      "銀河",
      "Galactic",
      "無欠性・調和させる",
      "全体の調和を重んじ、周囲をフォローする。動物や自然を愛好する温和な性格。",
    ),
    ToneData(
      9,
      "太陽",
      "Solar",
      "意図・脈動させる",
      "明るく情熱的。ワクワクする感情を周囲に伝染させる、生粋のムードメーカー。",
    ),
    ToneData(
      10,
      "惑星",
      "Planetary",
      "現れ・生み出す",
      "プロデュース能力が極めて高く、目に見える形で結果を出す完璧主義者。",
    ),
    ToneData(
      11,
      "スペクトル",
      "Spectral",
      "解放・溶かす",
      "既存のルールやしがらみを破壊し、新しい風を吹き込む改革者。自由を愛する。",
    ),
    ToneData(
      12,
      "水晶",
      "Crystal",
      "協力・捧げる",
      "人の集まる場所で輝きを放つ。相談役として他者の悩みを聞き、癒やす才能。",
    ),
  ];

  static const List<List<List<int>>> sealShapes = [
    [
      [0, 1, 0, 1, 1, 0, 1, 0],
      [1, 0, 2, 2, 2, 2, 0, 1],
      [0, 2, 1, 1, 1, 1, 2, 0],
      [1, 2, 1, 2, 2, 1, 2, 1],
      [1, 2, 1, 2, 2, 1, 2, 1],
      [0, 2, 1, 1, 1, 1, 2, 0],
      [1, 0, 2, 2, 2, 2, 0, 1],
      [0, 1, 0, 1, 1, 0, 1, 0],
    ],
    [
      [0, 0, 1, 1, 1, 0, 0, 0],
      [0, 1, 2, 2, 2, 1, 0, 0],
      [1, 2, 1, 2, 1, 2, 1, 0],
      [1, 2, 2, 2, 2, 2, 1, 0],
      [0, 1, 2, 1, 1, 2, 1, 0],
      [0, 0, 1, 2, 2, 1, 0, 0],
      [0, 1, 2, 2, 2, 2, 1, 0],
      [0, 1, 1, 1, 1, 1, 1, 0],
    ],
    [
      [0, 0, 2, 2, 2, 0, 0, 0],
      [0, 2, 1, 1, 1, 2, 0, 0],
      [2, 1, 0, 0, 0, 1, 2, 0],
      [0, 2, 1, 1, 2, 0, 0, 0],
      [0, 0, 0, 0, 1, 2, 0, 0],
      [2, 2, 2, 1, 1, 2, 0, 0],
      [1, 1, 1, 2, 2, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0],
    ],
    [
      [0, 0, 0, 1, 1, 0, 0, 0],
      [0, 0, 1, 2, 2, 1, 0, 0],
      [0, 1, 2, 1, 0, 2, 1, 0],
      [1, 2, 0, 0, 0, 0, 2, 1],
      [1, 2, 0, 1, 2, 0, 2, 1],
      [0, 1, 2, 1, 0, 2, 1, 0],
      [0, 0, 1, 2, 2, 1, 0, 0],
      [0, 0, 0, 1, 1, 0, 0, 0],
    ],
    [
      [0, 0, 0, 1, 1, 0, 0, 0],
      [0, 0, 1, 2, 2, 1, 0, 0],
      [0, 1, 2, 1, 1, 2, 1, 0],
      [0, 1, 2, 2, 2, 2, 1, 0],
      [0, 1, 2, 1, 1, 2, 1, 0],
      [1, 2, 1, 0, 0, 1, 2, 1],
      [1, 2, 1, 0, 0, 1, 2, 1],
      [0, 1, 0, 0, 0, 0, 1, 0],
    ],
    [
      [0, 0, 1, 1, 1, 1, 0, 0],
      [0, 1, 2, 2, 2, 1, 0, 0],
      [1, 2, 1, 2, 1, 2, 1, 0],
      [1, 2, 2, 2, 2, 2, 1, 0],
      [0, 1, 1, 1, 1, 2, 1, 0],
      [0, 0, 0, 0, 1, 2, 1, 0],
      [1, 1, 1, 1, 2, 1, 0, 0],
      [0, 1, 1, 1, 0, 0, 0, 0],
    ],
    [
      [0, 1, 1, 1, 1, 1, 1, 0],
      [1, 2, 2, 0, 0, 2, 2, 1],
      [1, 2, 1, 0, 0, 1, 2, 1],
      [1, 2, 2, 1, 1, 2, 2, 1],
      [1, 2, 2, 1, 1, 2, 2, 1],
      [1, 2, 1, 0, 0, 1, 2, 1],
      [1, 2, 2, 0, 0, 2, 2, 1],
      [0, 1, 1, 1, 1, 1, 1, 0],
    ],
    [
      [0, 0, 1, 0, 1, 0, 0, 0],
      [0, 1, 2, 1, 2, 1, 0, 0],
      [0, 1, 2, 1, 2, 1, 1, 0],
      [1, 2, 2, 2, 2, 2, 2, 1],
      [1, 2, 2, 2, 2, 2, 2, 1],
      [0, 1, 2, 2, 2, 2, 1, 0],
      [0, 1, 2, 2, 2, 2, 1, 0],
      [0, 0, 1, 1, 1, 1, 0, 0],
    ],
    [
      [0, 0, 0, 1, 1, 0, 0, 0],
      [0, 0, 1, 2, 2, 1, 0, 0],
      [0, 1, 2, 2, 2, 2, 1, 0],
      [1, 2, 2, 1, 1, 2, 2, 1],
      [1, 2, 2, 1, 1, 2, 2, 1],
      [0, 1, 2, 2, 2, 2, 1, 0],
      [0, 0, 1, 2, 2, 1, 0, 0],
      [0, 0, 0, 1, 1, 0, 0, 0],
    ],
    [
      [0, 0, 0, 1, 1, 0, 0, 0],
      [0, 0, 1, 2, 2, 1, 0, 0],
      [0, 1, 2, 2, 2, 2, 1, 0],
      [1, 2, 2, 1, 1, 2, 2, 1],
      [1, 2, 1, 0, 0, 1, 2, 1],
      [1, 2, 2, 1, 1, 2, 2, 1],
      [0, 1, 2, 2, 2, 2, 1, 0],
      [0, 0, 1, 1, 1, 1, 0, 0],
    ],
    [
      [1, 1, 0, 0, 0, 0, 1, 1],
      [1, 2, 1, 0, 0, 1, 2, 1],
      [0, 1, 2, 1, 1, 2, 1, 0],
      [0, 1, 2, 2, 2, 2, 1, 0],
      [0, 1, 1, 2, 2, 1, 1, 0],
      [0, 1, 2, 1, 1, 2, 1, 0],
      [0, 0, 1, 2, 2, 1, 0, 0],
      [0, 0, 0, 1, 1, 0, 0, 0],
    ],
    [
      [0, 0, 1, 1, 1, 1, 0, 0],
      [0, 1, 2, 2, 2, 2, 1, 0],
      [1, 2, 1, 2, 2, 1, 2, 1],
      [1, 2, 2, 2, 2, 2, 2, 1],
      [0, 1, 2, 1, 1, 2, 1, 0],
      [0, 1, 2, 2, 2, 2, 1, 0],
      [0, 0, 1, 1, 1, 1, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0],
    ],
    [
      [0, 0, 0, 1, 1, 0, 0, 0],
      [0, 0, 1, 2, 2, 1, 0, 0],
      [0, 0, 0, 1, 1, 0, 0, 0],
      [0, 1, 1, 2, 2, 1, 1, 0],
      [1, 2, 1, 2, 2, 1, 2, 1],
      [1, 0, 1, 2, 2, 1, 0, 1],
      [0, 0, 1, 2, 2, 1, 0, 0],
      [0, 0, 1, 1, 1, 1, 0, 0],
    ],
    [
      [1, 1, 0, 1, 1, 0, 1, 1],
      [0, 1, 0, 1, 1, 0, 1, 0],
      [0, 1, 0, 1, 1, 0, 1, 0],
      [1, 2, 1, 2, 2, 1, 2, 1],
      [1, 2, 1, 2, 2, 1, 2, 1],
      [0, 1, 0, 1, 1, 0, 1, 0],
      [0, 1, 0, 1, 1, 0, 1, 0],
      [1, 1, 0, 1, 1, 0, 1, 1],
    ],
    [
      [0, 0, 0, 1, 1, 0, 0, 0],
      [0, 0, 1, 2, 2, 1, 0, 0],
      [0, 1, 2, 1, 1, 2, 1, 0],
      [1, 2, 1, 2, 2, 1, 2, 1],
      [1, 2, 1, 2, 2, 1, 2, 1],
      [0, 1, 2, 1, 1, 2, 1, 0],
      [0, 0, 1, 2, 2, 1, 0, 0],
      [0, 0, 0, 1, 1, 0, 0, 0],
    ],
    [
      [0, 0, 1, 1, 1, 1, 0, 0],
      [0, 1, 2, 2, 2, 2, 1, 0],
      [1, 2, 1, 2, 2, 1, 2, 1],
      [1, 2, 2, 1, 1, 2, 2, 1],
      [1, 2, 2, 2, 2, 2, 2, 1],
      [0, 1, 2, 2, 2, 2, 1, 0],
      [0, 0, 1, 2, 2, 1, 0, 0],
      [0, 0, 0, 1, 1, 0, 0, 0],
    ],
    [
      [0, 0, 0, 1, 1, 0, 0, 0],
      [0, 0, 1, 2, 2, 1, 0, 0],
      [0, 1, 2, 2, 2, 2, 1, 0],
      [1, 2, 1, 2, 2, 1, 2, 1],
      [1, 2, 1, 2, 2, 1, 2, 1],
      [1, 2, 2, 2, 2, 2, 2, 1],
      [0, 1, 1, 2, 2, 1, 1, 0],
      [0, 0, 0, 1, 1, 0, 0, 0],
    ],
    [
      [0, 0, 1, 1, 1, 1, 0, 0],
      [0, 1, 2, 2, 1, 2, 1, 0],
      [1, 2, 2, 1, 2, 2, 2, 1],
      [1, 1, 1, 2, 2, 1, 2, 1],
      [1, 2, 2, 2, 1, 2, 2, 1],
      [1, 2, 2, 1, 2, 2, 2, 1],
      [0, 1, 2, 2, 2, 1, 1, 0],
      [0, 0, 1, 1, 1, 1, 0, 0],
    ],
    [
      [0, 0, 0, 1, 1, 0, 0, 0],
      [0, 0, 1, 2, 2, 1, 0, 0],
      [0, 1, 2, 1, 1, 2, 1, 0],
      [1, 2, 1, 0, 0, 1, 2, 1],
      [1, 2, 1, 0, 0, 1, 2, 1],
      [0, 1, 2, 1, 1, 2, 1, 0],
      [0, 0, 1, 2, 2, 1, 0, 0],
      [0, 0, 0, 1, 1, 0, 0, 0],
    ],
    [
      [0, 1, 1, 1, 1, 1, 1, 0],
      [1, 2, 2, 2, 2, 2, 2, 1],
      [1, 2, 1, 1, 2, 2, 2, 1],
      [0, 1, 0, 1, 2, 2, 1, 0],
      [0, 0, 1, 2, 2, 1, 0, 0],
      [0, 1, 2, 2, 1, 0, 0, 0],
      [1, 2, 2, 1, 0, 0, 0, 0],
      [1, 1, 1, 0, 0, 0, 0, 0],
    ],
  ];
}

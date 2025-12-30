import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isSubscribed = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    _isSubscribed = prefs.getBool('subscribed') ?? false;
    setState(() => _isLoaded = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _isSubscribed ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}

Future<void> saveSubscription() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('subscribed', true);
}

Future<void> resetSubscription() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('subscribed');
}

//
// ---------------- ONBOARDING ----------------
//

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _controller,
        children: [
          _page(
            context,
            'Добро пожаловать',
            'Простое приложение с подпиской',
            next: true,
          ),
          _page(context, 'Готовы начать?', 'Нажмите продолжить', button: true),
        ],
      ),
    );
  }

  Widget _page(
    BuildContext context,
    String title,
    String text, {
    bool button = false,
    bool next = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Text(text, textAlign: TextAlign.center),

          if (next) ...[
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                _controller.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text('Далее'),
            ),
          ],

          if (button) ...[
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                );
              },
              child: const Text('Продолжить'),
            ),
          ],
        ],
      ),
    );
  }
}
//
// ---------------- PAYWALL ----------------
//

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  String _selectedPlan = 'month';

  Widget _planCard(String id, String title, String price) {
    final bool selected = _selectedPlan == id;

    return Card(
      color: selected ? Colors.blue.shade50 : null,
      child: ListTile(
        title: Text(title),
        subtitle: Text(price),
        trailing: selected
            ? const Icon(Icons.check_circle, color: Colors.blue)
            : const Icon(Icons.circle_outlined),
        onTap: () {
          setState(() {
            _selectedPlan = id;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Подписка')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _planCard('month', 'Месяц', '199 ₽ / месяц'),
            _planCard('year', 'Год', '1499 ₽ / год (−37%)'),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                await saveSubscription();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              },
              child: Text(
                _selectedPlan == 'year'
                    ? 'Оформить годовую подписку'
                    : 'Оформить месячную подписку',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//
// ---------------- HOME ----------------
//

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Главный экран'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Сброс подписки',
            onPressed: () async {
              await resetSubscription();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (_, i) => ListTile(
          leading: const Icon(Icons.star),
          title: Text('Элемент ${i + 1}'),
        ),
      ),
    );
  }
}

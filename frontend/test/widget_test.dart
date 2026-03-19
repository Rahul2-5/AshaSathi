import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/auth/cubit/login_cubit.dart';
import 'package:frontend/main.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/splash/splash_page.dart';

void main() {
  testWidgets('MyApp renders splash shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => LoginCubit(AuthService()),
        child: const MyApp(),
      ),
    );

    expect(find.byType(SplashPage), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    expect(find.byType(MyApp), findsOneWidget);
  });
}

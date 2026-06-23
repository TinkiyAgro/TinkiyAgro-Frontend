import 'package:flutter/material.dart';
import 'core/session_manager.dart';
import 'core/app_navigator.dart';
import 'core/offline/sync_coordinator.dart';
import 'features/auth/presentation/pages/welcome_page.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'features/auth/presentation/pages/role_selection_page.dart';
import 'shared/presentation/page/home_page.dart';
import 'features/catalog/presentation/pages/product_filters_page.dart';
import 'features/catalog/presentation/pages/product_detail_page.dart';
import 'features/catalog/presentation/pages/product_section_page.dart';
import 'features/farmer/presentation/pages/add_product_page.dart';
import 'features/farmer/presentation/pages/farmer_courier_status_page.dart';
import 'features/farmer/presentation/pages/farmer_delivery_confirm_page.dart';
import 'features/farmer/presentation/pages/farmer_deliveries_page.dart';
import 'features/farmer/presentation/pages/farmer_pickup_points_page.dart';
import 'features/orders/presentation/pages/consumer_orders_page.dart';
import 'features/orders/presentation/pages/order_detail_page.dart';
import 'features/orders/presentation/pages/checkout_shipping_page.dart';
import 'features/orders/presentation/pages/checkout_address_page.dart';
import 'features/orders/presentation/pages/checkout_payment_page.dart';
import 'features/courier/presentation/pages/courier_home_page.dart';
import 'features/courier/presentation/pages/courier_delivery_page.dart';
import 'features/reviews/presentation/pages/reviews_page.dart';
import 'features/reviews/presentation/pages/write_review_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionManager().loadSession();
  SyncCoordinator.instance.start();
  runApp(const TinkiyAgroApp());
}

class TinkiyAgroApp extends StatelessWidget {
  const TinkiyAgroApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionManager();
    String initialRoute = '/welcome';
    if (session.isLoggedIn) {
      initialRoute = session.rol == 'REPARTIDOR' ? '/courier_home' : '/home';
    }

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'TinkiyAgro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5CA399),
          primary: const Color(0xFF5CA399),
          secondary: const Color(0xFF1E3A32),
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
          ),
        ),
      ),
      initialRoute: initialRoute,
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/auth': (context) => const AuthPage(),
        '/role_selection': (context) => const RoleSelectionPage(),
        '/home': (context) => const HomePage(),
        '/filtros': (context) => const FiltrosProductoPage(),
        '/detalle_producto': (context) => const DetalleProductoPage(),
        '/seccion_productos': (context) => const SeccionProductosPage(),
        '/add_product': (context) => const AddProductPage(),
        '/write_review': (context) => WriteReviewsPage(
          productId:
              ModalRoute.of(context)!.settings.arguments as String? ?? '',
        ),
        '/resenas': (context) => const ResenasPage(),
        '/consumer_orders': (context) => const ConsumerOrdersPage(),
        '/order_detail': (context) => const OrderDetailPage(),
        '/checkout_envio': (context) => const CheckoutEnvioPage(),
        '/checkout_direccion': (context) => const CheckoutDireccionPage(),
        '/checkout_pago': (context) => const CheckoutPagoPage(),
        '/farmer_courier_status': (context) => const FarmerCourierStatusPage(),
        '/farmer_delivery_confirm': (context) =>
            const FarmerDeliveryConfirmPage(),
        '/farmer_entrega_form': (context) => const FarmerEntregaFormPage(),
        '/farmer_pickup_points': (context) => const FarmerPickupPointsPage(),
        '/courier_home': (context) => const CourierHomePage(),
        '/courier_delivery': (context) => const CourierDeliveryPage(),
      },
    );
  }
}

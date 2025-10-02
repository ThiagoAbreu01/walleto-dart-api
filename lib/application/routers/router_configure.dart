import 'package:walleto_dart_api/modules/user/user_router.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:walleto_dart_api/application/routers/i_router.dart';

class RouterConfigure {
  final Router _router;

  final List<IRouter> _routers = [
    UserRouter(),

    // HistoricoRoute()
  ];

  RouterConfigure(this._router);

  void configure() => _routers.forEach((route) {
    return route.configure(_router);
  });
}

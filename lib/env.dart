import 'package:envied/envied.dart';

part 'env.g.dart';

@envied
abstract class Env {
  @EnviedField(varName: 'MODE', obfuscate: true)
  static String mode = _Env.mode;

  static const String _modeAdvisor = "advisor";
  static const String _modeUser = "user";

  static bool get isAdvisor => mode == _modeAdvisor;
  static bool get isUser => mode == _modeUser;
}

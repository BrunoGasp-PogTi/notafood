/// Endereço base da API do NotaFood.
///
/// Padrão: `http://10.0.2.2:6001`, o endereço que o emulador Android usa
/// para acessar o `localhost` da máquina host. A porta é 6001 porque 5000 e
/// 5001 já estão ocupadas por outros processos nesta máquina.
///
/// Pode ser sobrescrito em tempo de build/execução sem editar código:
///
/// ```bash
/// flutter run --dart-define=BASE_URL=http://192.168.15.5:6001
/// ```
///
/// Use isso para apontar para o IP da máquina na rede local ao testar em um
/// device físico.
class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://192.168.15.5:6001',
  );
}

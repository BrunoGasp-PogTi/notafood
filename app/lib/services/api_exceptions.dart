/// Lançada quando o backend responde HTTP 404 com `encontrado: false`.
class ProdutoNaoEncontradoException implements Exception {
  final String codigo;
  final String mensagem;

  const ProdutoNaoEncontradoException({
    required this.codigo,
    required this.mensagem,
  });

  @override
  String toString() => mensagem;
}

/// Erros de rede/servidor que não são "produto não encontrado".
class ApiException implements Exception {
  final String mensagem;

  const ApiException(this.mensagem);

  @override
  String toString() => mensagem;
}

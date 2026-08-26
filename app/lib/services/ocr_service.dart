import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Reconhecimento de texto (OCR) local via ML Kit: roda no aparelho, sem
/// custo, sem chave de API e sem depender de internet.
class OcrService {
  final TextRecognizer _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> lerTexto(String caminhoImagem) async {
    final imagem = InputImage.fromFilePath(caminhoImagem);
    final resultado = await _recognizer.processImage(imagem);
    return resultado.text;
  }

  void dispose() => _recognizer.close();
}

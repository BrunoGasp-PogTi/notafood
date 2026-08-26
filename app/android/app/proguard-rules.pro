# O app usa apenas o reconhecimento de texto em latino (TextRecognitionScript.latin).
# O R8 encontra referências às classes dos outros scripts (chinês, devanagari,
# japonês, coreano) mesmo sem usá-las, porque o pacote base do ML Kit as
# referencia condicionalmente. Sem esses módulos de idioma como dependência,
# o R8 falha achando que são classes "faltando" — na prática nunca são usadas.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Músicas para Estudar

Aplicativo Android de concentração com catálogo de música clássica e brasileira, biblioteca pesquisável e timer de foco.

## Estado atual

- Interface Jetpack Compose com Início, Explorar, Foco e Biblioteca.
- Catálogo demonstrativo de compositores e obras para a curadoria inicial.
- Timer de 25, 50 e 90 minutos.
- 17 arquivos MP3 locais incluídos no APK, nas categorias Barroco e Piano para estudar.
- Reprodução local integrada com Media3/ExoPlayer.
- Metadados de atribuição incluídos em `app/src/main/assets/catalogo.json`.
- Todas as 36 capas estão incluídas em WebP otimizado em `app/src/main/assets/capas/`.
- A build debug usa o pacote separado `br.com.musicaspara.estudar.debug` para não conflitar com a instalação da Play Store.

## Inclusão de áudio

Cada faixa publicada deve registrar a composição, gravação, intérprete, fonte, licença, território e data de verificação. Uma composição em domínio público não torna automaticamente uma gravação reutilizável.

As referências do acervo estão em `ATRIBUICOES.md` e também são empacotadas no APK para consulta offline.

As faixas devem continuar sendo verificadas antes da publicação. A reprodução atual é local; a próxima etapa técnica é adicionar `MediaSessionService` para controles de reprodução em segundo plano e na notificação.

## Build

```bash
./gradlew test lintDebug bundleRelease
```

O Gradle usa `keystore.properties` quando esse arquivo existe. Crie-o localmente com:

```properties
storeFile=release-upload.jks
storePassword=SENHA_DO_KEYSTORE
keyAlias=upload
keyPassword=SENHA_DA_CHAVE
```

Sem esse arquivo, o bundle é gerado para validação local, mas permanece sem assinatura de upload e não deve ser enviado ao Google Play. Nunca versione o arquivo de propriedades ou a chave.

O release atual usa `versionCode 4`.

O player possui mini-player persistente acima da navegação, controles de pausa/retomada/parada e `PlaybackService` para permitir reprodução em segundo plano e integração com os controles de mídia do Android.

A aba Perfil apresenta minutos estudados e músicas iniciadas, salvos localmente no aparelho.

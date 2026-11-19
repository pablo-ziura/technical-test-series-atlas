# Series Atlas

Prueba técnica iOS para buscar series y consultar su sinopsis, géneros, idioma y valoración con la API pública de [TVmaze](https://www.tvmaze.com/api).

La app conserva por ahora la interfaz de plantilla. Está implementado el paquete de red genérico `SeriesAtlasNetwork`; la integración con TVmaze, las capas de negocio y las pantallas están pendientes.

## Ejecutar el proyecto

Se necesita Xcode 27.2 y un simulador compatible. La app, sus tests y el paquete de red usan el modo de lenguaje **Swift 6**.

1. Abrir `SeriesAtlas.xcodeproj`.
2. Seleccionar el esquema `SeriesAtlas` y un simulador compatible.
3. Ejecutar con `⌘R`. Con `⌘U` se ejecuta el plan compartido `SeriesAtlas`, que incluye los tests de la app, de interfaz y del paquete de red.

La API prevista no requiere claves ni credenciales.

## Capa de red

`Packages/SeriesAtlasNetwork` es un paquete SPM local sin dependencias externas. Expone `NetworkClientProtocol` y un `NetworkClient` inmutable para peticiones GET y respuestas `Decodable & Sendable`.

El cliente recibe la URL base y una `URLSession` por constructor, codifica parámetros con `URLComponents` y valida respuestas HTTP. Conserva los errores de transporte y decodificación; la cancelación se propaga como `CancellationError`. Cada operación crea su propio decoder y procesa la respuesta fuera de `MainActor`.

Los tests usan Swift Testing y transportes controlados independientes. Cubren peticiones, respuestas, errores, cancelación y llamadas concurrentes, sin acceder a la red ni usar esperas arbitrarias.

El paquete figura como dependencia local en **Package Dependencies**. Para ejecutar sus tests desde el esquema de la app, el target `SeriesAtlasNetworkTests` del proyecto compila las mismas fuentes de `Packages/SeriesAtlasNetwork/Tests/SeriesAtlasNetworkTests`, mediante una carpeta sincronizada. No se duplican archivos de tests. El paquete conserva su propio target de SwiftPM para probarlo de forma independiente; ambas configuraciones deben mantenerse coherentes.

## Diseño pendiente: MVVM y capas

La implementación funcional combinará MVVM con separación e inyección por constructor:

- **Domain:** modelos, casos de uso y contrato del repositorio, sin conocer la implementación de red.
- **Data:** servicio de TVmaze, DTOs, mapeos, caché y repositorio; utilizará el paquete de red.
- **Presentation:** vistas SwiftUI y ViewModels aislados en `MainActor`, dependientes de Domain.

La composición de las dependencias se realizará en el punto de entrada de la app. La búsqueda tendrá un debounce de 300 ms, cancelará el trabajo anterior y descartará respuestas que ya no correspondan a la consulta vigente. Una consulta vacía limpiará el estado.

La caché será en memoria, por consulta sin espacios en los extremos y en minúsculas. Su validez será de tres minutos desde una respuesta correcta; una entrada inválida al alcanzar su expiración requerirá red. Los errores y las búsquedas canceladas no se almacenarán. El tiempo se inyectará para probar estos límites sin esperas reales.

## API prevista

La búsqueda utilizará `GET https://api.tvmaze.com/search/shows?q={query}`. La respuesta incluye la información necesaria para el detalle, que no requerirá otra petición. Se tratarán los campos nulos y la sinopsis HTML para mostrar texto legible.

Los datos están sujetos a la licencia CC BY-SA de TVmaze. Cada ficha incluirá un enlace a la página original como atribución. Véanse las [condiciones de uso de la API](https://www.tvmaze.com/api#licensing).

## Validación e integración continua

Para ejecutar en local la misma selección de tests que en CI:

```sh
swift test --package-path Packages/SeriesAtlasNetwork --enable-code-coverage

xcodebuild -project SeriesAtlas.xcodeproj -scheme SeriesAtlas \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.2' \
  -enableCodeCoverage YES \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO test
```

El primer comando ejecuta los tests nativos del paquete en macOS. El segundo necesita un iPhone 17 con iOS 27.2 instalado y ejecuta el mismo plan que `⌘U`: `SeriesAtlasTests`, `SeriesAtlasUITests` y `SeriesAtlasNetworkTests`. Los dos primeros conservan ejemplos de la plantilla; sus resultados validan la infraestructura, no la funcionalidad de búsqueda pendiente.

El workflow [iOS CI](.github/workflows/ios-ci.yml) mantiene el check **Build and tests** en las PR hacia `develop` y `main`. Usa Xcode 27.2, ejecuta los tests nativos del paquete y compila la app y los tests con `build-for-testing` antes de usar `test-without-building`. Comprueba que se hayan generado todos los bundles del plan para detectar targets omitidos por Xcode.

La cobertura es informativa, sin umbral obligatorio. Los logs, la cobertura JSON del paquete, el informe de cobertura de la app y los resultados `.xcresult` se conservan durante siete días. Las ejecuciones sustituidas se cancelan y cada fase tiene un tiempo máximo. Los resultados observados en GitHub se consultan en la PR o en Actions; también se admite ejecución manual cuando el workflow esté en la rama predeterminada.

## Flujo de trabajo

El desarrollo se realiza en ramas `feature/<description>` creadas desde `develop`, con integración mediante PR. La integración en `main` también se realiza mediante PR.

Las protecciones de ambas ramas se configuran en GitHub: check **Build and tests** satisfactorio, rama actualizada y bloqueo de borrados y force pushes. Son independientes del fichero del workflow.

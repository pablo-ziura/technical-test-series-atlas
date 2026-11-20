# Series Atlas

Prueba técnica iOS para buscar series y personas con la API pública de [TVmaze](https://www.tvmaze.com/api) y consultar sus fichas.

La app conserva por ahora la interfaz de plantilla. Están implementados el paquete de red genérico `SeriesAtlasNetwork` y las capas Domain y Data. La composición de dependencias y las pantallas de búsqueda están pendientes.

## Ejecutar el proyecto

Se necesita Xcode 27.2 y un simulador compatible. La app, sus tests y el paquete de red usan el modo de lenguaje **Swift 6**.

1. Abrir `SeriesAtlas.xcodeproj`.
2. Seleccionar el esquema `SeriesAtlas` y un simulador compatible.
3. Ejecutar con `⌘R`. Con `⌘U` se ejecuta el plan compartido `SeriesAtlas`, que incluye los tests de la app, de interfaz y del paquete de red.

La API no requiere claves ni credenciales.

## Capa de red

`Packages/SeriesAtlasNetwork` es un paquete SPM local sin dependencias externas. Expone `NetworkClientProtocol` y un `NetworkClient` inmutable para peticiones GET y respuestas `Decodable & Sendable`.

El cliente recibe la URL base y una `URLSession` por constructor, codifica parámetros con `URLComponents` y valida respuestas HTTP. Conserva los errores de transporte y decodificación; la cancelación se propaga como `CancellationError`. Cada operación crea su propio decoder y procesa la respuesta fuera de `MainActor`.

Los tests usan Swift Testing y transportes controlados independientes. Cubren peticiones, respuestas, errores, cancelación y llamadas concurrentes, sin acceder a la red ni usar esperas arbitrarias.

El paquete figura como dependencia local en **Package Dependencies**. Para ejecutar sus tests desde el esquema de la app, el target `SeriesAtlasNetworkTests` del proyecto compila las mismas fuentes de `Packages/SeriesAtlasNetwork/Tests/SeriesAtlasNetworkTests`, mediante una carpeta sincronizada. No se duplican archivos de tests. El paquete conserva su propio target de SwiftPM para probarlo de forma independiente; ambas configuraciones deben mantenerse coherentes.

## Capa de dominio

`SeriesAtlas/Domain` contiene `Show`, `Person` y los casos de uso `SearchShowsUseCase` y `SearchPeopleUseCase` con sus protocolos. Se organiza en carpetas `Entities` y `UseCases`, con un tipo por archivo y sin dependencias de SwiftUI ni del paquete de red. Los modelos y los contratos son `Sendable`.

Los modelos inmutables reúnen los datos de listado y detalle. `Show` conserva nombre, sinopsis en texto, géneros, idioma, valoración, imagen y enlace de atribución a TVmaze. `Person` conserva nombre, país, género, nacimiento, fallecimiento, imagen y enlace de atribución. Ambos respetan los datos opcionales; las fechas de personas se mantienen como cadenas tal como llegan de la API. Data convierte la sinopsis HTML de las series en texto legible.

Cada caso de uso recibe su repositorio por constructor y transmite la consulta sin modificarla, incluidas las consultas vacías. Propaga resultados y errores, y comprueba la cancelación después de recibir la respuesta. Sus tests usan Swift Testing, con un mock configurable y una instancia independiente del caso de uso por test. La cancelación se controla desde el mock, sin esperas temporales.

## Capa de datos

`SeriesAtlas/Data` contiene DTOs, mapeos, servicios y repositorios. `ShowsService` y `PeopleService` reciben `NetworkClientProtocol`, consultan `search/shows` y `search/people` respectivamente y devuelven modelos en el orden de la respuesta. Conservan los opcionales y prefieren la imagen `medium`, con respaldo en `original`. Una imagen inválida se omite; un enlace obligatorio inválido produce un error. Para las series, los géneros ausentes se convierten en una lista vacía y la sinopsis se convierte con el importador HTML nativo en `MainActor`. El mapeo de personas es síncrono y conserva el nombre del país. Los servicios conservan el aislamiento del llamador; `NetworkClient` ejecuta la petición y la decodificación fuera del actor del llamador.

`ShowsRepository` y `PeopleRepository` reciben sus servicios por constructor y delegan las búsquedas sin modificar la consulta, preservando resultados, errores y cancelación. Sus contratos se definen en Data. La caché temporal por consulta queda para una entrega posterior.

La cancelación se comprueba al entrar y salir del cliente de red, al terminar el mapeo en los servicios —también con resultados vacíos— y al retomar el caso de uso tras esperar al repositorio. Los servicios reconocen también `URLError.cancelled` como `CancellationError`. Los repositorios propagan la cancelación sin repetir esas comprobaciones. La conversión HTML síncrona que ya haya empezado termina antes de poder descartar su resultado.

## Arquitectura: MVVM y capas

El flujo previsto es **Vista → ViewModel → Caso de uso → Repositorio → Servicio → Cliente de red**, con inyección por constructor:

- **Domain, implementado:** modelos y casos de uso de búsqueda de series y personas, que utilizan los contratos de repositorio definidos en Data.
- **Data, implementada:** servicios de TVmaze, DTOs, mapeos, contratos e implementaciones de los repositorios; utiliza el paquete de red. La caché está pendiente.
- **Presentation, pendiente:** vistas SwiftUI y ViewModels aislados en `MainActor`, dependientes de Domain.

La composición de las dependencias se realizará en el punto de entrada de la app. El ViewModel recortará espacios y saltos de línea exteriores de la consulta y limpiará el estado ante consultas vacías. La búsqueda tendrá un debounce de 300 ms, cancelará el trabajo anterior y descartará respuestas que ya no correspondan a la consulta vigente.

## API

Los servicios utilizan `GET /search/shows?q={query}` y `GET /search/people?q={query}` al recibir un cliente configurado con la URL base `https://api.tvmaze.com`. Las respuestas incluyen los datos de los modelos de detalle, sin peticiones adicionales.

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

El primer comando ejecuta los tests nativos del paquete en macOS. El segundo necesita un iPhone 17 con iOS 27.2 instalado y ejecuta el mismo plan que `⌘U`: `SeriesAtlasTests`, `SeriesAtlasUITests` y `SeriesAtlasNetworkTests`. Los tests de la app cubren los casos de uso, repositorios, servicios y mapeos de series y personas, errores y cancelación, además del recorrido completo con red simulada. Usan mocks configurables y fixtures en archivos Swift separados, sin acceder a TVmaze. Los tests de interfaz conservan los ejemplos de la plantilla y todavía no validan pantallas de búsqueda.

El workflow [iOS CI](.github/workflows/ios-ci.yml) mantiene el check **Build and tests** en las PR hacia `develop` y `main`. Usa Xcode 27.2, ejecuta los tests nativos del paquete y compila la app y los tests con `build-for-testing` antes de usar `test-without-building`. Comprueba que se hayan generado todos los bundles del plan para detectar targets omitidos por Xcode.

La cobertura es informativa, sin umbral obligatorio. Los logs, la cobertura JSON del paquete, el informe de cobertura de la app y los resultados `.xcresult` se conservan durante siete días. Las ejecuciones sustituidas se cancelan y cada fase tiene un tiempo máximo. Los resultados observados en GitHub se consultan en la PR o en Actions; también se admite ejecución manual cuando el workflow esté en la rama predeterminada.

## Flujo de trabajo

El desarrollo se realiza en ramas `feature/<description>` creadas desde `develop`, con integración mediante PR. La integración en `main` también se realiza mediante PR.

Las protecciones de ambas ramas se configuran en GitHub: check **Build and tests** satisfactorio, rama actualizada y bloqueo de borrados y force pushes. Son independientes del fichero del workflow.

# Series Atlas

Prueba técnica iOS para buscar series y personas con la API pública de [TVmaze](https://www.tvmaze.com/api) y consultar sus fichas.

La app permite buscar series y personas y abrir sus fichas desde las pestañas **Shows** y **People**. **Settings** muestra versión, compilación y atribución. La interfaz está en inglés y utiliza componentes nativos de SwiftUI. Están implementados el paquete de red `SeriesAtlasNetwork`, las capas Domain, Data y Presentation y la caché temporal por consulta.

## Ejecutar el proyecto

Se necesita Xcode 27.2 y un simulador compatible. La app, sus tests y el paquete de red usan el modo de lenguaje **Swift 6**.

1. Abrir `SeriesAtlas.xcodeproj`.
2. Seleccionar el esquema `SeriesAtlas` y un simulador compatible.
3. Ejecutar con `⌘R`. Con `⌘U` se ejecuta el plan compartido `SeriesAtlas`, que incluye los tests de la app, de interfaz y del paquete de red.

La API no requiere claves ni credenciales.

La URL base de la API, las rutas de búsqueda y los enlaces de Settings se definen en `SeriesAtlas/Resources/AppConfiguration.plist`. `SeriesAtlasApp` carga y valida una configuración inmutable al arrancar e inyecta cada valor en su destinatario; un recurso ausente, incompleto o inválido produce un error explícito de configuración. Para otro target se puede incluir un recurso con el mismo nombre y valores distintos. Las URL recibidas de la API y los fixtures de tests y previews se mantienen independientes de esta configuración.

## Capa de red

`Packages/SeriesAtlasNetwork` es un paquete SPM local sin dependencias externas. Expone `NetworkClientProtocol` y un `NetworkClient` inmutable para peticiones GET y respuestas `Decodable & Sendable`.

El cliente recibe la URL base y una `URLSession` por constructor, codifica parámetros con `URLComponents` y valida respuestas HTTP. Conserva los errores de transporte y decodificación; la cancelación se propaga como `CancellationError`. Cada operación crea su propio decoder y procesa la respuesta fuera de `MainActor`.

Los tests usan Swift Testing y transportes controlados independientes. Cubren peticiones, respuestas, errores, cancelación y llamadas concurrentes, sin acceder a la red ni usar esperas arbitrarias.

El paquete figura como dependencia local en **Package Dependencies** y sus tests se ejecutan con SwiftPM. El esquema de la app también declara un target `SeriesAtlasNetworkTests`, pero actualmente no tiene fuentes asignadas y ejecuta cero tests; queda pendiente corregir esa configuración en Xcode. La ejecución de `swift test` sigue siendo necesaria para validar el paquete.

## Capa de dominio

`SeriesAtlas/Domain` contiene `Show`, `Person`, los contratos `ShowsRepositoryProtocol` y `PeopleRepositoryProtocol` y los casos de uso `SearchShowsUseCase` y `SearchPeopleUseCase` con sus protocolos. Se organiza en carpetas `Entities`, `Repositories` y `UseCases`, con un tipo por archivo y sin dependencias de SwiftUI ni del paquete de red. Los modelos y los contratos son `Sendable`.

Los modelos inmutables reúnen los datos de listado y detalle. `Show` conserva nombre, sinopsis en texto, géneros, idioma, valoración, imagen y enlace de atribución a TVmaze. `Person` conserva nombre, país, género, nacimiento, fallecimiento, imagen y enlace de atribución. Ambos respetan los datos opcionales; las fechas de personas se mantienen como cadenas tal como llegan de la API. Data convierte la sinopsis HTML de las series en texto legible.

Cada caso de uso recibe su repositorio por constructor y transmite la consulta sin modificarla, incluidas las consultas vacías. Propaga resultados y errores, y comprueba la cancelación después de recibir la respuesta. Sus tests usan Swift Testing, con un mock configurable y una instancia independiente del caso de uso por test. La cancelación se controla desde el mock, sin esperas temporales.

## Capa de datos

`SeriesAtlas/Data` contiene DTOs, mapeos, servicios y repositorios. `ShowsService` y `PeopleService` reciben `NetworkClientProtocol`, consultan `search/shows` y `search/people` respectivamente y devuelven modelos en el orden de la respuesta. Conservan los opcionales y prefieren la imagen `medium`, con respaldo en `original`. Una imagen inválida se omite; un enlace obligatorio inválido produce un error. Para las series, los géneros ausentes se convierten en una lista vacía y la sinopsis se convierte con el importador HTML nativo en `MainActor`. El mapeo de personas es síncrono y conserva el nombre del país. Los servicios conservan el aislamiento del llamador; `NetworkClient` ejecuta la petición y la decodificación fuera del actor del llamador.

`ShowsRepository` y `PeopleRepository` reciben sus servicios y una caché por constructor. Cada uno conserva su propia instancia del actor `QueryCache`, compartiendo el mecanismo pero no los datos. Las claves recortan espacios y saltos de línea exteriores y pasan a minúsculas, sin alterar espacios interiores; el servicio recibe la consulta original. Las respuestas correctas, incluidas las vacías, se guardan en memoria durante 180 segundos desde su almacenamiento. Un acierto evita el servicio sin renovar la expiración; al alcanzar ese instante se consulta de nuevo. Los errores y las respuestas canceladas no se almacenan, y un fallo de refresco se propaga sin devolver datos expirados. La función de tiempo es inyectable y síncrona, lo que permite probar los límites sin esperas reales. No hay persistencia ni agrupación de peticiones concurrentes. Los contratos se definen en Domain y Data proporciona sus implementaciones.

La cancelación se comprueba al entrar y salir del cliente de red, al terminar el mapeo en los servicios —también con resultados vacíos— y al retomar el caso de uso tras esperar al repositorio. Los servicios reconocen también `URLError.cancelled` como `CancellationError`. Cada repositorio comprueba una vez tras leer la caché; el actor comprueba inmediatamente antes de escribir, sin suspensiones internas. Los ViewModels descartan resultados y errores cancelados antes de actualizar la pantalla. La conversión HTML síncrona que ya haya empezado termina antes de poder descartar su resultado.

La sesión de TVmaze se configura en `SeriesAtlasApp` con `urlCache = nil`, que [desactiva la caché HTTP local](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/urlcache). Así, una consulta ausente o expirada llega a la red y no reutiliza silenciosamente una respuesta de `URLCache`. Esta configuración no modifica el cliente de red genérico ni controla las cachés del servidor.

## Arquitectura: MVVM y capas

El flujo de búsqueda es **Vista → ViewModel → Caso de uso → Repositorio → Servicio → Cliente de red**, con inyección por constructor:

- **Domain, implementado:** modelos, contratos de repositorio y casos de uso de búsqueda de series y personas.
- **Data, implementada:** servicios de TVmaze, DTOs, mapeos, implementaciones de los contratos de repositorio de Domain y caché temporal; utiliza el paquete de red.
- **Presentation:** vistas SwiftUI, ViewModels de búsqueda y coordinadores por feature, aislados en `MainActor` y dependientes de Domain.

`SeriesAtlasApp` compone explícitamente cliente, servicios, cachés, repositorios y casos de uso. `AppCoordinator` conserva el router y los coordinadores de Shows, People y Settings, manteniendo las cachés disponibles entre búsquedas durante la sesión. Los coordinadores construyen pantallas y conservan sus ViewModels; `AppRouter` mantiene la pestaña seleccionada y las pilas tipadas de Shows y People. Cada pestaña tiene su propio `NavigationStack` y conserva consulta, resultados y detalle al cambiar de sección. Los detalles reciben el modelo seleccionado y no necesitan otra petición ni un ViewModel propio.

La búsqueda empieza al pulsar el botón **Search** o confirmar desde el teclado, recortando espacios y saltos de línea exteriores. El campo de texto tiene borde y el botón permanece disponible durante la carga para poder confirmar otra búsqueda. Editar o vaciar el campo conserva la petición y el estado de la última consulta confirmada. Confirmar otra consulta cancela la anterior y descarta sus resultados y errores tardíos; confirmar una consulta vacía vuelve al estado inicial. Se muestran estados inicial, carga, resultados, sin resultados y error; **Retry** repite la consulta fallida aunque el texto del campo haya cambiado. Una cancelación no se presenta como error. Cambiar de pestaña permite terminar la búsqueda vigente y volver del detalle no repite la petición.

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

El primer comando ejecuta los tests nativos del paquete en macOS. El segundo necesita un iPhone 17 con iOS 27.2 instalado y ejecuta el mismo plan que `⌘U`: `SeriesAtlasTests`, `SeriesAtlasUITests` y `SeriesAtlasNetworkTests`. Los tests unitarios cubren casos de uso, repositorios, servicios, mapeos, errores y cancelación, con red simulada. La caché se prueba con servicios simulados y tiempo controlado: aciertos, expiración exacta, normalización, consultas independientes, resultados vacíos y ausencia de almacenamiento tras errores o cancelación. Los tests unitarios de Presentation cubren estados de búsqueda, respuestas y errores fuera de orden, cancelación al confirmar otra consulta o solo espacios, edición del campo y Retry de la consulta confirmada. Usan casos de uso simulados con continuaciones y esperan la finalización de las tareas, sin red ni esperas temporales.

El test de interfaz existente solo comprueba el lanzamiento de la app; no acredita cobertura funcional de búsqueda ni detalle.

El workflow [iOS CI](.github/workflows/ios-ci.yml) mantiene el check **Build and tests** en las PR hacia `develop` y `main`. Usa Xcode 27.2, ejecuta los tests nativos del paquete y compila la app y los tests con `build-for-testing` antes de usar `test-without-building`. Comprueba que se hayan generado todos los bundles del plan para detectar targets omitidos por Xcode.

La cobertura es informativa, sin umbral obligatorio. Los logs, la cobertura JSON del paquete, el informe de cobertura de la app y los resultados `.xcresult` se conservan durante siete días. Las ejecuciones sustituidas se cancelan y cada fase tiene un tiempo máximo. Los resultados observados en GitHub se consultan en la PR o en Actions; también se admite ejecución manual cuando el workflow esté en la rama predeterminada.

## Flujo de trabajo

El desarrollo se realiza en ramas `feature/<description>` creadas desde `develop`, con integración mediante PR. La integración en `main` también se realiza mediante PR.

Las protecciones de ambas ramas se configuran en GitHub: check **Build and tests** satisfactorio, rama actualizada y bloqueo de borrados y force pushes. Son independientes del fichero del workflow.

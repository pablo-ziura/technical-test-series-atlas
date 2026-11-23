# Series Atlas

Prueba técnica iOS implementada en **Swift 6 y SwiftUI** para demostrar separación de responsabilidades, concurrencia con cancelación, caché temporal y tests unitarios.

La app permite buscar **series de televisión y personas relacionadas con el medio**, mostrar resultados en una lista y navegar a sus fichas. El detalle de series incluye nombre, géneros, idioma, valoración y sinopsis, mientras que el de personas incluye nombre, país, género y fechas disponibles. La interfaz está en inglés y contempla carga, ausencia de resultados, datos opcionales y errores recuperables.

## Arquitectura

Se combina **MVVM en Presentation** con separación en **Domain, Data y Presentation**, organizadas en carpetas dentro del target de la app. El cliente de red es un paquete SPM local, independiente de TVmaze. No hay dependencias externas.

| Área | Responsabilidad |
| --- | --- |
| [Domain](SeriesAtlas/Domain) | Modelos, contratos de repositorio y casos de uso. No conoce SwiftUI, la red ni la caché. |
| [Data](SeriesAtlas/Data) | Repositorios que deciden entre caché y red, servicios de TVmaze, DTOs y mapeos a modelos de dominio. |
| [Presentation](SeriesAtlas/Presentation) | Vistas SwiftUI, ViewModels con estado de búsqueda y coordinadores de navegación. |
| [SeriesAtlasNetwork](Packages/SeriesAtlasNetwork) | Cliente HTTP basado en `URLSession`, validación de respuestas y decodificación JSON. |

Data y Presentation dependen de Domain. El recorrido de una búsqueda sin caché es **Vista → ViewModel → Caso de uso → Repositorio → Servicio → Cliente de red**.

[SeriesAtlasApp](SeriesAtlas/SeriesAtlasApp.swift) compone las dependencias y las inyecta por constructor. Los protocolos permiten sustituir repositorios, servicios y red en los tests. Los coordinadores construyen pantallas y conservan sus ViewModels, y `AppRouter` mantiene rutas tipadas y pilas de navegación independientes por pestaña.

## Búsqueda y cancelación

La búsqueda se confirma con **Search** o desde el teclado. Editar el campo conserva la consulta vigente, y **Retry** repite la consulta fallida. Confirmar una consulta vacía cancela el trabajo pendiente y limpia el estado.

Cada ViewModel conserva su `Task` y la cancela al confirmar otra búsqueda. La cancelación se propaga hasta la petición de red y se comprueba antes de almacenar o publicar resultados: una respuesta o un error tardío no sobrescribe el estado actual. La cancelación no se muestra como error al usuario.

El flujo utiliza `async/await`, con estado de presentación aislado en `MainActor` y petición y decodificación de red fuera de él.

## Caché

[QueryCache](SeriesAtlas/Data/Cache/QueryCache.swift) protege los resultados en memoria mediante un actor. Series y personas utilizan instancias independientes.

- Las claves recortan espacios y saltos de línea exteriores y pasan a minúsculas.
- Las respuestas correctas, incluidas las vacías, se conservan **tres minutos desde su almacenamiento**. Un acierto evita la red y no renueva el plazo.
- Al alcanzar la expiración se consulta la red y se almacena la nueva respuesta correcta.
- No se guardan errores ni respuestas canceladas. El tiempo es inyectable para probar la expiración sin esperas reales.

No hay persistencia en disco ni agrupación de peticiones simultáneas.

## API y datos

Se eligió [TVmaze](https://www.tvmaze.com/api) principalmente porque su API pública **no requiere API key**. Se utilizan `GET /search/shows?q={query}` y `GET /search/people?q={query}`.

El detalle aprovecha el modelo obtenido en la búsqueda, sin otra petición. Data convierte la sinopsis HTML en texto legible y conserva los valores opcionales. Las URL y rutas se definen en [AppConfiguration.plist](SeriesAtlas/Resources/AppConfiguration.plist), se validan al arrancar y se inyectan en sus destinatarios.

Cada ficha enlaza a TVmaze como atribución. Sus datos están sujetos a las [condiciones de uso y licencia CC BY-SA](https://www.tvmaze.com/api#licensing).

## Tests

Los tests unitarios utilizan **Swift Testing** y dependencias simuladas, sin acceder a la API real:

- **Domain:** casos de uso con repositorios mockeados; resultados, errores y cancelación.
- **Data:** caché válida sin red, expiración con tiempo controlado, normalización y consultas independientes; mapeos y errores.
- **Presentation:** estados, cancelación, respuestas fuera de orden, edición y reintento, controlando cuándo termina cada búsqueda.
- **Red:** peticiones, respuestas HTTP, decodificación, cancelación y llamadas concurrentes.

**Los tests funcionales de UI están pendientes.** El test XCTest existente solo lanza la app; no verifica búsqueda ni navegación al detalle.

El workflow [iOS CI](.github/workflows/ios-ci.yml) compila y ejecuta los tests en las PR hacia `develop` y `main`, con el check **Build and tests** y cobertura informativa.

## Ejecución

Abrir `SeriesAtlas.xcodeproj` con **Xcode 27.2**, seleccionar el esquema **SeriesAtlas** y un simulador con **iOS 18.6 o posterior**. `⌘R` ejecuta la app y `⌘U` ejecuta el plan compartido con los tests de la app, de red y el test de UI existente. No se necesitan credenciales ni configuración adicional.

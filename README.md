# Series Atlas

Aplicación iOS para buscar series y consultar su sinopsis, géneros, idioma y valoración. Los datos proceden de la API pública de [TVmaze](https://www.tvmaze.com/api).

El proyecto está en su fase inicial. La arquitectura y los comportamientos descritos a continuación son el diseño previsto, pendiente de implementación.

## Ejecutar el proyecto

Se necesita Xcode 27.2 y un simulador de iOS instalado.

1. Abrir `SeriesAtlas.xcodeproj`.
2. Seleccionar el esquema `SeriesAtlas` y un simulador compatible con el proyecto.
3. Ejecutar con `⌘R`. Para lanzar los tests, usar `⌘U`.

La API no requiere claves ni configuración de credenciales. Los targets de tests contienen por ahora los ejemplos de la plantilla de Xcode.

## API

La búsqueda utilizará `GET https://api.tvmaze.com/search/shows?q={query}`. La respuesta incluye la información necesaria para el detalle, de modo que seleccionar una serie no requerirá otra petición.

Algunos campos pueden ser nulos y la sinopsis puede contener HTML. La presentación contemplará datos ausentes y mostrará la sinopsis como texto legible.

Los datos están sujetos a la licencia CC BY-SA de TVmaze. Cada ficha incluirá un enlace a la página original como atribución. Véanse las [condiciones de uso de la API](https://www.tvmaze.com/api#licensing).

## Arquitectura prevista: MVVM y separación por capas

La arquitectura combinará **MVVM (Model–View–ViewModel)** en la presentación con una separación en tres capas e inyección de dependencias por constructor:

- **Domain:** modelos, casos de uso y contrato del repositorio. Sin dependencias de SwiftUI ni de la implementación de red.
- **Data:** cliente HTTP con `URLSession`, transformación de respuestas, caché e implementación del repositorio.
- **Presentation:** vistas SwiftUI y ViewModels. Las vistas mostrarán el estado y enviarán acciones; los ViewModels invocarán los casos de uso y gestionarán el estado de la interfaz, aislado en `MainActor`.

Data y Presentation dependerán de Domain. La composición de las dependencias se realizará en el punto de entrada de la app.

## Búsqueda y caché

La búsqueda usará `async/await` y un debounce de 300 ms. Cada cambio de consulta cancelará la tarea anterior. Solo la consulta vigente podrá publicar resultados, incluso si una dependencia tarda en atender la cancelación. Una cancelación no se mostrará como un error al usuario.

La caché será en memoria, por consulta normalizada —sin espacios en los extremos y en minúsculas—, con una validez de tres minutos desde que se almacene la respuesta. Una entrada válida se devolverá sin acceder a la red. Si ha expirado, se consultará la API y se reemplazará al recibir una respuesta correcta. Los errores y las búsquedas canceladas no se almacenarán.

## Tests previstos

Los tests unitarios se escribirán con Swift Testing. Se priorizarán estos comportamientos:

- **Domain:** búsqueda mediante un repositorio simulado y propagación de resultados y errores.
- **Data:** reutilización de entradas válidas, expiración y separación entre consultas.
- **Presentation:** cancelación y descarte de respuestas de búsquedas anteriores.

El tiempo y las respuestas de red se controlarán mediante dependencias de prueba, evitando llamadas reales y esperas para comprobar la expiración.

## Integración continua

El workflow [iOS CI](.github/workflows/ios-ci.yml) ejecuta el check **Build and unit tests** en las pull requests hacia `develop` y `main`.

Utiliza Xcode 27.2 y un iPhone 17 con iOS 27.2. Compila la app y los tests con `build-for-testing` y ejecuta `SeriesAtlasTests` con `test-without-building`, sin certificados de firma ni credenciales de la API. La selección actual incluye solo los tests unitarios; los de interfaz quedan fuera de este workflow.

La cobertura se exporta como información, sin un porcentaje mínimo obligatorio. Los logs, el informe de cobertura y los resultados `.xcresult` se conservan durante siete días. Las ejecuciones anteriores de la misma PR se cancelan al recibir nuevos cambios y cada fase tiene un tiempo máximo.

Para ejecutar la misma selección de tests en local, con ese simulador instalado:

```sh
xcodebuild -project SeriesAtlas.xcodeproj -scheme SeriesAtlas \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.2' \
  -only-testing:SeriesAtlasTests -enableCodeCoverage YES \
  CODE_SIGNING_ALLOWED=NO test
```

Actualmente se ejecuta el test de ejemplo de la plantilla; un resultado satisfactorio valida la infraestructura, no el comportamiento funcional previsto. La primera ejecución en GitHub queda pendiente de publicar esta rama y abrir la PR. También se admite ejecución manual cuando el workflow esté en la rama predeterminada del repositorio.

## Flujo de trabajo

Tras la configuración inicial del repositorio, el desarrollo se realizará en ramas `feature/<description>` creadas a partir de `develop`. Los cambios se integrarán en `develop` mediante pull requests para su revisión.

La integración en `main` también se realizará mediante PR. En ambas ramas se configurará un ruleset que exija **Build and unit tests**, mantenga la rama actualizada antes de integrar y bloquee borrados y force pushes. La protección se activa en GitHub, de forma independiente al fichero del workflow.

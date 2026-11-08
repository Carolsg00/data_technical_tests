\# Transformaciones de datos con dbt



\## 1. Arquitectura



El proyecto utiliza \*\*DuckDB\*\* como base de datos local y \*\*dbt Core\*\* como herramienta para realizar las transformaciones, organizar los modelos y validar la calidad de los datos.



El flujo de datos es el siguiente:



`Archivos CSV → DuckDB (RAW) → dbt Staging → dbt Marts`



La arquitectura se divide en tres capas:



\- \*\*RAW:\*\* almacena los datos originales procedentes de los archivos CSV.

\- \*\*Staging:\*\* realiza la limpieza, normalización y conversión de tipos de cada fuente.

\- \*\*Marts:\*\* contiene los modelos finales preparados para su explotación y análisis.



Se ha optado por una arquitectura sencilla y local, suficiente para los volúmenes de datos de la prueba y fácilmente reproducible.



\## 2. Capa RAW



Se cargan siete archivos CSV mediante un script Python (`scripts/load\_raw.py`) en el esquema `raw` de DuckDB.



Las tablas de origen son:



| Tabla | Registros |

|---|---:|

| `raw\_projects` | 11 |

| `raw\_campaigns` | 16 |

| `raw\_routes` | 295 |

| `raw\_visits` | 480 |

| `raw\_workers` | 45 |

| `pos\_omni` | 365 |

| `pos\_gi` | 245 |



Las columnas se ingieren inicialmente como texto (`VARCHAR`) para conservar los valores originales y realizar las conversiones de tipos en la capa de staging.



Esta separación permite mantener una copia de los datos de origen y centralizar las reglas de limpieza en dbt.



\## 3. Capa Staging



Se han creado siete modelos:



\- `stg\_projects`

\- `stg\_campaigns`

\- `stg\_routes`

\- `stg\_visits`

\- `stg\_workers`

\- `stg\_pos\_omni`

\- `stg\_pos\_gi`



\### Transformaciones realizadas



Los modelos de staging incluyen:



\- \*\*Conversión de tipos:\*\* identificadores a `INTEGER`, fechas a `DATE` o `TIMESTAMP`, coordenadas a `DOUBLE` y estados de actividad a `BOOLEAN`.

\- \*\*Limpieza de texto:\*\* eliminación de espacios sobrantes mediante `TRIM`.

\- \*\*Normalización:\*\* unificación de mayúsculas y minúsculas mediante `UPPER`, especialmente en estados, provincias y nombres.

\- \*\*Tratamiento de valores vacíos:\*\* conversión de cadenas vacías en `NULL` mediante `NULLIF`.

\- \*\*Conservación de códigos postales como texto:\*\* evita perder posibles ceros iniciales.

\- \*\*Control de conversiones:\*\* utilización de `TRY\_CAST` para evitar que un valor inválido interrumpa toda la transformación.



Se mantienen los valores nulos cuando representan información ausente en origen, sin sustituirlos por valores inventados.



\### Materialización como vistas



Los siete modelos se materializan como \*\*vistas (`view`)\*\*.



Se ha elegido esta materialización porque los datos tienen un volumen reducido y las transformaciones son relativamente sencillas.



De hecho, las vistas permiten mantener la lógica de transformación sin almacenar una segunda copia física de los datos, reduciendo el almacenamiento y facilitando el mantenimiento.



\## 4. Unificación de establecimientos (`dim\_pos\_unified`)



El modelo `dim\_pos\_unified` integra los establecimientos procedentes de los sistemas \*\*Omni\*\* y \*\*GI\*\*, que utilizan identificadores y estructuras de datos diferentes.



El objetivo es obtener un catálogo unificado en el que cada establecimiento físico esté representado una sola vez.



El modelo se materializa como \*\*tabla (`table`)\*\*, ya que contiene el resultado consolidado de las reglas de matching y se utiliza posteriormente para relacionar las visitas con los establecimientos.



\### Reglas de matching



Se aplican dos reglas de coincidencia:



1\. \*\*Nombre normalizado y código postal:\*\* identifica establecimientos con el mismo nombre estandarizado y código postal.

2\. \*\*Dirección, localidad y código postal:\*\* identifica establecimientos que comparten ubicación, aunque sus nombres sean diferentes.



Se prioriza la primera regla porque utiliza una coincidencia más específica de nombre y código postal. La segunda se aplica únicamente a los establecimientos que todavía no han sido emparejados.



También se evitan emparejamientos repetidos para garantizar que un establecimiento de Omni no se relacione con varios de GI, y viceversa.



\### Clasificación de establecimientos



La dimensión utiliza tres estados:



\- \*\*MATCHED:\*\* el establecimiento aparece en ambos sistemas.

\- \*\*OMNI\_ONLY:\*\* el establecimiento aparece únicamente en Omni.

\- \*\*GI\_ONLY:\*\* el establecimiento aparece únicamente en GI.



Esta clasificación permite identificar coincidencias y diferencias entre ambos catálogos.



\### Resultados de la unificación



De los 365 establecimientos de Omni y los 245 de GI, se identificaron 161 coincidencias.



| Clasificación | Establecimientos |

|---|---:|

| MATCHED | 161 |

| OMNI\_ONLY | 204 |

| GI\_ONLY | 84 |

| \*\*Total unificado\*\* | \*\*449\*\* |



El número de establecimientos unificados se calcula como:



`365 + 245 - 161 = 449`



Los establecimientos coincidentes se contabilizan una sola vez para evitar duplicidades.



De las 161 coincidencias identificadas, 123 cumplen la regla de nombre normalizado y código postal. Las otras 38 se identificaron mediante dirección, localidad y código postal.



\### Trazabilidad



Se conservan los identificadores originales:



\- `intervention\_point\_id` de Omni.

\- `ext\_id` de GI.



También se almacena el estado del matching, la regla aplicada y la procedencia del registro.



Esto permite relacionar los establecimientos con otras tablas, como las visitas, y explicar por qué dos registros se han considerado correspondientes al mismo establecimiento.



\## 5. Modelo incremental (`fct\_visits`)



El modelo `fct\_visits` contiene las visitas y su relación con los establecimientos de `dim\_pos\_unified`.



Se materializa como \*\*tabla incremental (`incremental`)\*\* para procesar las visitas nuevas o actualizadas sin reconstruir toda la información en cada ejecución.



Esta estrategia permite mejorar la eficiencia cuando aumenta el volumen de datos.



\### Configuración



\- \*\*Clave única (`unique\_key`):\*\* `visit\_id`.

\- \*\*Campo de actualización:\*\* `updated\_at`.

\- \*\*Estrategia incremental:\*\* `merge`.



\### Justificación



\*\*`visit\_id` como clave única\*\*



Permite identificar cada visita y evitar que una actualización genere un registro duplicado.



\*\*`updated\_at` como campo de actualización\*\*



Se utiliza para detectar las visitas que se han modificado desde la última carga. El modelo compara este campo con el máximo `updated\_at` almacenado.



\*\*`merge` como estrategia\*\*



Permite insertar visitas nuevas y actualizar las existentes cuando coinciden sus identificadores.



De esta manera, se mantiene una única fila por visita.



\### Relación con la dimensión



`fct\_visits` utiliza `intervention\_point\_id` para recuperar el identificador `pos\_unified\_id` desde `dim\_pos\_unified`.



Esto permite asociar las visitas con el catálogo unificado de establecimientos, conservando la relación original con Omni.



\### Validación de la incrementalidad



Se realizaron dos pruebas:



\*\*Prueba 1. Segunda ejecución sin modificaciones\*\*



Se ejecutó el modelo incremental dos veces consecutivas.



En ambas ejecuciones se mantuvieron:



\- 480 visitas.

\- 480 identificadores únicos.

\- 0 visitas sin establecimiento relacionado.



Se comprobó que una segunda ejecución no generaba registros duplicados.



\*\*Prueba 2. Actualización de una visita existente\*\*



Se modificó temporalmente la visita con `visit\_id = 1`:



\- Estado original: `OK`.

\- Estado actualizado: `INCID`.

\- Fecha original de actualización: `2026-05-29`.

\- Nueva fecha de actualización: `2026-09-09`.



Tras ejecutar el modelo incremental, se comprobó que la visita se había actualizado correctamente sin crear una fila adicional.



El número total de registros se mantuvo en 480.



Posteriormente, se restauraron los datos originales y se ejecutó una carga completa mediante `--full-refresh`.



Estas pruebas confirmaron el funcionamiento básico de la estrategia incremental y del proceso de actualización mediante `merge`.



\## 6. Calidad de datos



Se han implementado tests automáticos de dbt para comprobar la integridad de las tablas y las relaciones entre modelos.



\### Tests genéricos



\- \*\*`unique`:\*\* verifica que los identificadores no estén duplicados.

\- \*\*`not\_null`:\*\* comprueba que los campos obligatorios tengan valores informados.

\- \*\*`relationships`:\*\* verifica que las claves de relación existan en las tablas correspondientes.

\- \*\*`accepted\_values`:\*\* comprueba que determinados campos solo contengan valores permitidos.



Por ejemplo, se comprueba que cada campaña esté asociada a un proyecto existente y que cada visita tenga un establecimiento válido.



En `dim\_pos\_unified`, también se comprueba que `match\_status` únicamente contenga `MATCHED`, `OMNI\_ONLY` o `GI\_ONLY`.



\### Test SQL personalizado



Se ha desarrollado el test `assert\_campaign\_dates.sql`, que comprueba que ninguna campaña tenga una fecha de inicio posterior a su fecha de finalización.



El test devuelve únicamente los registros que incumplen esta condición. Si no devuelve filas, dbt considera que el test ha pasado.



\### Macro reutilizable



Se ha creado la macro `normalize\_text`, que permite aplicar una misma lógica de normalización a diferentes campos de texto.



La macro realiza las siguientes operaciones:



1\. Convierte el valor a texto.

2\. Sustituye espacios consecutivos por un único espacio.

3\. Elimina espacios al principio y al final.

4\. Convierte el texto a mayúsculas.

5\. Transforma cadenas vacías en `NULL`.



Se utiliza en `stg\_pos\_omni` y `stg\_pos\_gi` para normalizar los nombres de establecimientos antes del matching.



De esta forma, se evita duplicar lógica SQL y se garantiza que ambas fuentes utilicen el mismo criterio de normalización.



\### Resultados de los tests



Se han ejecutado \*\*34 tests automáticos\*\*, todos superados.



También se ha ejecutado el proyecto completo mediante `dbt build`, con los siguientes resultados:



| Componente | Cantidad |

|---|---:|

| Vistas de staging | 7 |

| Tabla de dimensión | 1 |

| Modelo incremental | 1 |

| Tests automáticos | 34 |

| \*\*Operaciones correctas\*\* | \*\*43\*\* |



La ejecución finalizó sin errores ni advertencias.



\## 7. Ejecución



\### Requisitos



\- Python.

\- dbt Core.

\- Adaptador `dbt-duckdb`.

\- DuckDB.

\- Entorno virtual de Python.



\### Preparación de los datos



Desde la raíz del proyecto, con el entorno virtual activado, se cargan los CSV en DuckDB mediante:



&#x20;   python scripts/load\_raw.py



Esta operación crea las tablas originales en el esquema `raw`.



\### Ejecución de dbt



Desde la carpeta `dbt`, con el entorno virtual activado:



\*\*Comprobar la conexión:\*\*



&#x20;   dbt debug --profiles-dir .



\*\*Construir todos los modelos y ejecutar los tests:\*\*



&#x20;   dbt build --profiles-dir .



\*\*Ejecutar únicamente los tests:\*\*



&#x20;   dbt test --profiles-dir .



\*\*Ejecutar únicamente un modelo:\*\*



&#x20;   dbt run --select nombre\_modelo --profiles-dir .



\*\*Forzar una reconstrucción completa del modelo incremental:\*\*



&#x20;   dbt run --select fct\_visits --full-refresh --profiles-dir .



La configuración de conexión se encuentra en `profiles.yml`, que apunta a la base de datos DuckDB local.



\## 8. Decisiones técnicas principales



Las decisiones adoptadas buscan mantener un equilibrio entre simplicidad, calidad de datos y facilidad de mantenimiento.



\- \*\*DuckDB:\*\* permite ejecutar el proyecto localmente sin desplegar infraestructura adicional.

\- \*\*dbt Core:\*\* organiza las transformaciones, las dependencias y los tests.

\- \*\*RAW con datos originales:\*\* conserva la información de origen antes de aplicar reglas de transformación.

\- \*\*Staging como vistas:\*\* evita almacenar copias físicas innecesarias de tablas pequeñas.

\- \*\*Dimensión como tabla:\*\* conserva el catálogo consolidado de establecimientos para su consulta.

\- \*\*Tabla de visitas incremental:\*\* evita procesar todas las visitas en cada ejecución.

\- \*\*Macros reutilizables:\*\* centralizan transformaciones comunes y reducen la duplicación de código.

\- \*\*Tests automáticos:\*\* permiten detectar problemas de integridad y calidad durante las ejecuciones.



El resultado es un pipeline de transformación local, reproducible y validado, que sirve como base para su integración posterior con las herramientas de ingesta y orquestación.


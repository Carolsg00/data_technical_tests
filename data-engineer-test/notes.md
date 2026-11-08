\# Notas técnicas



\## 1. Arquitectura



Se ha desarrollado un pipeline local utilizando \*\*Python, DuckDB, dbt Core y Apache Airflow\*\*.



El flujo de datos es:



`CSV → Python → DuckDB (RAW) → dbt Staging → dbt Marts`



Se ha elegido esta arquitectura por su sencillez, facilidad de ejecución local y bajo coste de infraestructura.



\## 2. Ingesta



Los siete CSV se cargan en DuckDB mediante `scripts/load\_raw.py`, utilizando una estrategia \*\*Full Refresh + Overwrite\*\*.



Las columnas se cargan inicialmente como texto para conservar los valores originales y realizar las conversiones en dbt.



Se incluye `ingestion/connections.yml` con la configuración descriptiva de las siete ingestas. No se han ejecutado conexiones reales de Airbyte.



\## 3. Transformaciones y matching



Se han creado siete modelos de staging y dos modelos finales:



\- \*\*`dim\_pos\_unified`:\*\* unifica los establecimientos de Omni y GI.

\- \*\*`fct\_visits`:\*\* procesa las visitas de forma incremental.



Para el matching se aplican dos reglas, por orden de prioridad:



1\. Nombre normalizado + código postal.

2\. Dirección + localidad + código postal.



Se evitan emparejamientos repetidos y se conservan los identificadores originales para garantizar la trazabilidad.



\*\*Resultados:\*\* 161 establecimientos coincidentes, 204 exclusivos de Omni y 84 exclusivos de GI, con un total de 449.



\## 4. Incrementalidad



`fct\_visits` utiliza `visit\_id` como clave única, `updated\_at` para detectar modificaciones y `merge` para insertar o actualizar registros.



Se ha comprobado que una segunda ejecución no duplicaba las 480 visitas y que una modificación de una visita existente se actualizaba correctamente.



\## 5. Calidad de datos



Se han implementado \*\*34 tests de dbt\*\*, incluyendo `unique`, `not\_null`, `relationships`, `accepted\_values` y un test personalizado de fechas.



También se ha creado la macro `normalize\_text` para reutilizar la normalización de nombres.



\## 6. Orquestación



Se creó el DAG `primer\_impacto\_pipeline` en Apache Airflow, ejecutado mediante Docker.



Contiene dos tareas:



1\. `load\_raw`: carga de los archivos CSV.

2\. `dbt\_build`: ejecución de los modelos y tests.



El DAG incluye programación diaria, dependencias, dos reintentos, límites de tiempo y registro de errores.

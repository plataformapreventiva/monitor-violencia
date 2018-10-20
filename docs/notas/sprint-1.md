# Notas del sprint
Sprint: 01
Fecha: 19/10/18

Tenemos, en esencia, dos preguntas centrales a responder:
1. ¿Cómo podemos generalizar el análisis para detección de anomalías en los datos de distintas amenazas?
2. ¿Cómo podemos visualizar ese análisis?

## Análisis/Modelado

Para el análisis, algunas ideas que queremos tomar en cuenta:
- Dado que esta herramienta está pensada para reaccionar a corto plazo, no queremos detectar niveles altos, sino tasas de crecimiento anómalas.
- Para algunas amenazas, ese análisis de detección de anomalías ya está hecho, y sólo tenemos que consumir los datos. Para otras, necesitamos implementarlo de una forma (idealmente) suficientemente general. Concretamente, tenemos cuatro amenazas que podríamos utilizar:
    - **Requieren sólo consumo**: Sequías y Terremotos
    - **Requiere implementar algún análisis**: Violencia y delincuencia, Anomalías en precios de granos básicos (para esta ya tenemos el modelo)
- Tenemos claro que algunas amenazas afectan de forma distinta a los municipios según la vulnerabilidad que tengan ante la amenaza/las capacidades que tengan para enfrentarla, y nos gustaría incorporar eso al análisis.

Tomando estas ideas en cuenta, lo que decidimos hacer es:
1. Empezar con Violencia y Delinuencia, utilizando tanto los datos del SENSP como los de INEGI. Dada la enorme cifra negra en la mayoría de los delitos, vamos a utilizar solamente homicidios y robo de vehículos, que tienen tasas mucho menores de subreporte.
2. Los de INEGI son más confiables, pero van un año retrasados, así que vamos a ajustar los datos históricos de SENSP con los de INEGI, y generar pronósticos base con esos datos ajustados, usando un ARIMA simple o algún modelo de ese tipo. Así, podemos filtrar la detección de anomalías de temas como la tendencia generalizada, estacionalidad o volatilidad.
3. Podemos entonces definir anomalías como una observación que cae fuera de algún intervalo (definido a nuestro criterio) alrededor de nuestro pronóstico base.

## Visualización

- Para temas de visualización, tenemos la intención de complementar un mapa (que permite tomar en cuenta correlaciones espaciales, pero pierde elementos importantes para tomar decisiones como la población) con algún otro tipo de análisis que tome en cuenta tendencias históricas, población total y otras cuestiones. Antes de tener mayor claridad sobre qué vamos a usar en particular, necesitamos definir cuál es el uso típico de la herramienta.

- Existen algunas referencias interesantes de cosas que podríamos hacer. A pesar de que no es factible hacerlo como prueba de concepto, nos interesa recomendar algo tan completo como [FEWS](http://fews.net).

- Por ahora, vamos a seguir buscando referencias de visualizaciones interesantes en lo que avanzamos con el análisis. Algunas que ya tenemos en mente son [Diego Valle](https://elcri.men/), [Hafen](https://github.com/hafen/geofacet) o [Flowing Data](https://flowingdata.com/category/visualization/mapping/)

- Nos gustaría además reflejar tanto la varianza alrededor del fenómeno en cada municipio, como la importancia de la amenaza según la vulnerabilidad que tiene el municipio ante ella. Una idea interesante es que el usuario pueda escoger qué ponderación le da a esa vulnerabilidad, y así ir entendiendo cómo hay amenazas que "son más importantes que otras".

## To-do (*deadline*: viernes 26 de octubre)

- **Felipe**
    - Comenzar el análisis de las series del SENSP (disponible en **features.crimenes_tasas**) e INEGI (por ahora, hay que tomarlo del sitio de INEGI).
- **Mónica**
    - Ingestar los datos de homicidios de INEGI

# Notas de sprint
Sprint: 02
Fecha: 06/12/2018

## Visualización

Empezamos el sprint revisando una [primera versión](https://drive.google.com/open?id=118IHShr2OyHHpQJXnHIARcoT2DuGCmDP). A partir de esa primera versión, llegamos algunos acuerdos:

La tabla que relaciona las alertas, el perfil de riesgo/vulnerabilidad y la política social activa en cada municipio es lo más importante que queremos mostrar de la vista, pero coincidimos que está bien mostrar el mapa y la descripción de la alerta como una introducción para el usuario. Partiendo de esto, hay varios detalles que acordamos:

    - Incorporar a la tabla sparklines con la línea de tiempo de la amenaza, incluyendo información sobre su respectiva alerta y la fecha del último levantamiento de información de SEDESOL.

    - Permitir filtros para tener *N* alertas, ya sea para todo el país o filtrando por un estado. Así, fijamos el área que destinamos a las alertas individuales y mostramos e.g. de 5 en 5.

    - Encontrar formas de "rebajar" el área del texto: ya sea de quitarle prioridad en términos de espacio o de armonizarlo más con el resto del output. Un par de ideas de cómo lograr esto:

    1. [El ejemplo de Felipe](https://sedesol-lab.slack.com/files/U9GJ1AJMU/FEMCAJPKN/ejemplo_csi.png), en el que el texto está claramente relacionado con las gráficas. Otra cosa que nos gusta mucho de acá es explorar un tooltip más evidente que permita explicar mejor la visualización.

    2. [El ejemplo de Eward Tufte](https://www.edwardtufte.com/bboard/q-and-a-fetch-msg?msg_id=0003mm). Acá lo que nos gusta es cómo el texto sirve para explicar bien la visualización, sin tener mucho protagonismo de color o tamaño. También nos gusta mucho esa gráfica de barras como header. Proponemos usar ya sea el total de alertas por año (nacional/estatal) o el total para cada estado/municipio.

    3. Un detalle adicional: subir el texto de abajo del mapa como un header que lo explique.


## Modelado

    - Sobre la posibilidad de ajustar la serie del SENSP a la de INEGI, consideramos que lejos de ayudar puede ser más confuso presentar una tercera cifra de homicidios. Además, en general el margen que tiene la segunda sobre la primera se mantiene constante, y lo que estamos analizando son los patrones, no los niveles. Acordamos dejar el modelo sólo con los datos del SENSP, con dos detalles:

    1. Meter un disclaimer sobre cómo los datos del Secretariado subestiman las cuentas de homicidios.

    2. Sobreponer la serie de INEGI como contexto, pero sin hacer ningún ajuste adicional.

    - Vamos a correr el modelo para los niveles de *alpha* = [0.1, 0.05, 0.02, 0.01]


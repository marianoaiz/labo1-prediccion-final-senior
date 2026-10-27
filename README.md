# Predicción Final · Analista Senior · Laboratorio de Implementación I

Maestría en Ciencia de Datos · Universidad Austral · 2026
Autor: Mariano Aznar

Notebooks y scripts para replicar la predicción final de la competencia Kaggle `labo-1-ba-2026-analista-sr` (mes a predecir: 202109).

**Submit elegido:** `KA9799_ensamble_c10_11000.csv`, ensamble de 10 corridas completas del workflow, con corte en 11.000 envíos.

## Decisiones tomadas a partir de los Experimentos Colaborativos

Para cada recomendación se consideró si superó al baseline con varias semillas y un test, si se midió en Analista Senior y si coincidían los dos grupos.

| Etapa del workflow | Decisión | Fuente |
|---|---|---|
| FE histórico | Ventana de **9 meses** con tendencia, `ratioavg` y `ratiomax` (original: 6 meses, sin ratios). Solo columnas numéricas para la historia. | #4 Grupo B (Morera): 9 meses le ganó a 6 meses en 10 de 10 semillas (p = 0,004), medido en 202107 |
| FE con Random Forest | Sin cambios: baseline 20/16/100/0,2 | #6 Grupos A y B: ninguna configuración superó al baseline |
| FE intra-mes genético | No se usa | #7 Grupos A y B: la genética no supera a fórmulas al azar |
| Canaritos | Se mantienen (sin ellos, con la ventana de 9 meses el dataset no entra en 128 GB) | Decisión propia |
| Training strategy | Sin cambios | #5: evidencia en el dataset Junior y recomendaciones contradictorias entre grupos |
| Predicción final | **Ensamble de 10 corridas** completas con distintas semillas primigenias, promediando rankings | #7 Grupos A y B: +2 a +6 M y menor varianza; satura entre 5 y 10 corridas |
| Corte | **11.000 envíos**, decidido de antemano, sin mirar el leaderboard público | Coinciden #4, #6 y #7: meseta entre 11.000 y 12.000 en 202107 |

Todos los cambios al notebook de la cátedra están marcados en el código con `[PRED FINAL]`.

## Archivos

```
z739_final_senior.ipynb     Workflow Senior de la cátedra con los cambios [PRED FINAL].
                            Una corrida = una semilla primigenia; cada una va a WF9700_s<semilla>/
z749_ensamble_final.ipynb   Ensambla las corridas: ranking por corrida, promedio de rankings,
                            archivos para Kaggle (cortes 10.000 a 13.000)
scripts_vm/
  z739_final_senior.R       Mismo código que el notebook, para correr con Rscript en una VM
  z749_ensamble_final.R     Mismo código que el notebook de ensamble
  correr_final.sh           Corre una semilla:  correr_final.sh <semilla>
  cadena_final.sh           Corre varias semillas en secuencia y saltea las ya terminadas
```

## Cómo replicar

**Requisitos:** VM de Google Cloud de la cátedra (128 GB de RAM, 12 vCPU), con el bucket montado en `/content/buckets/b1` y `analistasr_competencia_2026.csv.gz` en `/content/datasets/`.

1. Copiar `scripts_vm/*` a `/home/ds/` y darles permiso de ejecución:
   ```bash
   chmod +x /home/ds/*.sh
   ```
2. Correr las 10 semillas (se usaron dos VMs en paralelo):
   ```bash
   # VM1
   nohup /home/ds/cadena_final.sh 102191 220123 550007 777109 998561 > /home/ds/log_cadena.txt 2>&1 &
   # VM2
   nohup /home/ds/cadena_final.sh 129997 200003 300007 400009 600011 > /home/ds/log_cadena.txt 2>&1 &
   ```
   Si la VM se apaga, relanzar el mismo comando: saltea las semillas terminadas y retoma la optimización bayesiana desde `HT.RDATA`.
3. Ensamblar:
   ```bash
   Rscript /home/ds/z749_ensamble_final.R
   ```
   El archivo a subir es `exp/WF9799_ensamble/kaggle/KA9799_ensamble_c10_11000.csv`.

Alternativamente, los dos notebooks se pueden correr en Jupyter cambiando `PARAM$semilla_primigenia` a mano en cada corrida.

## Registro de las corridas

- 10 corridas completas, del 24 al 25 de octubre de 2026, entre 2 y 6 horas cada una, sin interrupciones.
- En todas: optimización bayesiana completa (20 puntos iniciales + 30 iteraciones), 10 modelos de semillerío y entre 86 y 113 variables de la ventana de 9 meses usadas por el modelo final.
- Memoria: ~40 GB de 121 disponibles.
- Las 10 predicciones cubren los mismos 165.076 clientes de 202109. Correlación de Spearman entre corridas: 0,95 a 0,99. Coincidencia de los primeros 11.000 clientes entre pares de corridas: 88% a 94%.

## Advertencia de reproducibilidad

Repetir una semilla no garantiza el mismo resultado: LightGBM suma en paralelo y el orden de esas sumas puede depender del procesador y de la cantidad de hilos, lo que puede cambiar el camino de la optimización bayesiana. En el experimento colaborativo #6, una repetición de la misma semilla en otra VM varió 15,5 M en 202107. El ensamble de 10 corridas está pensado justamente para que el resultado no dependa de una corrida en particular.

## Relacionado

Experimento Colaborativo #6 (Grupo B), feature engineering con Random Forest:
https://github.com/marianoaiz/labo1-grupoB-feature-engineering-rf

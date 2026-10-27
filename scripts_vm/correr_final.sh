#!/bin/bash
# =====================================================================
#  correr_final.sh  <semilla_primigenia>
#
#  Corre una vez el workflow final (z739_final_senior.R) con una semilla.
#  Resultado: /content/buckets/b1/exp/WF9700_s<semilla>/  con
#  prediccion.txt (para el ensamble) y kaggle/ (archivos de esta corrida).
#
#  ejemplo:
#     nohup /home/ds/correr_final.sh 102191 > /dev/null 2>&1 &
#
#  Si la VM se apaga: volver a lanzar la MISMA semilla. La optimizacion
#  bayesiana retoma desde HT.RDATA y los modelos ya entrenados no se
#  vuelven a entrenar (la parte de preprocesamiento si se rehace).
# =====================================================================
SEM=${1:?"falta la semilla: correr_final.sh <semilla>"}
FOLDER=WF9700_s${SEM}
LOG=/home/ds/log_${FOLDER}.txt

{
  echo "=============================================="
  echo " INICIO  $FOLDER   $(date)"
  echo "=============================================="
  Rscript /home/ds/z739_final_senior.R $SEM
  echo "=============================================="
  echo " FIN     $FOLDER   $(date)"
  echo "=============================================="
} >> $LOG 2>&1

# copio el log a la carpeta del experimento (en el bucket)
cp $LOG /content/buckets/b1/exp/${FOLDER}/ 2>/dev/null

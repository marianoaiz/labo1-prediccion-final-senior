#!/bin/bash
# =====================================================================
#  cadena_final.sh  <semilla1> <semilla2> ...
#
#  Corre el workflow final para varias semillas, una detras de otra.
#  Saltea las semillas que ya tienen su prediccion.txt en el bucket,
#  asi que si la VM se apaga alcanza con relanzar el MISMO comando.
#
#  ejemplo (VM1):
#     nohup /home/ds/cadena_final.sh 102191 220123 777109 > /home/ds/log_cadena.txt 2>&1 &
# =====================================================================
for s in "$@"; do
  PRED=/content/buckets/b1/exp/WF9700_s${s}/prediccion.txt
  if [ -f "$PRED" ]; then
    echo " semilla $s ya terminada, la salteo   $(date)"
    continue
  fi
  echo " ARRANCA semilla $s   $(date)"
  /home/ds/correr_final.sh $s
  if [ -f "$PRED" ]; then
    echo " OK semilla $s   $(date)"
  else
    echo " !!! la semilla $s NO produjo prediccion.txt: revisar /home/ds/log_WF9700_s${s}.txt"
    exit 1
  fi
done
echo " CADENA COMPLETA   $(date)"

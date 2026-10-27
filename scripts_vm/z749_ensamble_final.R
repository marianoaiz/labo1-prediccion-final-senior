# z749_ensamble_final.R - generado de z749_ensamble_final.ipynb (mismo codigo)

format(Sys.time(), "%a %b %d %X %Y")
rm(list=ls(all.names=TRUE))
gc(full=TRUE, verbose=FALSE)
require("data.table")

PARAM <- list()
PARAM$experimento <- "9799_ensamble"

# carpeta donde estan los experimentos
PARAM$carpeta_exp <- "/content/buckets/b1/exp"

# corridas a ensamblar: una carpeta por semilla primigenia
PARAM$semillas <- c( 102191, 220123, 550007, 777109, 998561,    # VM1
                     129997, 200003, 300007, 400009, 600011 )   # VM2
# las corridas que todavia no terminaron se saltean (se informa "FALTA")
PARAM$corridas <- paste0( "WF9700_s", PARAM$semillas )

# cortes para los que se generan archivos, y el corte elegido de antemano
PARAM$kaggle$competencia <- "labo-1-ba-2026-analista-sr"
PARAM$kaggle$cortes <- seq(10000, 13000, by = 500)
PARAM$kaggle$corte_final <- 11000

# TRUE sube a Kaggle SOLO el archivo del corte final
PARAM$kaggle$subir <- FALSE

setwd( PARAM$carpeta_exp )
experimento_folder <- paste0("WF", PARAM$experimento)
dir.create(experimento_folder, showWarnings=FALSE)
setwd( paste0(PARAM$carpeta_exp, "/", experimento_folder) )

leer_corrida <- function( corrida ) {
  arch <- paste0( PARAM$carpeta_exp, "/", corrida, "/prediccion.txt" )
  if( !file.exists(arch) ) {
    cat( "FALTA ", arch, "\n" )
    return( NULL )
  }
  tb <- fread( arch, select = c("numero_de_cliente", "prob") )
  # ranking normalizado: 1/N el de mayor probabilidad, 1 el de menor
  tb[, rank := frank( -prob, ties.method = "average" ) / .N ]
  tb[, corrida := corrida ]
  return( tb )
}

tb_todas <- rbindlist( lapply( PARAM$corridas, leer_corrida ) )
corridas_ok <- unique( tb_todas$corrida )
cat( "corridas disponibles:", length(corridas_ok), "\n" )
print( corridas_ok )

if( length(corridas_ok) == 0 ) stop( "no hay ninguna corrida terminada" )

# mismo conjunto de clientes en todas las corridas
tb_n <- tb_todas[, list( clientes = .N, distintos = uniqueN(numero_de_cliente) ), by = corrida ]
print( tb_n )
if( uniqueN(tb_n$clientes) != 1 || any(tb_n$clientes != tb_n$distintos) )
  stop( "las corridas no predicen el mismo conjunto de clientes" )

# matriz cliente x corrida con los rankings
tb_rank <- dcast( tb_todas, numero_de_cliente ~ corrida, value.var = "rank" )
if( any( is.na( tb_rank ) ) ) stop( "hay clientes que no estan en todas las corridas" )

# parecido entre corridas
if( length(corridas_ok) >= 2 ) {
  m <- as.matrix( tb_rank[, ..corridas_ok] )
  cat( "\ncorrelacion de Spearman entre corridas:\n" )
  print( round( cor(m, method = "spearman"), 3 ) )

  top <- lapply( corridas_ok, function(cr) tb_rank[ order(get(cr)) ][ 1:PARAM$kaggle$corte_final, numero_de_cliente ] )
  coincidencia <- outer( seq_along(top), seq_along(top),
    Vectorize( function(i, j) length( intersect(top[[i]], top[[j]]) ) / PARAM$kaggle$corte_final ) )
  dimnames( coincidencia ) <- list( corridas_ok, corridas_ok )
  cat( "\ncoincidencia de los primeros", PARAM$kaggle$corte_final, "clientes:\n" )
  print( round( coincidencia, 3 ) )
}

tb_ensamble <- tb_todas[, list( rank_prom = mean(rank), prob_prom = mean(prob) ),
  by = numero_de_cliente ]

# menor ranking promedio = mayor propension a la baja
setorder( tb_ensamble, rank_prom )

fwrite( tb_ensamble, file = "prediccion_ensamble.txt", sep = "\t" )
head( tb_ensamble )

dir.create( "kaggle", showWarnings = FALSE )

for( envios in PARAM$kaggle$cortes ) {
  tb_ensamble[, Predicted := 0L ]
  tb_ensamble[ 1:envios, Predicted := 1L ]

  archivo_kaggle <- paste0( "./kaggle/KA", PARAM$experimento, "_c",
    length(corridas_ok), "_", envios, ".csv" )

  fwrite( tb_ensamble[, list(numero_de_cliente, Predicted)],
    file = archivo_kaggle, sep = "," )

  # solo se sube el corte decidido de antemano
  if( PARAM$kaggle$subir && envios == PARAM$kaggle$corte_final ) {
    linea <- paste( "kaggle competitions submit",
      "-c", PARAM$kaggle$competencia,
      "-f", archivo_kaggle,
      paste0( "-m 'ensamble ", length(corridas_ok), " corridas, envios=", envios, "'" ) )
    salida <- system( linea, intern = TRUE )
    cat( salida, "\n" )
  }
}

list.files( "kaggle" )

# grabo los parametros
if( !require("yaml")) install.packages("yaml")
require("yaml")
PARAM$corridas_usadas <- corridas_ok
write_yaml( PARAM, file = "PARAM.yml" )
format(Sys.time(), "%a %b %d %X %Y")

library(tidyverse)
library(lubridate)
library(surveillance)
library(DBI)
library(dbplyr)
library(jsonlite)

source('./deteccion-homicidios.R')

dotenv::load_dot_env("../.env")

PGDATABASE <- Sys.getenv("PGDATABASE")
POSTGRES_PASSWORD <- Sys.getenv("POSTGRES_PASSWORD")
POSTGRES_USER <- Sys.getenv("POSTGRES_USER")
PGHOST <- Sys.getenv("PGHOST")
PGPORT <- Sys.getenv("PGPORT")

con <- DBI::dbConnect(RPostgres::Postgres(),
                      host=PGHOST,
                      port=PGPORT,
                      dbname=PGDATABASE,
                      user=POSTGRES_USER,
                      password=POSTGRES_PASSWORD
)

selected_crimes <- c('Homicidio doloso',
                     'Feminicidio')

meses <- list('Enero'='01', 'Febrero'='02', 'Marzo'='03', 'Abril'='04',
              'Mayo'='5', 'Junio'='06', 'Julio'='07', 'Agosto'='08',
              'Septiembre'='09', 'Octubre'='10', 'Noviembre'='11', 'Diciembre'='12')

nm <- tbl(con, dbplyr::in_schema('raw','delitos_comun')) %>%
  filter(subtipodedelito %in% selected_crimes) %>%
  mutate(fecha = paste0(anio,'-',mes,'-01')) %>%
  group_by(cve_muni, fecha) %>%
  summarise(count = sum(incidencia_delictiva, na.rm = T)) %>%
  collect()

nm <- nm %>%
  separate(fecha, into = c('anio','mes','dia')) %>%
  mutate(mes = recode(mes, !!!meses),
         date = ymd(paste0(anio,'-',mes,'-',dia))) %>%
  select(cve_muni, date, count)

query_0 <-"select cve_muni, entidad, municipio, pob_tot
           from clean.coneval_municipios
           where data_date = '2015-a'
           group by 1,2,3,4
           order by cve_muni"
pob <- dbGetQuery(con, query_0)

nm <- pob %>% 
  left_join(nm, by = "cve_muni") %>%
  mutate(count = as.integer(count),
         pob_tot = as.integer(pob_tot)) %>%
  arrange(cve_muni, date)

# Ejemplo
# guadalajara <- nm %>% filter(cve_muni == '14039')
# monitor_gdl <- monitor_farrington(guadalajara, alpha=0.05, periods = 10)
# graf_monitor(monitor_gdl)

municipios <- pob$cve_muni

procesa_mun <- function(mun){
  datos_muni <- nm %>% filter(cve_muni == mun & !is.na(count))
  state <- first(datos_muni$entidad) %>% simple_cap
  muni <- first(datos_muni$municipio) %>% simple_cap
  monitor_datos <- monitor(datos_muni, alpha = 0.02, periods = 10)
  json_final <- list("tipo" = monitor_datos$tipo)
  
  tryCatch({
    metadata <- fromJSON(unique(monitor_datos$data$metadata))
  },
  error = function(e){
    metadata <- NA
  },
  finally = {
    if(!exists("metadata")){
      metadata <- NA
      alpha <- NA
      b <- NA
      w <- NA
      periods <- NA
      limit <- NA
    }else{
      alpha <- metadata$alpha
      b <- metadata$b
      w <- metadata$w
      periods <- metadata$periods
      limit <- metadata$limit
    }
    metadata <- list("alpha" = alpha, "b" = b, "w" = w, 
                    "periods" = periods, "limit" = limit)
    json_final <- c(json_final, list("metadata" = metadata))
    rm(alpha,b,w,periods,limit,metadata)
  })
  
  aux_serie <- monitor_datos$data
  serie_lista <- lapply(1:nrow(aux_serie), function(i){
    aux <- aux_serie[i,]
    nom <- as.character(as.Date(aux$date[1]))
    l <- list("num_crimenes" = as.integer(aux$count[1]),
              "alerta" = as.integer(aux$alerta[1]),
              "alerta_nivel" = as.integer(aux$alerta_nivel[1])
              )
    names(l)
    list(nom = nom, l = l)
  })
  noms <- Reduce(c, Map(f = function(x){x$nom}, x = serie_lista))
  ls <- map(.f = function(x){x$l}, .x = serie_lista)
  names(ls) <- noms
  json_final <- c(json_final, list("serie" = serie_lista))
  serie <- toJSON(json_final, auto_unbox = T)
  
  tibble(nivel = "m", nivel_clave = mun, 
         nivel_nombre = paste0(muni, ', ', state), 
         values = serie)
}

datos_finales <- map_df(.x = municipios, .f = procesa_mun)

query_1 <- c("DROP TABLE IF EXISTS models.monitor_violencia_municipios;")
chrs <- c(letters, '_', 0:9)
nom_tabla <- make.names(paste0(sample(chrs, size = 20, replace = T), collapse = ''))
query_2 <- paste0('CREATE TEMP TABLE IF NOT EXISTS ', nom_tabla, 
                    ' nivel TEXT, ',
                    'nivel_clave TEXT, ',
                    'nivel_nombre TEXT, ',
                    'values TEXT);')
DBI::dbGetQuery(con, query_1)
DBI::dbGetQuery(con, query_2)

RPostgres::dbWriteTable(conn = con,
                        name = nom_tabla,
                        value = datos_finales, 
                        temporary = TRUE,
                        overwrite = TRUE, 
                        row.names = FALSE)

query_3 <- paste0('CREATE TABLE models.monitor_crimenes_municipios AS (',
                  'SELECT * from ', nom_tabla, ');')
DBI::dbGetQuery(con, query_3)

# Clean and disconnect
gc()
dbDisconnect(con)

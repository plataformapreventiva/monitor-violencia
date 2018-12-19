
simple_cap <- function(x) {
    s <- strsplit(tolower(x), " ")[[1]]
    paste(toupper(substring(s, 1, 1)), substring(s, 2),
          sep = "", collapse = " ")
}

monitor_bayes <- function(hom_df, periods = 10, alpha = 0.02, b = 0, w = 6){
    hom_df <- arrange(hom_df, date)
    
    observed <- hom_df$count 
    n <- length(observed)
    range <- (n - periods + 1):n
    start_date <- min(hom_df$date)
    start <- c(lubridate::year(start_date), lubridate::month(start_date))
    obs_dprog <- ts(observed, start = start, frequency = 12) %>% 
        as("sts") %>% sts2disProg
    
    tryCatch({
      monitor_surv <- algo.bayes(obs_dprog, 
                                control = list(range = range, b = b, w = w, 
                                              alpha = alpha))
      hom_df$alerta <- NA
      hom_df$alerta_nivel <- NA
      hom_df$alerta[range] <- as.logical(monitor_surv$alarm)
      hom_df$alerta_nivel[range] <- monitor_surv$upperbound
      metadata <- list(tipo= 'bayes', alpha = alpha, b = b, w = w,
                       periods = periods,
                       hash_model = digest::digest(monitor_surv, algo = 'md5')) %>% 
        jsonlite::toJSON(auto_unbox = TRUE)
      hom_df$metadata <- metadata
      list(monitor = monitor_surv, data = hom_df, tipo = 'bayes')
    }, 
    error = function(e) {
      hom_df$alerta <- NA
      hom_df$alerta_nivel <- NA
      hom_df$metadata <- NA
      list(monitor = NULL, data = hom_df, tipo = 'ninguno')
    }
    )
}

monitor_farrington <- function(hom_df, periods = 10, alpha = 0.02, b = 2, 
                               w = 4){
    hom_df <- arrange(hom_df, date)
    
    observed <- hom_df$count 
    n <- length(observed)
    range <- (n - periods + 1):n
    start_date <- min(hom_df$date)
    start <- c(lubridate::year(start_date), lubridate::month(start_date))
    obs_dprog <- ts(observed, start = start, frequency = 12) %>% 
        as("sts") # %>% sts2disProg
    
    monitor_surv <- farringtonFlexible(obs_dprog, 
                    control = list(range = range, b = b, w = w, 
                                   powertrans = "none", alpha = alpha,
                                   limit54 = c(5, 3),
                                   thresholdMethod="nbPlugin",
                                   reweight = TRUE,
                                   pastWeeksNotIncluded = 0, verbose = FALSE))
    hom_df$alerta <- NA
    hom_df$alerta_nivel <- NA
    hom_df$alerta[range] <- monitor_surv@alarm
    hom_df$alerta_nivel[range] <- monitor_surv@upperbound 
    collapsed <- any(is.na(monitor_surv@upperbound))
    metadata <- list(tipo = 'farrington', alpha = alpha, b = b, w = w,
                     periods = periods, limit = c(5,3), 
                     hash_model = digest::digest(monitor_surv, algo = 'md5')) %>% 
        jsonlite::toJSON(auto_unbox = TRUE)
    hom_df$metadata <- metadata
    list(monitor = monitor_surv, data = hom_df, tipo = 'farrington',
         collapsed = collapsed)
}

monitor <- function(hom_df, periods = 10, alpha = 0.02, b = 2, w = 4) {
    tryCatch({
        monitor_1 <- monitor_farrington(hom_df, periods = periods, 
                                        alpha = alpha, b = b, w = w)
    }, 
        warning = function(w) { 
            monitor_bayes(hom_df, periods = periods, alpha = 0.5 * alpha)
        }
    )
}
graf_monitor <- function(monitor){
    data <- monitor$data
    state <- first(data$entidad) %>% simple_cap
    mun <- first(data$municipio) %>% simple_cap
    valores_alerta <- unique(data$alerta[!is.na(data$alerta)])
    colores <- "black"
    if(length(valores_alerta) ==2){
        colores <- c("black", "red")
    } else {
        if(TRUE %in% valores_alerta) {
            colores <- c("red")
        }
    }
    graf <- ggplot(data, aes(x = date, y = count)) + 
        geom_ribbon(aes(ymin=0, ymax = alerta_nivel) ,alpha = 1, fill="gray90") +
        geom_linerange(aes(ymin=0, ymax = alerta_nivel) ,alpha = 1, size = 5,
                        colour = "gray90") +
        geom_line(aes(y = count), colour='gray') +
        geom_point(aes(y = count), colour='gray') +
        scale_colour_manual(values = colores) +
        scale_size(range=c(2,4)) +
        theme_minimal() + guides(colour=FALSE) + guides(size = FALSE) +
        ylab("Número de homicidios") +
        labs(title = paste0(mun, ", ", state)) + 
        labs(subtitle = paste("Método:", monitor$tipo))
    if(max(data$alerta, na.rm = TRUE) == 1){
        graf <- graf + geom_point(aes(y = count, colour = factor(alerta), 
                                      size=as.numeric(alerta)))
    } else {
        graf <- graf + geom_point(aes(y = count, colour = factor(alerta)))
    }
    graf
}


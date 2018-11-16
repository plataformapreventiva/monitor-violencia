simple_cap <- function(x) {
    s <- strsplit(tolower(x), " ")[[1]]
    paste(toupper(substring(s, 1, 1)), substring(s, 2),
          sep = "", collapse = " ")
}

monitor <- function(hom_df, periods = 10, alpha = 0.02){
    hom_df <- arrange(hom_df, date)
    
    observed <- hom_df$count 
    n <- length(observed)
    range <- (n - periods + 1):n
    obs_dprog <- ts(observed, start = c(2015,1), frequency = 12) %>% 
        as("sts") %>% sts2disProg
    
    monitor_surv <- algo.bayes(obs_dprog, 
                               control = list(range = range, b = 0, w = 6, alpha = alpha))
    hom_df$alarm <- NA
    hom_df$upper_bound <- NA
    hom_df$alarm[range] <- monitor_surv$alarm
    hom_df$upper_bound[range] <- monitor_surv$upperbound
    list(monitor = monitor_surv, data = hom_df, tipo = 'bayes')
}

monitor_farrington <- function(hom_df, periods = 10, alpha = 0.02){
    hom_df <- arrange(hom_df, date)
    
    observed <- hom_df$count 
    n <- length(observed)
    range <- (n - periods + 1):n
    obs_dprog <- ts(observed, start = c(2015,1), frequency = 12) %>% 
        as("sts") # %>% sts2disProg
    
    monitor_surv <- farringtonFlexible(obs_dprog, 
                    control = list(range = range, b = 2, w = 3, 
                                   powertrans = "none", alpha = alpha,
                                   thresholdMethod="nbPlugin",
                                   reweight = FALSE,
                                   pastWeeksNotIncluded = 0, verbose = FALSE))
    hom_df$alarm <- NA
    hom_df$upper_bound <- NA
    hom_df$alarm[range] <- monitor_surv@alarm
    hom_df$upper_bound[range] <- monitor_surv@upperbound 
    collapsed <- any(is.na(monitor_surv@upperbound))
    list(monitor = monitor_surv, data = hom_df, tipo = 'farrington',
         collapsed = collapsed)
}

monitor_mixto <- function(hom_df, periods = 10, alpha = 0.02){
    monitor <- monitor_farrington(hom_df, periods = periods, alpha = alpha)
    if(monitor$collapsed){
        monitor <- monitor(hom_df, periods = periods, alpha = alpha)
    }
    monitor
}

graf_monitor <- function(monitor){
    data <- monitor$data
    state <- first(data$state) %>% simple_cap
    mun <- first(data$municipio) %>% simple_cap
    graf <- ggplot(data, aes(x = date, y = count)) + 
        geom_ribbon(aes(ymin=0, ymax = upper_bound) ,alpha = 0.5, fill="gray80") +
        geom_line(aes(y = count), colour='gray') +
        geom_point(aes(y = count), colour='gray') +
        scale_colour_manual(values = c("black", "red")) +
        scale_size(range=c(2,4)) +
        theme_minimal() + guides(colour=FALSE) + guides(size = FALSE) +
        ylab("Número de homicidios") +
        labs(title = paste0(mun, ", ", state)) + 
        labs(subtitle = paste("Método:", monitor$tipo))
    if(max(data$alarm, na.rm = TRUE) == 1){
        graf <- graf + geom_point(aes(y = count, colour = factor(alarm), 
                                      size=as.numeric(alarm))) 
    } else {
        graf <- graf + geom_point(aes(y = count, colour = factor(alarm)))
    }
    graf
}


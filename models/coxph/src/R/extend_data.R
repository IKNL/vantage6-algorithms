#' version: 1.0
#' Extend the data with new variables
#'
#' This function enriches the datasets at the nodes with more variable which in
#' turn can be used in analyses. Created together with Laura Botta (INT).
#' This function will be called at the start of the analysis, and executed on
#' the data of every node. Has to be implemented in every RPC call.
#'
#' @param data Data provided by client.
#'
#' @return Original dataframe extended with new columns.
#'
#' @export

extend_data <- function(data){

  library(dplyr)

  temp.data = data

  print('Number of columns before extend_data:')
  print(ncol(temp.data))

  temp.data <- temp.data %>%

    mutate(time2 = time+sample(1:20, n(), replace = TRUE)) %>%

    #creazione dei site combinato
    #mutate(site = ifelse(!is.na(d11_siterare),d11_siterare ,d11_sitecomrar))
    #la differenza tra questi due codici, uno ha la label e l altro no. QUALE ? MEGLIO TENERE?
    mutate(siteName = case_when(d11_siterare == 1 | d11_sitecomrar == 1 ~ "Nasal cavity and paranasal sinuses",
                            d11_siterare == 2 | d11_sitecomrar == 2 ~ "Nasopharynx",
                            d11_siterare %in% c(3,4,5) | d11_sitecomrar %in% c(3,4,5) ~ "Parotid gland; Submandibular gland; Sublingual gland",
                            d11_siterare == 6 | d11_sitecomrar == 6 ~ "Middle ear",
                            # !is.na(d11_siterare) | !is.na(d11_sitecomrar) ~ "Other",
                            TRUE ~ "Other")) %>%
    #mutate(dates = as.Date(d01_diagdate, "%Y-%m-%d"))%>%
    #creo un unica variabile per et?
    mutate(age = ifelse(!is.na(d03_diagage_au), d03_diagage_au,d04_diagage_man)) %>%
    #categorizzazione delle et?
    mutate(ageclas = case_when(age < 40 ~ 1,
                               age >= 40 & age < 50 ~ 2,
                               age >= 50 & age < 60 ~ 3,
                               age >= 60 & age < 70 ~ 4,
                               age >= 70 ~ 5, TRUE ~NA))%>%
    #anni di  diagnosi e di follow-up
    mutate(year_diag = format(d01_diagdate, format = '%Y')) %>%
    #mutate(datesfu = as.Date(h02_datelasfup, "%Y-%m-%d"))%>%
    mutate(yearF =  format(h02_datelasfup, format = '%Y')) %>%
    #BMI
    mutate(BMI = ifelse(!is.na(b18_bmi), b18_bmi,b18b_bmimanu)) %>%
    mutate(catBMI = ifelse(BMI < 18.5, 1, ifelse(BMI >= 18.5 & BMI < 25, 2, ifelse(BMI >= 25 & BMI < 30, 3, ifelse(BMI >= 30 & BMI != ".", 4, ifelse(BMI == ".", 999, NA)))))) %>%
    mutate(stage = ifelse(e34_cstage %in% c(1,2,3), 1, ifelse(e34_cstage %in% c(4,5,6,7), 2, ifelse(e34_cstage == 8 | (e34_cstage == 7 & siteName == 2) | (e34_cstage == 5 & siteName == 3 & d27_p16 == 1), 3, ifelse(e34_cstage == 999, 999, NA)))))%>%
    mutate(pstage = ifelse(e54_pstage %in% c(1,2,3), 1, ifelse(e54_pstage %in% c(4,5,6,7), 2, ifelse(e54_pstage == 8 | (e54_pstage == 7 & siteName == 2) | (e54_pstage == 5 & siteName == 3 & d27_p16 == 1), 3, ifelse(e54_pstage == 999, 999, NA))))) %>%
    #creo una variabile che usi il patologico e se non c'? il clinico
    mutate(combstage = ifelse(is.na(e54_pstage) | e54_pstage==999, e34_cstage,  e54_pstage)) %>%

    # 1 se adk o salivary, 0 negli altri casi
    mutate(Salivary  = case_when(siteName %in% c(3,4,5)~ 1, d05_histo==2 ~ 1, TRUE ~ 0))%>%

    #vale solo per i salivary di Stefano
    #genero una selezione per i salivary con intervento chirurgico fatto e con radio fatta
    mutate(groups = case_when (f32_1_systsetting %in% c(2,3) & Salivary == 1 & f03_surgintent == 2 & (f54_radiointent == 2 & f55_radiosett %in% c(3,4))~ 2,
                                Salivary == 1 & f03_surgintent == 2 & (f54_radiointent == 2 & f55_radiosett %in% c(3,4))~ 1)) %>%
    #eventi e survival per OS e Cause specific
    mutate(deadOS = ifelse(h01_status %in% c(2,3,4), 1, 0)) %>%
    mutate(deadC = ifelse(h01_status==2, 1, 0)) %>%

    # questa distanza ? calcolata in giorni per cui surv ? in giorni
    mutate(surv = as.Date(h02_datelasfup) - as.Date(d01_diagdate)) %>%
    #eventi e survival per PFS _dalla data inizio trattamento a progressione o morte per tumore

    #####Morto per tumore o progressione è 1 ( evento) LE MORTI PER ALTRE CAUSE sono 0 ( no evento) e devono essere censorizzate,
    mutate(event_pfs = ifelse(h01_status == 2 | g1_01_progrel %in% c(1,2) | g2_01_progrel %in% c(1,2) | g3_01_progrel %in% c(1,2) | g4_01_progrel %in% c(1,2) | g5_01_progrel %in% c(1,2) | g6_01_progrel %in% c(1,2) | g7_01_progrel %in% c(1,2) | g8_01_progrel %in% c(1,2) | g9_01_progrel %in% c(1,2) | g10_01_progrel %in% c(1,2), 1 ,0)) %>%
    #Genero la data di progressione
    #mutate(dataprog = pmax(g1_03_date,g2_03_date,g3_03_date,g4_03_date,g5_03_date,g6_03_date,g7_03_date,g8_03_date,g9_03_date,g10_03_date, na.rm = TRUE)) %>%
    mutate(dataprog = case_when(g1_01_progrel %in% c(1:2) ~ g1_03_date,
                                g2_01_progrel %in% c(1:2) ~ g2_03_date,
                                g3_01_progrel %in% c(1:2) ~ g3_03_date,
                                g4_01_progrel %in% c(1:2) ~ g4_03_date,
                                g5_01_progrel %in% c(1:2) ~ g5_03_date,
                                g6_01_progrel %in% c(1:2) ~ g6_03_date,
                                g7_01_progrel %in% c(1:2) ~ g7_03_date,
                                g8_01_progrel %in% c(1:2) ~ g8_03_date,
                                g9_01_progrel %in% c(1:2) ~ g9_03_date,
                                g10_01_progrel %in% c(1:2) ~ g10_03_date,
                                TRUE ~ NA)) %>%
    #La data di follow-up deve sempre essere aggiornata, non puo esistere se c'? progressione una data di follow-up precedente-E un CHECK! Uso la
    # attenzione che se c'? una data NA questo mi restituisce NA
    mutate(PFS = (pmin(as.Date(h02_datelasfup), as.Date(dataprog), na.rm= TRUE) - pmin(as.Date(f02_datesurg), as.Date(f33_1_startdate_syst), as.Date(f80_radiostartdate), na.rm= TRUE))) %>%

    #Seleziono i pazienti che non sono metastatici e se PFS ? calcolabile (un paziente non metastatico ma senza trattamento non entra, un paziente senza stadio non entra resta un sel1=NA
    mutate(sel1 = ifelse(stage!= 3 & !is.na(PFS), 1, 0)) %>%

    ######eventi e survival LOCAL CONTROL
    #LC considera come evento la prima recidiva locale (su T) a prescindere dal fatto che sviluppi metastasie/o regionale (su N) o sia deceduto (in tal caso sarà censorizzato alla data di ultimo follow up)
    #DA VERIFICARE CON STEFANO: cosa succede se ho la progressione su T, N ed M? Io l ho messo come evento
    mutate(datelc = case_when(g1_01_progrel %in% c(1:2) & (g1_04_local==1) ~ g1_03_date,
                              g2_01_progrel %in% c(1:2) & (g2_04_local==1) ~ g2_03_date,
                              g3_01_progrel %in% c(1:2) & (g3_04_local==1) ~ g3_03_date,
                              g4_01_progrel %in% c(1:2) & (g4_04_local==1) ~ g4_03_date,
                              g5_01_progrel %in% c(1:2) & (g5_04_local==1) ~ g5_03_date,
                              g6_01_progrel %in% c(1:2) & (g6_04_local==1) ~ g6_03_date,
                              g7_01_progrel %in% c(1:2) & (g7_04_local==1) ~ g7_03_date,
                              g8_01_progrel %in% c(1:2) & (g8_04_local==1) ~ g8_03_date,
                              g9_01_progrel %in% c(1:2) & (g9_04_local==1) ~ g9_03_date,
                              g10_01_progrel %in% c(1:2) & (g10_04_local==1) ~ g10_03_date,
                              TRUE ~ NA)) %>%
    # mutate (datalc= ifelse(g1_01_progrel %in% c(1:2) & (g1_04_local==1), g1_03_date , ifelse(g2_01_progrel %in% c(1:2) & (g2_04_local==1), g2_03_date,  ifelse(g3_01_progrel %in% c(1:2) & (g3_04_local==1), g3_03_date,ifelse(g4_01_progrel %in% c(1:2) & (g4_04_local==1), g4_03_date,  ifelse(g5_01_progrel %in% c(1:2) & (g5_04_local==1), g5_03_date,  ifelse(g6_01_progrel %in% c(1:2)& (g6_04_local==1), g6_03_date,  ifelse(g7_01_progrel %in% c(1:2) & (g7_04_local==1), g7_03_date, ifelse(g8_01_progrel %in% c(1:2) & (g8_04_local==1), g8_03_date, ifelse(g9_01_progrel %in% c(1:2) & (g9_04_local==1), g9_03_date, ifelse(g10_01_progrel %in% c(1:2) & (g10_04_local==1), g10_03_date, NA))))))))))) %>%


    #lc1 ? per definire se ha una recidiva/progressione su N o M oppure se ? morto per altre cause
    mutate(datelc1 = case_when(g1_01_progrel %in% c(1:2) & (g1_04_local!=1) ~ g1_03_date,
                               g2_01_progrel %in% c(1:2) & (g2_04_local!=1) ~ g2_03_date,
                               g3_01_progrel %in% c(1:2) & (g3_04_local!=1) ~ g3_03_date,
                               g4_01_progrel %in% c(1:2) & (g4_04_local!=1) ~ g4_03_date,
                               g5_01_progrel %in% c(1:2) & (g5_04_local!=1) ~ g5_03_date,
                               g6_01_progrel %in% c(1:2) & (g6_04_local!=1) ~ g6_03_date,
                               g7_01_progrel %in% c(1:2) & (g7_04_local!=1) ~ g7_03_date,
                               g8_01_progrel %in% c(1:2) & (g8_04_local!=1) ~ g8_03_date,
                               g9_01_progrel %in% c(1:2) & (g9_04_local!=1) ~ g9_03_date,
                               g10_01_progrel %in% c(1:2) & (g10_04_local!=1) ~ g10_03_date,
                               TRUE ~ h02_datelasfup)) %>%
    # mutate (datalc1= ifelse(g1_01_progrel %in% c(1:2) & (g1_04_local!=1), g1_03_date , ifelse(g2_01_progrel %in% c(1:2) & (g2_04_local!=1), g2_03_date,  ifelse(g3_01_progrel %in% c(1:2) & (g3_04_local!=1), g3_03_date,ifelse(g4_01_progrel %in% c(1:2) & (g4_04_local!=1), g4_03_date,  ifelse(g5_01_progrel %in% c(1:2) & (g5_04_local!=1), g5_03_date,  ifelse(g6_01_progrel %in% c(1:2)& (g6_04_local!=1), g6_03_date,  ifelse(g7_01_progrel %in% c(1:2) & (g7_04_local!=1), g7_03_date, ifelse(g8_01_progrel %in% c(1:2) & (g8_04_local!=1), g8_03_date, ifelse(g9_01_progrel %in% c(1:2) & (g9_04_local!=1), g9_03_date, ifelse(g10_01_progrel %in% c(1:2) & (g10_04_local!=1), g10_03_date,h02_datelasfup ))))))))))) %>%

    mutate(LC = pmin(as.Date(datelc), as.Date(datelc1), na.rm= TRUE) - pmin(as.Date(f02_datesurg), as.Date(f33_1_startdate_syst), as.Date(f80_radiostartdate), na.rm=TRUE )) %>%
    #creo l evento, 1 se LC ? presente 0 se invece c'? prima la morte o la metastasi
    #cosa succede in R se una data ? NA? Se datelc ? NA la riga 99 produce uno 0? o non si confrontano le due date. Ho messo che datelc ? nullo, invece per la riga 100 non c'? problema perch? il follow-up ci deve essere sempre
    mutate(event_Lc = case_when(is.na(datelc)  ~ 0 ,
                               datelc1 < datelc  ~ 0,
                               datelc1 >= datelc ~  1 ,
                               TRUE ~ NA))%>%
    mutate(sel2 = ifelse(stage!= 3 & !is.na(LC), 1, 0) ) %>%
    #per Matteo Cellamare, possiamo ottere il plot dell'incidenza cumulata ( 1-KM)

    #LOCOREGIONAL CONTROL, Patients were censored at the date of death if they died of distant metastases or died without documented progressive cancer;
    #Freedom from local-regional progression.

    #datelrc mi da la data di un evento locoregionale
    mutate(datelrc = case_when (g1_01_progrel %in% c(1,2) & (g1_04_local == 1 | g1_05_regional == 1)  ~ g1_03_date,
                                 g2_01_progrel %in% c(1,2) & (g2_04_local == 1 | g2_05_regional == 1)~ g2_03_date,
                                 g3_01_progrel %in% c(1,2) & (g3_04_local == 1 | g3_05_regional == 1)~ g3_03_date,
                                 g4_01_progrel %in% c(1,2) & (g4_04_local == 1 | g4_05_regional == 1)~ g4_03_date,
                                 g5_01_progrel %in% c(1,2) & (g5_04_local == 1 | g5_05_regional == 1)~ g5_03_date,
                                 g6_01_progrel %in% c(1,2) & (g6_04_local == 1 | g6_05_regional == 1)~ g6_03_date,
                                 g7_01_progrel %in% c(1,2) & (g7_04_local == 1 | g7_05_regional == 1)~ g7_03_date,
                                 g8_01_progrel %in% c(1,2) & (g8_04_local == 1 | g8_05_regional == 1)~ g8_03_date,
                                 g9_01_progrel %in% c(1,2) & (g9_04_local == 1 | g9_05_regional == 1)~ g9_03_date,
                                 g10_01_progrel %in% c(1,2) & (g10_04_local == 1 | g10_05_regional == 1)~ g10_03_date,TRUE ~ NA)) %>%
    #cosi ho che se ho un progressione su T N ed M  un evento, se ho ptrogressione Su M o morte o vivo sono censorizzati

    #mi d? la data di un evento censura di sola progressione M+o morte) in caso di mancante alla fine metto il follow-up

    mutate(datelrc1 = case_when (g1_01_progrel %in% c(1,2) & (g1_06_meta == 1) & g1_04_local != 1 & g1_05_regional != 1 ~ g1_03_date,
                                  g2_01_progrel %in% c(1,2) & (g2_06_meta == 1) & g2_04_local != 1 & g2_05_regional != 1 ~ g2_03_date,
                                  g3_01_progrel %in% c(1,2) & (g3_06_meta == 1) & g3_04_local != 1 & g3_05_regional != 1 ~ g3_03_date,
                                  g4_01_progrel %in% c(1,2) & (g4_06_meta == 1) & g4_04_local != 1 & g4_05_regional != 1 ~ g4_03_date,
                                  g5_01_progrel %in% c(1,2) & (g5_06_meta == 1) & g5_04_local != 1 & g5_05_regional != 1 ~ g5_03_date,
                                  g6_01_progrel %in% c(1,2) & (g6_06_meta == 1) & g6_04_local != 1 & g6_05_regional != 1 ~ g6_03_date,
                                  g7_01_progrel %in% c(1,2) & (g7_06_meta == 1) & g7_04_local != 1 & g7_05_regional != 1 ~ g7_03_date,
                                  g8_01_progrel %in% c(1,2) & (g8_06_meta == 1) & g8_04_local != 1 & g8_05_regional != 1 ~ g8_03_date,
                                  g9_01_progrel %in% c(1,2) & (g9_06_meta == 1) & g9_04_local != 1 & g9_05_regional != 1 ~ g9_03_date,
                                  g10_01_progrel %in% c(1,2) & (g10_06_meta == 1) & g10_04_local != 1 & g10_05_regional != 1 ~ g10_03_date, TRUE ~ h02_datelasfup)) %>%

    #creo l evento, 1 se LRC ? presente 0 se invece c'? prima la morte o la metastasi
    #METTI IFELSe
    mutate(event_Lrc = case_when(is.na(datelrc)  ~ 0 ,
                                datelrc1 < datelrc  ~ 0,
                                datelrc1 >= datelrc ~  1 ,
                                TRUE ~ NA))%>%

    mutate(LRC = pmin(as.Date(datelrc), as.Date(datelrc1), na.rm= TRUE) - pmin(as.Date(f02_datesurg), as.Date(f33_1_startdate_syst), as.Date(f80_radiostartdate), na.rm=TRUE)) %>%
    as.data.frame()

  print('Number of columns after extend_data:')
  print(ncol(temp.data))

  return(temp.data)
}
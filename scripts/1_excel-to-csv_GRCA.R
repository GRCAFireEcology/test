# Created by: Alexandra Lalor
# Email: alexandra_lalor@nps.gov, allielalor@gmail.com
# Date Created: 2024-05-01
# Last Edited: 2024-08-02
#
# To take data from excel files and save individual protocols/tabs as CSVs,
# and name them appropriately

# Folder Setup:
# Navigate to where you store FX excel data files (e.g. data/GRCA/FMH/2023/)
# In this folder, create 2 subfolders. One called "Collected", and the other called "_CSV_Import to FFI"
# Put all your completed data collection excel spreadsheets into the "Collected" folder.
#   Make sure excel files are named as follows: MonitoringType_Plot#_Status (e.g. PIPN_08_02Year05.xlsx)
# The "_CSV_Import to FFI" folder should be empty. This is where CSVs will be stored after running this code.


################################################################################
# BEFORE STARTING
################################################################################

#install packages
install.packages("tidyverse")
#load packages
library(tidyverse)
library(readxl)

#identify working directory
#setwd("/Users/alalor.NPS/Desktop/FX_Lalor/R/GRCA/test")
getwd()


################################################################################
# MAKE SURE FILE PATHS ARE CORRECT
################################################################################

#load in data and name them based on file path
my_path_data <- "C:/Users/alalor.NPS/OneDrive - DOI/FireFX2.0/Data Collection/GRCA - FMH/2024/Collected/"
my_path_csv <- "C:/Users/alalor.NPS/OneDrive - DOI/FireFX2.0/Data Collection/GRCA - FMH/2024/_CSV_Import to FFI/"


################################################################################
# CREATE LIST OF DATA NEEDED
################################################################################

#create list of file names
file_names_list <- list.files(my_path_data)

#specify file path each excel sheet
file_path <- paste0(my_path_data, file_names_list)

#add file paths and names to a dataframe
file_names_df <- data.frame(FilePath = file_path, text = file_names_list) %>%
  separate(text, sep = ".xlsx", into = ("Plot_Status")) %>%
  separate("Plot_Status", sep = "_", into = c("MonitoringType", "Plot", "Read", "Tablet"), remove = FALSE)


################################################################################
# MAIN CODE / DO THE THING!
################################################################################

#separate excel files into tabs, save as CSVs, and name them appropriately
for(i in 1:nrow(file_names_df)) {
  path <- file_names_df[i,1]
  name <- file_names_df[i,2]

  #read tabs of excel files, bring them into R
  FuelsFWD <- read_excel(path, sheet = "Fuels FWD")
  FuelsCWD <- read_excel(path, sheet = "Fuels CWD")
  FuelsDuffLitt <- read_excel(path, sheet = "Fuels Duff-Litt")
  HerbsPoints <- read_excel(path, sheet = "Herbs (Points)")
  HerbsObs <- read_excel(path, sheet = "Herbs-Ob (Sp Comp)")
  Shrubs <- read_excel(path, sheet = "Shrubs (Belt)")
  Seedlings <- read_excel(path, sheet = "Seedlings (Quad)")
  Trees <- read_excel(path, sheet = "Trees")
  PostBurn <- read_excel(path, sheet = "Post Burn")

  #create csv paths
  my_path_csv_FuelsFWD <- paste0(my_path_csv, name, "_FuelsFWD.csv")
  my_path_csv_FuelsCWD <- paste0(my_path_csv, name, "_FuelsCWD.csv")
  my_path_csv_FuelsDuffLitt <- paste0(my_path_csv, name, "_FuelsDuffLitt.csv")
  my_path_csv_HerbsPoints <- paste0(my_path_csv, name, "_HerbsPoints.csv")
  my_path_csv_HerbsObs<- paste0(my_path_csv, name, "_HerbsObs.csv")
  my_path_csv_Shrubs<- paste0(my_path_csv, name, "_Shrubs.csv")
  my_path_csv_Seedlings <- paste0(my_path_csv, name, "_Seedlings.csv")
  my_path_csv_Trees <- paste0(my_path_csv, name, "_Trees.csv")
  my_path_csv_PostBurn <- paste0(my_path_csv, name, "_PostBurn.csv")

  #identify duplicate species in HerbsObs
  DuplicateHerbs <-
    merge(HerbsPoints, HerbsObs, by = "Species") %>%
    select(Species) %>%
    distinct(Species)
  DuplicateShrubs <-
    merge(Shrubs, HerbsObs, by = "Species") %>%
    select(Species) %>%
    distinct(Species)
  DuplicateSeedlings <-
    merge(Seedlings, HerbsObs, by = "Species") %>%
    select(Species) %>%
    distinct(Species)
  DuplicateTrees <-
    merge(Trees, HerbsObs, by = "Species") %>%
    select(Species) %>%
    distinct(Species)

  # Remove duplicate species from Herbs Obs)
  DuplicateSpecies <- rbind(DuplicateHerbs, DuplicateShrubs, DuplicateSeedlings, DuplicateTrees)
  HerbsObs <- anti_join(HerbsObs, DuplicateSpecies, by = "Species")
  # Count Herb heights to make sure some data is present
  HerbsPointsCount <- sum(!is.na(HerbsPoints$Height))

  # QAQC all protocols: Delete empty rows, Change numbers in index column into ascending order
  FuelsFWD <- subset(FuelsFWD, OneHr != "") %>%
    mutate(Index = row_number()) %>%
    map_df(str_replace_all, pattern = ",", replacement = ";")
  FuelsCWD <- subset(FuelsCWD, Dia != "") %>%
    mutate(Index = row_number())
  FuelsDuffLitt <- subset(FuelsDuffLitt, LittDep != "") %>%
    mutate(Index = row_number())
  HerbsPoints <-
    mutate(HerbsPoints, Count = HerbsPointsCount) %>%
    subset(Count != "0") %>%
    mutate(Index = row_number()) %>%
    map_df(str_replace_all, pattern = ",", replacement = ";")
  HerbsObs <- subset(HerbsObs, Species != "") %>%
    mutate(Index = row_number()) %>%
    map_df(str_replace_all, pattern = ",", replacement = ";")
  Seedlings <- subset(Seedlings, Species != "") %>%
    mutate(Index = row_number()) %>%
    map_df(str_replace_all, pattern = ",", replacement = ";")
  Shrubs <- subset(Shrubs, Species != "") %>%
    mutate(Index = row_number()) %>%
    map_df(str_replace_all, pattern = ",", replacement = ";")
  Trees <- subset(Trees, Status != "X") %>%
    arrange(SubFrac, QTR, TagNo) %>%
    mutate(Index = row_number()) %>%
    mutate(IsVerified = "TRUE") %>%
    map_df(str_replace_all, pattern = ",", replacement = ";")
  PostBurn <- subset(PostBurn, Sub != "") %>%
    mutate(Index = row_number())

  #create CSVs, exclude blank data frames
  if(dim(FuelsFWD)[1] == 0) {print(paste0(name," ","Fuels FWD is empty"))}
    else{write.csv(FuelsFWD, my_path_csv_FuelsFWD, quote=FALSE, row.names = FALSE, na = "")}
  if(dim(FuelsCWD)[1] == 0) {print(paste0(name," ","Fuels CWD is empty"))}
    else{write.csv(FuelsCWD, my_path_csv_FuelsCWD, quote=FALSE, row.names = FALSE, na = "")}
  if(dim(FuelsDuffLitt)[1] == 0) {print(paste0(name," ","Fuels Duff-Litt is empty"))}
     else{write.csv(FuelsDuffLitt, my_path_csv_FuelsDuffLitt, quote=FALSE, row.names = FALSE, na = "")}
  if(dim(HerbsPoints)[1] == 0) {print(paste0(name," ","Herbs Points is empty"))}
     else{write.csv(HerbsPoints, my_path_csv_HerbsPoints, quote=FALSE, row.names = FALSE, na = "")}
  if(dim(HerbsObs)[1] == 0) {print(paste0(name," ","Herbs Obs is empty"))}
     else{write.csv(HerbsObs, my_path_csv_HerbsObs, quote=FALSE, row.names = FALSE, na = "")}
  if(dim(Shrubs)[1] == 0) {print(paste0(name," ","Shrubs is empty"))}
     else{write.csv(Shrubs, my_path_csv_Shrubs, quote=FALSE, row.names = FALSE, na = "")}
  if(dim(Seedlings)[1] == 0) {print(paste0(name," ","Seedlings is empty"))}
     else{write.csv(Seedlings, my_path_csv_Seedlings, quote=FALSE, row.names = FALSE, na = "")}
  if(dim(Trees)[1] == 0) {print(paste0(name," ","Trees is empty"))}
    else{write.csv(Trees, my_path_csv_Trees, quote=FALSE, row.names = FALSE, na = "")}
  if(dim(PostBurn)[1] == 0) {print(paste0(name," ","Post Burn is empty"))}
    else{write.csv(PostBurn, my_path_csv_PostBurn, quote = FALSE, row.names = FALSE, na = "")}
  }



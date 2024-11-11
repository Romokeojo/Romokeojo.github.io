############################################################################################
# DSM with R for prediction of soil classes (associations) from terra cognita into terra 
# incognita, based on the Irish Soil Information System project
# Developed by Joanna Zawadzka and Ron Corstanje at Cranfield University (2018, 2020, 2023)
# Any queries email Joanna at joanna.zawadzka@cranfield.ac.uk
############################################################################################

##############################################
# Step 0: Installation of required R packages
##############################################
install.packages("ranger") #fast implementation of random forest
install.packages ("sp") #spatial operations and handling of vectors
install.packages("raster") #spatial operations and handling of rasters
install.packages("rgdal") #spatial data handling
install.packages("plyr") #handling of data tables
install.packages("caret") #for confusion matrices
install.packages("lattice") #required by caret
install.packages("ggplot2") #required by caret
install.packages("e1071") #required by caret
###############################################
# Step 1: Data preparation
###############################################

# Set working directory to the folder that holds the supplied training 
# and deployment text files
 # Please note that your actual path will vary from the one used in the example below
 # In R studio, best done by going to the Session-->Set Working Directory--> Choose Directory

setwd() # insert the path to the A_R folder here

# Create a folder to store your outputs
 # Path to the outputs folder:

outputs<-file.path("path to the A_R folder/Results")
dir.create(outputs) #create the folder with the dir.create() function

#**************************************************
# Step 1A: load the supplied training data file 
#**************************************************
# This is a stratified random sample of soil associations within terra cognita
training<-read.table("training_terra_cognita.txt", header = T, sep="\t") # tab "\t" separated text file
 
# Any no data values in this file are coded as -9999 and should be replaced with NA
# so that they appear as blank (empty) cells in the dataframe (data table)
training[training==-9999]<-NA

# View the table to see where the NAs are
View(training)

# Remove (omit) rows with missing data
training2<-na.omit(training)

# Calculate the number of rows with NA values - how many rows were removed?
nrow(training) - nrow(training2) # nrow() function calculates the number of rows in a dataframe

# the answer is 509 - a small fraction of the overall number of rows (~25k)
# therefore we can proceed with the task

# The training is no longer needed, and therefore can be overwritten with training2.df
# and training2.df can be removed from the environment

training<-training2

rm(training2) # remove from the environment
gc()# clear memory usage by R

# Let's view the training data table
View(training)

# The training table contains XY coordinates, the slasscn field that stores the soil
# association codes as well as a set of various environmental covariates
# Also, NAs are no longer within the table!

#**************************************************
# Step 1B: load the supplied deployment data file for terra incognita
#**************************************************
# Load the supplied deployment data file for terra incognita
deployment_ti<-read.table("deployment_terra_incognita.txt", header=T, sep="\t")

# Set -9999 to no data
deployment_ti[deployment_ti==-9999]<-NA

# View the table to see where the NAs are
View(deployment_ti)
# in this case, its is not easy to find NAs, however, we will run na.omit on this 
# table just in case NAs exist

# Omit rows with missing data
deployment_ti2<-na.omit(deployment_ti)

# Calculate the number of rows with NA values - how many rows were removed?
nrow(deployment_ti) - nrow(deployment_ti2)

# the answer is 109 - again a relatively small number. This means that locations
# represented by these rows will not by covered by the predictive map

# The deployment_ti is no longer needed, and therefore can be overwritten with deployment2
# and deployment2 can be removed from the environment

deployment_ti<-deployment_ti2

rm(deployment_ti2) # remove from the environment
gc()# clear memory usage by R

# Let's view the deployment data table
View(deployment_ti)

# Notice that the deployment table contains the Ref_Soil column - this is a column
# containing reference soil values that will be used in the validation of the 
# predictive soil map later in this exercise
# The reference soil values, for the purpose of demonstration of the concept, 
# were taken from the actual predictive map generated during the Irish SIS project
# In real life situations, however, the reference data would constitute an independently
# captured sample of soil information

#*********************************************************************************
# Step 1C: Equalise factor levels between the training and deployment samples
#*********************************************************************************
# This is important because either the training or deployment data tables may 
# not contain all instances of classes in categorical variables

# This will make sure that each categorical variable has the same factor 
# level in both the training and deployment data tables

# This is essential for the prediction process to work correctly as it removes potential confusion 
# between classes in categorical variables stored within the training and deployment tables

# We will overcome this problem by combining the training and deployment tables into a single
# long table, and then separating them back again

# Add "Sample_Type" field to dataframes with the training and deployment data
# and calculate as "training" or "deployment". This will help separate the tables back after combining.

training$Sample_Type<-"training"
deployment_ti$Sample_Type<-"deployment"

# let's check the factor levels of a selected categorical variable in the training an deployment samples
levels(as.factor(training$ASO2))
levels(as.factor(deployment_ti$ASO2))

# are the numbers different? if yes, this means their factor levels will also be different
# we can safely assume that this is the case for all other categorical variables

# Before combining tables, change the name of Ref_Soil column in the deployment dataframes to slasscn
# to ensure that both the training and deployment tables have exactly the same column names
colnames(deployment_ti)[4]<-"slasscn" # [4] denotes the fourth column, which is Ref_Soil (Reference Soil)

# Combine dataframes
combined<-rbind(training, deployment_ti)

# Convert all character columns that store SCORPAN covariates to factors
# Note that data type of each column can be established by expanding the data frame structure in the Environment
# on the right-hand side
combined$slasscn<-as.factor(combined$slasscn)
combined$AA162<-as.factor(combined$AA162)
combined$AHA2<-as.factor(combined$AHA2)
combined$ANM2<-as.factor(combined$ANM2)
combined$ASO2<-as.factor(combined$ASO2)
combined$COR<-as.factor(combined$COR)
combined$GEO<-as.factor(combined$GEO)
combined$GSM<-as.factor(combined$GSM)
combined$HAB<-as.factor(combined$HAB)
combined$SBS<-as.factor(combined$SBS)

# Extract the training and deployment samples from the combined file
training<-combined[which(combined$Sample_Type=='training'),]
deployment_ti<-combined[which(combined$Sample_Type=='deployment'),]

#Extract columns from training file that contain SCORPAN covariates only, i.e. exclude ID, X, Y
training<-training[,4:32] # this means we are only interested in columns 4:32, 
                                # as the first three contain the ID, X, and Y fields, 
                                # and the last one - the Sample_Type field we added earlier

###################################################
# Step 2: Model development - Random Forests
###################################################
# First, set the workspace to your output folder - your results will be saved in there
setwd(outputs)

#*****************************************************************************************************
# Step 2A: Load the required library
#*****************************************************************************************************
library(ranger) #implementation of Random Forest

#*****************************************************************************************************
# Step 2B: Train 100 trees with random forests
#*****************************************************************************************************

# create an object that will store the random forest model  (rf100)
rf100<-ranger(slasscn ~ .,            # formula relating ~ the dependent slasscn variable
                                       # to all other variables "." in the input training table
             data=training,           # table holding the training data
             write.forest = T,        # save the forest to enable prediction on the deployment data
             num.trees=100,           # number to trees to grow
             importance = "impurity", # the Gini index to determine variable importance
             verbose = T)             # include the progress bar

gc()# clear memory usage by R

#*****************************************************************************************************
# Step 2C: Create a dataframe with variable importance scores and visualize them
#*****************************************************************************************************
# Call the variable.importance object stored in the trained model
# and covert it to a data frame
importance_rf100<-as.data.frame(rf100$variable.importance)

# View the variable importance table
View(importance_rf100)

# Change the name of the column storing variable importance scores
colnames(importance_rf100)[1]<-"Var_importance"

# add a new column to store the names of the SCORPAN covariates that are currently row names
importance_rf100$SCORPANcov<-rownames(importance_rf100)

# View the variable importance table
View(importance_rf100)

# sort the importance table according to decreasing values of the Gini Index
importance_rf100<-importance_rf100[order(importance_rf100$Var_importance, importance_rf100$SCORPANcov,decreasing = TRUE),]
View(importance_rf100)
# Create a bar graph showing variable importance
# using functionality of the ggplot2 library

library(ggplot2)

imp<-ggplot(data = importance_rf100,                     # data table storing the variable importance data
            aes(x = Var_importance,   # column to be plotted on x axis,
                y = reorder(SCORPANcov, Var_importance),      # column to be plotted on y axis, reordered by the var_importance values
                fill = reorder(SCORPANcov, Var_importance)))+ # column to be used to colour the bars, reordered by the var_importance values                         
  geom_bar(stat = "identity")+                              # plotting the bar graph
  labs(x = "Variable importance",                           # adjusting the x axis label
       y = "SCORPAN factors",                               # adjusting the y axis label
       title = "Random Forest variable importance")+        # adjusting the plot title
  scale_fill_viridis_d()+                                   # color gradient for categorical variables (use help for more colour options)
  theme_bw()+                                               # adding the black and white theme
  theme(legend.position="none")                             # remove plot legend

# view the plot
imp

# save the plot as a jpeg
 # it will be saved inside the working directory, which has been set to the Results folder created at the 
 # start of this tutorial
ggsave("Random_Forest_var_imp.jpeg", # file name and format
       imp,                          # the plot to be saved
       width = 1750,                 # width of the image
       height = 1500,                # height of the image
       units = "px",                 # unit at which the height and width are measured (px - pixels)
       dpi = 300)                    # resolution of the image

# which SCORPAN factors where the strongest and weakest predictors of soils?
 # note - the higher the Gini index value, the higher the importance

#*****************************************************************************************************
# Step 2D: save the variable importance table as a tab delimited text file for future reference
#*****************************************************************************************************
write.table(importance_rf100,               # the data frame storing variable importance values
            file="rf_importance_terra.txt", # the name of the output file with extension
            row.names=F,                 # to exclude row names
            col.names=T,                 # to include column names
            sep="\t",                    # to specify Tab as the separator between columns in the output txt file
            quote=F)                     # to exclude quotation marks "" from strings stored in the txt file

#*****************************************************************************************************
# Step 2E: Extract the prediction error and confusion matrix
#*****************************************************************************************************
# Call the prediction.error object stored in the trained model
 # This is an overall out of bag prediction error expressed as a fraction of 
 # misclassified samples
rf_training_error<-rf100$prediction.error

# Display the error in the console
rf_training_error

# Call the confusion.matrix object stored in the trained model
 # This is based solely on the training data sample and therefore 
 # can be used for model diagnostic purposes rather that reporting
 # accuracy scores, which should be done with the use of an independent
 # validation (reference) data sample
rf_training_matrix <- as.data.frame(rf100$confusion.matrix)

# View the confusion matrix
View(rf_training_matrix) 
 # note that this is a long table that needs to be reformatted to form a confusion matrix

# Create a contingency table to display the confusion matrix correctly

# library(reshape) - commented out as we are going to use the :: method to
# use the cast() function from the reshape library
# the cast function will calculate the sums of data rows in 
# the contingency table formed from the true and predicted columns
# in the rt_training_matrix dataframe
conf<-reshape::cast(rf_training_matrix, true ~ predicted, sum)

#view the confusion matrix
View(conf)

#save into a csv format for easy import into MS Excel
write.csv(conf,
          "training_confusion_matrix.csv",
          row.names = F)


################################################################################
# Step 3: Model deployment - prediction from terra cognita into terra incognita
################################################################################

#deploy the model to get predicted soil associations in terra incognita
pred_rf100_ti<-predict(rf100,             #this is our trained model
                    data=deployment_ti,    #deployment dataset for terra incognita
                    type="response",       #to indicate we want to predict soil classes 
                                             #rather than view standard error, terminal nodes or quantiles
                    predict.all=F)         #to return aggregated predictions for all trees rather than predictions of individual trees

#save the predicted soil associations into a dataframe
pred_RF_ti<-as.data.frame(pred_rf100_ti$predictions)

# View the table containing the predicted soil association values
View(pred_RF_ti)

# change the column name
colnames(pred_RF_ti)[1]<-"RF_PRED"

# join with the deployment_ti3 dataset to ensure each predicted value is linked to its xy coordinate
pred_RF_ti<-cbind(pred_RF_ti, deployment_ti)

# View the table again
View(pred_RF_ti)
 # note that the predicted soil associations (RF_PRED) are stored in the first column
 # the reference soil values for independent validation are stored in the slasscn column


###################################################
# Step 4: Mapping the predictions: GeoTiff rasters
###################################################
#load libraries that work with spatial data
library(sp)
library(raster)

#create a dataframe with predicted, X and Y columns only
pred_RFxy_ti<-pred_RF_ti[,c(3:4,1)] 

#######################################################################
# The below lines of code present a method of conversion of a 
# data table with XY coordinates to a raster layer that can be saved
# on the disk in a GeoTiff format to be used with other applications
# such as ArcGIS Pro or other GIS software
#######################################################################

# point to the fields storing XY coordinates
coordinates(pred_RFxy_ti)<-~X+Y 

# define as a gridded dataset
gridded(pred_RFxy_ti)<-TRUE 

# convert to raster
raster_RF_ti<-raster(pred_RFxy_ti)

# apply the TM65 / Irish Grid -- Ireland coordinate system (ESPG: 29902) https://epsg.io/29902 PROJ.4 code
crs(raster_RF_ti)<-'+proj=tmerc +lat_0=53.5 +lon_0=-8 +k=1.000035 +x_0=200000 +y_0=250000 +a=6377340.189 +rf=299.3249646 +towgs84=482.5,-130.6,564.6,-1.042,-0.214,-0.631,8.15 +units=m +no_defs +type=crs'

# make a simple plot of the raster
plot(raster_RF_ti$RF_PRED) 

# ensure that the raster is an integer raster
dataType(raster_RF_ti) # check data type
dataType(raster_RF_ti)<-'INT2S' # apply the desirable data type
dataType(raster_RF_ti) # check data type again

# save as a tif file
writeRaster(raster_RF_ti,"RF_prediction_ti.tif", format="GTiff", datatype='INT2S', overwrite = T) 
 # note that this tif raster only contains the factor levels of the predicted
 # soil associations and there is no raster attribute table that will show the soil association codes

########################################################################
# Create a lookup table (LUT) with soil associations codes
########################################################################

# create a dataframe with predicted, X and Y columns only
levels_RF_ti<-as.data.frame(levels(pred_RF_ti$RF_PRED))

# add the VALUE field and calculate as row names
levels_RF_ti$VALUE<-rownames(levels_RF_ti)

# change column names of levels_RF data frame
colnames(levels_RF_ti)<-c("RF_Pred", "VALUE")

# change the order of columns
levels_RF_ti<-levels_RF_ti[,c("VALUE","RF_Pred")]

View(levels_RF_ti)

# Write as a csv file making sure the file 
write.csv(levels_RF_ti, "RF_levels_ti.csv", row.names=F)

################################################################################
# Step 5: Accuracy assessment using independent data (confusion matrix)
################################################################################
library(caret)
#**********************************************************************************
# Step 5: Confusion matrix for RF predictions (Terra cognita into Terra incognita)
#**********************************************************************************
# Again, we will combine the tables with the predicted and reference values
# to equalise the factor levels

# First, extract the predicted values from the pred_RF_ti table alongside the XY coordinates
# the XY coordinates will help us map areas with correct and incorrect predictions
pred_ti<-pred_RF_ti[,c("X", "Y", "RF_PRED")]
View(pred_ti)

# Add Sample_Type column and populate with "prediction" 
pred_ti$Sample_Type<-"prediction"

# Extract the referee data from the deployment table
reference_ti<-as.data.frame(deployment_ti$slasscn)

# Add Sample_Type column and populate with "reference" 
reference_ti$Sample_Type<-"reference"

# View the column names of the reference_ti table
colnames(reference_ti)

# Notice, the first column is called "deployment_ti$slasscn" - we want to change that
colnames(reference_ti)[1]<-"RF_PRED"#just to match col names
colnames(reference_ti) #check the column names again

# before combining the tables, let's check their factor levels
levels(reference_ti$RF_PRED)
levels(pred_ti$RF_PRED)
# the levels look the same - we did equalise them after all at the start of the tutorial

# combine the tables using the rbind() function
combined_rf_ti<-rbind(pred_ti, reference_ti)

# we got an error message! Let's investigate why!
# The error message says: numbers of columns of arguments do not match
# Let's view both tables

View(pred_ti)
View(reference_ti)

# turns out the reference_ti table does not contain the XY coordinates columns
# for rbind to work, we need the exact number of columns called exactly the same in both tables
# let's try the rbind() again, asking R to take only the RF_PRED and Sample_Type columns from pred_ti

combined_rf_ti<-rbind(pred_ti[,c("RF_PRED", "Sample_Type")], reference_ti)

# this time no error message occurred. Lets view the combined table
View(combined_rf_ti) # notice the number of rows equals the sum pf pred_ti and reference_ti

# separate the predicted and reference entries
predicted_RF<-combined_rf_ti[which(combined_rf_ti$Sample_Type=='prediction'),]
reference_ti<-combined_rf_ti[which(combined_rf_ti$Sample_Type=='reference'),]

# let's view the factor levels 
levels(predicted_RF$RF_PRED)
levels(reference_ti$RF_PRED)
# are they the same?


#******************************************************************************
#*Generating a confusion matrix with the caret package
#******************************************************************************
# create vectors of factors with predicted and reference values 
predicted<-as.factor(predicted_RF$RF_PRED)
reference<-as.factor(reference_ti$RF_PRED)

# make a confusion matrix (RF terra incognita)
rf_ti_confusion_mx<-confusionMatrix(predicted, reference)

# extract overall accuracy scores
rf_ti_confusion_mx$overall

# convert to a data frame
overall<-as.data.frame(unlist(rf_ti_confusion_mx$overall)) # note that the unlist() 
# function is needed to extract the overall table from the lists of tables in the rf_ti_confusion_mx_df object
# which is a list

View(overall)

#change column name of the overall df
colnames(overall)<-"Overall_Accuracy"

# what can you tell about the accuracy of the predicted map verified with the independent reference sample?
# Why do you think there is a difference as compared  to the accuracy assessed from the out-of-bag method during model training?

# Save the accuracy statistics into a csv
write.csv(overall, "RF_TC_into_TI_conf_mtrx_overall.csv", row.names=T) # note that this time we want to keep the row names
# as these contain stats names

# Now, let's move on to the actual confusion matrix, and extract it from the output of the consfusionMatrix() function
View(rf_ti_confusion_mx$table)
rf_ti_conf<-as.data.frame(unlist(rf_ti_confusion_mx$table))

# change the long format to the wide format
conf_mx<-reshape::cast(rf_ti_conf, Prediction ~ Reference, sum)

#Now, save the confusion matrix table
write.csv(conf_mx, "RF_TC_into_TI_conf_mtrx_table.csv", row.names=T)

###########################################################################
## Bonus - Create a map of locations of correct and incorrect predictions
###########################################################################

# let's combine the pred_ti table (with prediction and XY coordinates)
# with the reference_ti table (with reference soil associations using the cbind() function
pred_ref_ti<-cbind(pred_ti, reference_ti)
View(pred_ref_ti)

# change the column names to ensure that predictions and reference values are called differently
colnames(pred_ref_ti)[3] <- "Predicted" # changing the name of 3rd column
colnames(pred_ref_ti)[5] <- "Reference" # changing the name of 5th column

#remove Sample_Type fields
pred_ref_ti[, c(4,6)]<-NULL # note that this removes column 4 and 6

# create a column storing a statement whether the prediction was correct or incorrect
# we will use the ielse() statment here

pred_ref_ti$Agreement<- ifelse(pred_ref_ti$Predicted == pred_ref_ti$Reference, "Correct", "Incorrect")
View(pred_ref_ti)

# Let's now plot the correct and incorrect values using ggplot2

agreement<-ggplot(pred_ref_ti, aes(x = X, y = Y, colour = Agreement)) +
  geom_point() +
  scale_color_manual(values=c("darkolivegreen1","indianred1")) + #colors in R: http://www.stat.columbia.edu/~tzheng/files/Rcolor.pdf
  coord_fixed(ratio = 1) + #making sure that x and y axis maintain their aspect ratio
  theme_bw() +
  theme(legend.position = "bottom", # move legend to the bottom of the graph
        legend.title = element_blank()) #remove legend title

agreement

ggsave("terra_incognita_agreement.jpeg", 
       agreement,
       width = 1800, 
       height = 1500,
       units = "px",
       dpi = 300)



###########################################################################################################
# End of RF modelling
# Now, move on to TASKS 4 and 5 in the tutorial handout to create a map of predicted 
# soil associations in ArcGIS Pro environment
###########################################################################################################


###########################################
# CHALLENGE
###########################################

# Create a predictive map of soil associations using the second scenario: 
# terra cognita into terra cognita. Use this script to guide you in the process.


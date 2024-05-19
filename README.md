# Track's Genres Prediction with Spotify Dataset
_Author: Clara Le_

_Date: 26/4/2023_

---
Spotify is an audio streaming and media services provider with over 365 million monthly active users, and 165 million paying subscribers. This analysis is conducted according to Spotify’s demand to better recommend or advertise songs to customers and more effective update compilation playlists through predicting what genre a song belongs to. The data set used in this analysis contains 6000 observations with 1000 observations for each track’s genre, 1 response variable (“track_genre”) and 43 predictors. 

After performing data cleaning and preprocessing, EDA, applying machine learning models, there are several main findings as belows:
+ Among 43 predictors used in predicting track’s genres, the five most important predictors are **track’s released year** (“year_released” variable), **track’s danceability** (“danceability” variable), **track’s tempo** (“tempo” variable), **track’s speechiness** (“speechiness” variable), and **track’s energy** (“energy” variable). Besides these predictors, other track’s features such as liveness, mode and key have less importance in predicting genres. Additionally, artist Ballin Entertainment, Queen, 2Pac, Gloria Estefan, Don Omar, Kiss, Janelle Monae and Logic also contribute to genre predictions, but their importance is not significant.
<a href="url"><img src="https://github.com/Tien-le98/DA_Project_Spotify/blob/main/feature_importance" align="center" height="500" width="700" ></a>
<a href="url"><img src="https://github.com/Tien-le98/DA_Project_Spotify/blob/main/year_released" align="right" height="250" width="350" ></a>
+ In terms of the predictor **year_released**, it has 61 unique years ranging from 1957 to 2020. Around 73.5% tracks released from 1990 backward are mainly rock tracks. Therefore, if a track released from 1990 backward, it can be more likely to be a rock track. To tracks released between 1991 and 2000, around 36.2% tracks are r&b, about 28.7% tracks are rock, and about 22.2% tracks are rap. To tracks released after 2000, they have all six types of genres, but the most popular genre is edm and the least popular genre is rock. In addition, about 99.6% of edm tracks were released after 2000.

+ To the predictor **danceability**, the average value track’s danceability varies between different genres. The figure for rock is the lowest while the figure for rap is the highest. Track’s danceability in ascending order is rock, pop, edm, r&b, latin and rap.
+ In terms of the predictor **tempo**, the average value track’s tempo varies between different genres. The figure for r&b is the lowest while the figure for edm is the highest. Track’s tempo in ascending order is r&b, latin, pop, rock, rap and edm.
+ The average value of **track’s speechiness** varies between different genres. The figure for rock is the lowest while the figure for rap is the highest. Track’s speechiness in ascending order is rock, pop, edm, latin, r&b and rap.

<p align="center" width="100%">
    <img width="30%" src="https://github.com/Tien-le98/DA_Project_Spotify/blob/main/danceability">
    <img width="30%" src="https://github.com/Tien-le98/DA_Project_Spotify/blob/main/tempo">
    <img width="30%" src="https://github.com/Tien-le98/DA_Project_Spotify/blob/main/speechiness">
</p>

+ To the predictor **energy**, the average value track’s energy varies between different genres. The figure for r&b is the lowest while the figure for edm is the highest. Track’s energy in ascending order is r&b, rap, pop, latin, rock and edm.
+ The average value of **track’s popularity** varies between different genres. The figure for edm is the lowest while the figure for pop is the highest. Track’s popularity in ascending order is edm, r&b, rap/rock, latin and pop. The average value of rap track’s popularity is equal to the figure for rock tracks. In addition, the average value of **track’s popularity** fluctuates significantly, meaning that there is no clear trend in track’s popularity over time.

<p align="center" width="100%">
    <img width="30%" src="https://github.com/Tien-le98/DA_Project_Spotify/blob/main/energy_plot">
    <img width="30%" src="https://github.com/Tien-le98/DA_Project_Spotify/blob/main/popularity">
</p>

+ After considering three different models which are a linear discriminant analysis model, a K-nearest neighbours model and a random forest model, the **random forest model** with mtry equals to 11 (the number of predictors that will be randomly sampled at each split is 11), 100 trees (the number of trees contained in the ensemble is 100) and min_n equals to 21 (the minimum number of data points in a node that are required for the node to be split further is 21) seems to be the best model.

| ML model | Accuracy    | AUC    |
| :---:   | :---: | :---: |
| Linear Discriminant Analysis (LDA) | 0.505   | 0.817   |
| K-nearest Neighbours (KNN) | 0.519   | 0.824   |
| **Random Forest** | **0.561**   | **0.824**   |

## Random Forest performance
The overall model’s performance on the processed testing set is showed through metrics such as average sensitivity (0.56), average specificity (0.912), and average AUC (0.852). This model has high average value of AUC, which is area under the ROC curve, so this model can be a good discrimination when considering AUC value. Additionally, the value of specificity is high, but the value of sensitivity is pretty low. Each metrics of each genre as shown below:
+ To **sensitivity**, the model has sensitivity value of 0.692 in predicting edm tracks, which means that if a track is edm, the model correctly predicting it as responding “edm” 69.2% of the time. Accordingly, the figure for latin tracks is 42.2% of the time, pop tracks is 45.7% of the time, r&b tracks is 42.9% of the time, rap tracks is 58.3% of the time and rock tracks is 77.7% of the time. So, the model has the highest probability of correctly predicting rock tracks and the lowest probability of correctly predicting latin tracks.
+ To **specificity**, the model has specificity value of 0.927 in predicting non-edm tracks, which means that if a track is not edm, the model correctly predicting it as responding different from “edm” is 92.7% of the time. Accordingly, the figure for latin tracks is 91.5% of the time, pop tracks is 87.5% of the time, r&b tracks is 91.9% of the time, rap tracks is 90.1% of the time, and rock tracks is 93.5% of the time. So, the model has high specificity values in all kinds of genres, it has the highest probability of correctly predicting non-rock tracks and the lowest probability of correctly predicting non-pop tracks.
+ Although **the average AUC** is high (0.852) which can indicate a good discrimination, the average sensitivity and sensitivity value of each track’s genre are low, meaning that this model can not be good at predicting actual track’s genres. Based on roc curves, in terms of the sensitivity values, the model also has the highest probability of correctly predicting rock tracks and the lowest probability of correctly predicting latin tracks. It can be because released year is the most important predictor in predicting track’s genres, and tracks released from 1990 backward are mainly rock tracks, therefore, rock tracks can be distinguished more clearly than other track’s genres. Besides, this model can also be good at predicting edm tracks. However, this model may not be good at predicting other genres because their sensitivity values are low.

 <a href="url"><img src="https://github.com/Tien-le98/DA_Project_Spotify/blob/main/ROC_curves" align="center" height="500" width="700" ></a>
 
> To increase this model’s performance, in future analysis, the data set should include more features which can contribute to predict track’s genres and create better way to manage playlist’s genres. Because playlist’s genres are used to identify track’s genres, if playlist’s genres can be set and modified by users, playlist’s genres can be incorrect, which can lead to wrong track’s genres.

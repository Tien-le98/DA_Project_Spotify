# Load necessary packages
# pacman::p_load(tidyverse, tidymodels, dplyr, readr, stringr, forcats, inspectdf, recipes)
# library(spotifyr)
# library(lubridate)
# library(skimr)
# library(janitor)
# library(moments)
# library(themis)
# library(discrim)
# library(vip)
# library(knitr)

pacman::p_load(tidymodels)

# Load data to dataframe spotify_songs
spotify_songs <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2020/2020-01-21/spotify_songs.csv')
head(spotify_songs, n = 6)


library(stringr)
library(inspectdf)
# DATA CLEANING
# Extract released year for each observation in the data set
spotify_df <- spotify_songs %>%
  mutate(year_released = str_match(track_album_release_date, '(\\d{4})')[,2])

# Convert playlist_genre to factor and year_released to numeric
spotify_df <- spotify_df %>% mutate(playlist_genre = factor(playlist_genre, ordered = FALSE),
                                    year_released = as.numeric(year_released))

# Check missing values in the data set
inspect_na(spotify_df)

# Drop missing values
spotify_df <- spotify_df %>% drop_na()

# Check valid track's features

#ADD MORE CHECKING FOR EACH PREDICTOR

spotify_df %>% filter(!between(loudness, -60, 0))
spotify_df %>% filter(tempo == 0)

# Remove observations having invalid loudness and invalid tempo
spotify_df <- spotify_df %>%
  mutate(key = as.integer(key)) %>%
  filter(-60 <= loudness & loudness <= 0) %>%
  filter(tempo > 0)

# Create a table “playlist_spotify” and a table "track_spotify" 
playlist_spotify <- spotify_df %>% dplyr::select(contains("playlist"), track_id)
track_spotify <- spotify_df %>% dplyr::select(!contains("playlist"))

# Clean the table "playlist_spotify"
## Check if a track only appear one time in a playlist
playlist_spotify %>% count(playlist_id, track_id) %>% arrange(desc(n))

## Only take 1 observation of a track in a playlist
playlist_spotify <- playlist_spotify %>% distinct(playlist_id, track_id, .keep_all = TRUE)

## Check if a playlist_id has one playlist_name
playlist_spotify %>% distinct(playlist_id, playlist_name) %>% count(playlist_id) %>% arrange(desc(n))

## Create a column for track's genres ('track_genre'), defined by 'playlist_genre'
## (Ex: If a track appear mainly in a rock playlist, it can be more likely to be a rock track)
playlist_spotify %>% count(track_id, playlist_genre) %>% arrange(desc(n))
playlist_spotify <- playlist_spotify %>% group_by(track_id) %>%
  count(track_id, playlist_genre) %>% arrange(track_id, desc(n)) %>% slice(1) %>% dplyr::select(-n) %>%
  rename(track_genre = playlist_genre) %>% ungroup()

## Check if 1 track has 1 track's genre
playlist_spotify %>% count(track_id, track_genre) %>% arrange(desc(n))

# Check table "track"
## Only take unique observations (unique tracks)
track_spotify <- track_spotify %>% distinct()

## Check if unique track_id has unique track_name
track_spotify %>% count(track_id, track_artist) %>% arrange(desc(n))

## Check if unique track_id has unique track_artist
track_spotify %>% count(track_id, track_artist) %>% arrange(desc(n))

## Check if unique track_id is in unique track_album_id
track_spotify %>% count(track_id, track_album_id) %>% arrange(desc(n))

## Check if unique track_id has unique track_album_release_day
track_spotify %>% count(track_id, track_album_release_date) %>% arrange(desc(n))

## Check if unique track_id has unique track_popularity
track_spotify %>% count(track_id, track_popularity) %>% arrange(desc(n))

## Check if unique track_id has unique track_album_name
track_spotify %>% count(track_id, track_album_name) %>% arrange(desc(n))

## Check if unique track_id has unique danceability
track_spotify %>% count(track_id, danceability) %>% arrange(desc(n))

## Check if unique track_id has unique track_album_name
track_spotify %>% count(track_id, energy) %>% arrange(desc(n))

## Check if unique track_id has unique track_album_name
track_spotify %>% count(track_id, key) %>% arrange(desc(n))

## Check if unique track_id has unique loudness
track_spotify %>% count(track_id, loudness) %>% arrange(desc(n))

## Check if unique track_id has unique mode
track_spotify %>% count(track_id, mode) %>% arrange(desc(n))

## Check if unique track_id has unique speechiness
track_spotify %>% count(track_id, speechiness) %>% arrange(desc(n))

## Check if unique track_id has unique acousticness
track_spotify %>% count(track_id, acousticness) %>% arrange(desc(n))

## Check if unique track_id has unique instrumentalness
track_spotify %>% count(track_id, instrumentalness) %>% arrange(desc(n))

## Check if unique track_id has unique liveness
track_spotify %>% count(track_id, liveness) %>% arrange(desc(n))

## Check if unique track_id has unique valence
track_spotify %>% count(track_id, valence) %>% arrange(desc(n))

## Check if unique track_id has unique tempo
track_spotify %>% count(track_id, tempo) %>% arrange(desc(n))

## Check if unique track_id has unique duration_ms
track_spotify %>% count(track_id, duration_ms) %>% arrange(desc(n))

# Join table "track_spotify" and table "playlist_spotify" by track_id, to take track's features
spotify_final <- playlist_spotify %>% inner_join(track_spotify, by = "track_id")

# Remove all columns with name (track_name, track_album_name) 
# because these name can be given arbitrarily so they may not have relationship with genre
spotify_final <- spotify_final %>% dplyr::select(!(contains("name")))

# Remove track_release_year because variable "year_released" is already created
spotify_final <- spotify_final %>% dplyr::select(-track_album_release_date)

# Check the number of track's genre
print(spotify_final %>% count(track_genre)%>% arrange(n), n = 10) 

# Set seed for reproducibility
set.seed(1872398)

# Reduce the data set, only take 1,000 tracks per genre
spotify_1000 <- spotify_final %>% group_by(track_genre) %>% sample_n(1000) %>% ungroup()
head(spotify_1000, n = 6)

# Clean variable track_artist
## Create a table for track's artists including track_id, track_artist and track_genre
spotify_1000_artist_origin <- spotify_1000 %>% 
  dplyr::select(track_id, track_artist, track_genre) %>% distinct()

## Check artists having 10 tracks or more
spotify_1000_artist_origin %>% count(track_artist) %>% 
  count(n) %>% 
  mutate(prop = round(nn*100/ sum(nn),3)) %>% 
  filter(n >= 10)

library(janitor)
## Create a pivot table for track_artist
spotify_1000_artist <- spotify_1000_artist_origin %>%
  add_count(track_id, track_artist, track_genre) %>%
  arrange(desc(n)) %>%
  pivot_wider(names_from = track_artist, values_from = n, values_fill = list(n=0)) %>%
  clean_names()

## Take a list of track's artists having 10 tracks or more and clean artist's names
track_artist_morethan10 <- spotify_1000 %>% count(track_artist) %>% 
  filter(n >= 10) %>% pull(track_artist)

track_artist_morethan10 <- make_clean_names(track_artist_morethan10)

## Only take track's artists having 10 tracks or more, do not include variable "track_artist"
spotify_1000_artist <- spotify_1000_artist %>% 
  dplyr::select(track_id, track_genre, all_of(track_artist_morethan10))

# Join table "spotify_1000" and table "spotify_1000_artist" together by using variable "track_id"
spotify_1000 <- spotify_1000 %>% 
  inner_join(spotify_1000_artist %>% dplyr::select(-track_genre), by = c("track_id"))

# Remove all columns with ID (track_id, track_album_id) and track_artist
spotify_1000 <- spotify_1000 %>% dplyr::select(-track_id, -track_album_id, -track_artist)

library(moments)
# EXPLORATORY DATA - PLOT NUMBERS???
# Summary statistics of predictors related to track’s features
## Summary statistics of track_popularity
spotify_1000 %>% ggplot(aes(x = track_popularity)) + geom_histogram() + ylab("Frequency")
skewness(spotify_1000$track_popularity)
round(summary(spotify_1000$track_popularity),3)
round(sd(spotify_1000$track_popularity),3)
quantile_v <- round(quantile(spotify_1000$track_popularity),3)
quantile_v
q_1 <- round(as.numeric(quantile_v[2]),3)
q_3 <- round(as.numeric(quantile_v[4]),3)
iqr_v <- q_3 - q_1
iqr_v
spotify_1000 %>% 
  filter(!(between(track_popularity, q_1 - 1.5*iqr_v, q_3 + 1.5*iqr_v))) %>% count()

## Summary statistics of danceability
spotify_1000 %>% ggplot(aes(x = danceability)) + geom_histogram() + ylab("Frequency")
skewness(spotify_1000$danceability)
round(summary(spotify_1000$danceability),3)
quantile_v <- round(quantile(spotify_1000$danceability),3)
quantile_v
q_1 <- round(as.numeric(quantile_v[2]),3)
q_3 <- round(as.numeric(quantile_v[4]),3)
iqr_v <- q_3 - q_1
iqr_v
spotify_1000 %>% 
  filter(!(between(danceability, q_1 - 1.5*iqr_v, q_3 + 1.5*iqr_v))) %>% count()

## Summary statistics of energy
spotify_1000 %>% ggplot(aes(x = energy)) + geom_histogram() + ylab("Frequency")
skewness(spotify_1000$energy)
round(summary(spotify_1000$energy),3)
quantile_v <- round(quantile(spotify_1000$energy),3)
quantile_v
q_1 <- round(as.numeric(quantile_v[2]),3)
q_3 <- round(as.numeric(quantile_v[4]),3)
iqr_v <- q_3 - q_1
iqr_v
spotify_1000 %>% 
  filter(!(between(energy, q_1 - 1.5*iqr_v, q_3 + 1.5*iqr_v))) %>% count()

## Summary statistics of key
spotify_1000 %>% ggplot(aes(x = key)) + geom_bar() + ylab("Frequency") # Should key is factor???
spotify_1000 %>% 
  count(key) %>% arrange(desc(n)) %>% mutate(prop = round(100*n/sum(n),3))

## Summary statistics of loudness
spotify_1000 %>% ggplot(aes(x = loudness)) + geom_histogram() + ylab("Frequency")
skewness(spotify_1000$loudness)
round(summary(spotify_1000$loudness),3)
quantile_v <- round(quantile(spotify_1000$loudness),3)
quantile_v
q_1 <- round(as.numeric(quantile_v[2]),3)
q_3 <- round(as.numeric(quantile_v[4]),3)
iqr_v <- q_3 - q_1
iqr_v
spotify_1000 %>% 
  filter(!(between(loudness, q_1 - 1.5*iqr_v, q_3 + 1.5*iqr_v))) %>% count()

## Summary statistics of mode
spotify_1000 %>% ggplot(aes(x = mode)) + geom_bar() + ylab("Frequency") # Should mode is factor???
spotify_1000 %>% count(mode) %>% mutate(prop = round(n*100/ sum(n),3))

## Summary statistics of speechiness
spotify_1000 %>% ggplot(aes(x = speechiness)) + geom_histogram() + ylab("Frequency")
skewness(spotify_1000$speechiness)
round(summary(spotify_1000$speechiness),3)
quantile_v <- round(quantile(spotify_1000$speechiness),3)
quantile_v
q_1 <- round(as.numeric(quantile_v[2]),3)
q_3 <- round(as.numeric(quantile_v[4]),3)
iqr_v <- q_3 - q_1
iqr_v
spotify_1000 %>% 
  filter(!(between(speechiness, q_1 - 1.5*iqr_v, q_3 + 1.5*iqr_v))) %>% count()

## Summary statistics of acousticness
spotify_1000 %>% ggplot(aes(x = acousticness)) + geom_histogram() + ylab("Frequency")
skewness(spotify_1000$acousticness)
round(summary(spotify_1000$acousticness),3)
quantile_v <- round(quantile(spotify_1000$acousticness),3)
quantile_v
q_1 <- round(as.numeric(quantile_v[2]),3)
q_3 <- round(as.numeric(quantile_v[4]),3)
iqr_v <- q_3 - q_1
iqr_v
spotify_1000 %>% 
  filter(!(between(acousticness, q_1 - 1.5*iqr_v, q_3 + 1.5*iqr_v))) %>% count()

## Summary statistics of instrumentalness
spotify_1000 %>% ggplot(aes(x = instrumentalness)) + 
  geom_histogram() + ylab("Frequency") # Should log instrumentalness
skewness(spotify_1000$instrumentalness)
round(summary(spotify_1000$instrumentalness),3)
quantile_v <- round(quantile(spotify_1000$instrumentalness),3)
quantile_v
q_1 <- round(as.numeric(quantile_v[2]),3)
q_3 <- round(as.numeric(quantile_v[4]),3)
iqr_v <- q_3 - q_1
iqr_v
spotify_1000 %>% 
  filter(!(between(instrumentalness, q_1 - 1.5*iqr_v, q_3 + 1.5*iqr_v))) %>% count()

## Summary statistics of liveness
spotify_1000 %>% ggplot(aes(x = liveness)) + geom_histogram() + ylab("Frequency")
skewness(spotify_1000$liveness)
round(summary(spotify_1000$liveness),3)
quantile_v <- round(quantile(spotify_1000$liveness),3)
quantile_v
q_1 <- round(as.numeric(quantile_v[2]),3)
q_3 <- round(as.numeric(quantile_v[4]),3)
iqr_v <- q_3 - q_1
iqr_v
spotify_1000 %>% 
  filter(!(between(liveness, q_1 - 1.5*iqr_v, q_3 + 1.5*iqr_v))) %>% count()

## Summary statistics of valence
spotify_1000 %>% ggplot(aes(x = valence)) + geom_histogram() + ylab("Frequency")
skewness(spotify_1000$valence)
round(summary(spotify_1000$valence),3)
quantile_v <- round(quantile(spotify_1000$valence),3)
quantile_v
q_1 <- round(as.numeric(quantile_v[2]),3)
q_3 <- round(as.numeric(quantile_v[4]),3)
iqr_v <- q_3 - q_1
iqr_v
spotify_1000 %>% 
  filter(!(between(valence, q_1 - 1.5*iqr_v, q_3 + 1.5*iqr_v))) %>% count()

## Summary statistics of tempo
spotify_1000 %>% ggplot(aes(x = tempo)) + geom_histogram() + ylab("Frequency")
skewness(spotify_1000$tempo)
round(summary(spotify_1000$tempo),3)
quantile_v <- round(quantile(spotify_1000$tempo),3)
quantile_v
q_1 <- round(as.numeric(quantile_v[2]),3)
q_3 <- round(as.numeric(quantile_v[4]),3)
iqr_v <- q_3 - q_1
iqr_v
spotify_1000 %>% 
  filter(!(between(tempo, q_1 - 1.5*iqr_v, q_3 + 1.5*iqr_v))) %>% count()

## Summary statistics of duration_ms
spotify_1000 %>% ggplot(aes(x = duration_ms)) + geom_histogram() + ylab("Frequency")
skewness(spotify_1000$duration_ms)
round(summary(spotify_1000$duration_ms),3)
quantile_v <- round(quantile(spotify_1000$duration_ms),3)
quantile_v
q_1 <- round(as.numeric(quantile_v[2]),3)
q_3 <- round(as.numeric(quantile_v[4]),3)
iqr_v <- q_3 - q_1
iqr_v
spotify_1000 %>% 
  filter(!(between(duration_ms, q_1 - 1.5*iqr_v, q_3 + 1.5*iqr_v))) %>% count()

## Summary statistics of year_released
spotify_1000 %>% ggplot(aes(x = year_released)) + geom_histogram() + ylab("Frequency")
print(spotify_1000 %>% 
  count(year_released) %>% mutate(prop = round(n*100/sum(n),3)) %>% arrange(desc(prop)), n =70)

# Relationship between predictors and track’s genres
## Relationship between track_popularity and track’s genres
spotify_1000 %>% ggplot(aes(x = fct_reorder(track_genre, track_popularity), y = track_popularity)) + 
  geom_boxplot() + xlab("Track_genre")
spotify_1000 %>% group_by(track_genre) %>% 
  summarise(mean_v = median(track_popularity)) %>% arrange(mean_v)

## Relationship between danceability and track’s genres
spotify_1000 %>% ggplot(aes(x = fct_reorder(track_genre, danceability), y = danceability)) + 
  geom_boxplot() + xlab("Track_genre")
spotify_1000 %>% 
  group_by(track_genre) %>% summarise(mean_v = median(danceability)) %>% arrange(mean_v)

## Relationship between energy and track’s genres
spotify_1000 %>% ggplot(aes(x = fct_reorder(track_genre, energy), y = energy)) + 
  geom_boxplot() + xlab("Track_genre")
spotify_1000 %>% 
  group_by(track_genre) %>% summarise(mean_v = median(energy)) %>% arrange(mean_v)

## Relationship between key and track’s genres
spotify_1000 %>% ggplot(aes(x = fct_reorder(track_genre, key), y = key)) + 
  geom_boxplot() + xlab("Track_genre")
spotify_1000 %>% 
  group_by(track_genre) %>% summarise(mean_v = median(key)) %>% arrange(mean_v)

## Relationship between loudness and track’s genres
spotify_1000 %>% ggplot(aes(x = fct_reorder(track_genre, loudness), y = loudness)) + 
  geom_boxplot() + xlab("Track_genre")
spotify_1000 %>% 
  group_by(track_genre) %>% summarise(mean_v = median(loudness)) %>% arrange(mean_v)

## Relationship between mode and track’s genres
spotify_1000 %>% ggplot(aes(x = track_genre, fill = factor(mode))) + 
  geom_bar() + xlab("Track_genre")

## Relationship between speechiness and track’s genres
spotify_1000 %>% ggplot(aes(x = fct_reorder(track_genre, speechiness), y = speechiness)) + 
  geom_boxplot() + xlab("Track_genre")
spotify_1000 %>% 
  group_by(track_genre) %>% summarise(mean_v = median(speechiness)) %>% arrange(mean_v)

## Relationship between acousticness and track’s genres
spotify_1000 %>% ggplot(aes(x = fct_reorder(track_genre, acousticness), y = acousticness)) + 
  geom_boxplot() + xlab("Track_genre")
spotify_1000 %>% 
  group_by(track_genre) %>% summarise(mean_v = median(acousticness)) %>% arrange(mean_v)

## Relationship between instrumentalness and track’s genres
spotify_1000 %>% ggplot(aes(x = fct_reorder(track_genre, instrumentalness), 
                            y = instrumentalness)) + 
  geom_boxplot() + xlab("Track_genre")
spotify_1000 %>% 
  group_by(track_genre) %>% summarise(mean_v = median(instrumentalness)) %>% arrange(mean_v)

## Relationship between liveness and track’s genres
spotify_1000 %>% ggplot(aes(x = fct_reorder(track_genre, liveness), y = liveness)) + 
  geom_boxplot() + xlab("Track_genre")
spotify_1000 %>% 
  group_by(track_genre) %>% summarise(mean_v = median(liveness)) %>% arrange(mean_v)

## Relationship between valence and track’s genres
spotify_1000 %>% ggplot(aes(x = fct_reorder(track_genre, valence), y = valence)) + 
  geom_boxplot() + xlab("Track_genre")
spotify_1000 %>% 
  group_by(track_genre) %>% summarise(mean_v = median(valence)) %>% arrange(mean_v)

## Relationship between tempo and track’s genres
spotify_1000 %>% ggplot(aes(x = fct_reorder(track_genre, tempo), y = tempo)) + 
  geom_boxplot() + xlab("Track_genre")
spotify_1000 %>% 
  group_by(track_genre) %>% summarise(mean_v = median(tempo)) %>% arrange(mean_v)

## Relationship between duration_ms and track’s genres
spotify_1000 %>% ggplot(aes(x = fct_reorder(track_genre, duration_ms), y = duration_ms)) + 
  geom_boxplot() + xlab("Track_genre")
spotify_1000 %>% 
  group_by(track_genre) %>% summarise(mean_v = median(duration_ms)) %>% arrange(mean_v)

## How does track popularity change over time?
spotify_1000 %>% ggplot(aes(x = factor(year_released), y = track_popularity)) + 
  geom_boxplot() + xlab("Year_released") +
  theme(axis.text.x = element_text(angle =90, hjust = 1, vjust = 0.5))

## Relationship between year_released and track’s genres
spotify_1000 %>% ggplot(aes(x = factor(track_genre), fill = factor(year_released))) + 
  geom_bar(position = "fill", col = "black") + xlab("Track_genre") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1))

## Check proportion of track's genres from 1957 to 1990
spotify_1000 %>% count(track_genre, year_released) %>% 
  filter(between(year_released,1957, 1990)) %>% 
  group_by(track_genre) %>% mutate(total = sum(n)) %>% ungroup() %>% 
  distinct(track_genre, total) %>% mutate(prop = round(total*100/sum(total),3))

## Check proportion of track's genres from 1991 to 2000
spotify_1000 %>% count(track_genre, year_released) %>% 
  filter(between(year_released,1991, 2000)) %>% 
  group_by(track_genre) %>% mutate(total = sum(n)) %>% ungroup() %>% 
  distinct(track_genre, total) %>% mutate(prop = round(total*100/sum(total),3))

## Check proportion of track's genres from 2001 to 2020
spotify_1000 %>% count(track_genre, year_released) %>% 
  filter(between(year_released,2001, 2020)) %>% 
  group_by(track_genre) %>% mutate(total = sum(n)) %>% ungroup() %>% 
  distinct(track_genre, total) %>% mutate(prop = round(total*100/sum(total),3))

## Check proportion of released year in edm tracks
print(spotify_final %>% filter(track_genre == "edm") %>% 
        count(year_released) %>% arrange(desc(year_released)) %>% 
        mutate(prop = n/sum(n), cum_sum = cumsum(prop)), n = 40)

# Check track_genre for each track_artists - check top 10 artists having the highest number of tracks
## Get list of top track artists
spotify_1000_artist_origin %>% count(track_artist) %>% arrange(desc(n)) %>% top_n(10)

## Check proportion of track's genres of Queen
spotify_1000_artist %>% filter(queen==1) %>% count(track_genre) %>% mutate(total = sum(n),prop = round(n*100/total,3)) %>% arrange(desc(n))

## Check proportion of track's genres of Ballin Entertainment
spotify_1000_artist %>% filter(ballin_entertainment==1) %>% count(track_genre) %>% mutate(total = sum(n),prop = round(n*100/total,3)) %>% arrange(desc(n))

## Check proportion of track's genres of Don Omar
spotify_1000_artist %>% filter(don_omar==1) %>% count(track_genre) %>% mutate(total = sum(n),prop = round(n*100/total,3)) %>% arrange(desc(n))

## Check proportion of track's genres of 2Pac
spotify_1000_artist %>% filter(x2pac==1) %>% count(track_genre) %>% mutate(total = sum(n),prop = round(n*100/total,3)) %>% arrange(desc(n))

## Check proportion of track's genres of Martin Garrix
spotify_1000_artist %>% filter(martin_garrix==1) %>% count(track_genre) %>% mutate(total = sum(n),prop = round(n*100/total,3)) %>% arrange(desc(n))

## Check proportion of track's genres of Rihanna
spotify_1000_artist %>% filter(rihanna==1) %>% count(track_genre) %>% mutate(total = sum(n),prop = round(n*100/total,3)) %>% arrange(desc(n))

## Check proportion of track's genres of David Guetta
spotify_1000_artist %>% filter(david_guetta==1) %>% count(track_genre) %>% mutate(total = sum(n),prop = round(n*100/total,3)) %>% arrange(desc(n))

## Check proportion of track's genres of Drake
spotify_1000_artist %>% filter(drake==1) %>% count(track_genre) %>% mutate(total = sum(n),prop = round(n*100/total,3)) %>% arrange(desc(n))

## Check proportion of track's genres of Hardwell
spotify_1000_artist %>% filter(hardwell==1) %>% count(track_genre) %>% mutate(total = sum(n),prop = round(n*100/total,3)) %>% arrange(desc(n))

## Check proportion of track's genres of Logic
spotify_1000_artist %>% filter(logic==1) %>% count(track_genre) %>% mutate(total = sum(n),prop = round(n*100/total,3)) %>% arrange(desc(n))

## Check proportion of track's genres of R3HAb
spotify_1000_artist %>% filter(r3hab==1) %>% count(track_genre) %>% mutate(total = sum(n),prop = round(n*100/total,3)) %>% arrange(desc(n))

## Check proportion of track's genres of The Chainsmokers
spotify_1000_artist %>% filter(the_chainsmokers==1) %>% count(track_genre) %>% mutate(total = sum(n),prop = round(n*100/total,3)) %>% arrange(desc(n))

# BUILDING MODELS
# Split the data set into a training set and a testing set
spotify_split <- initial_split(spotify_1000)
spotify_train <- training(spotify_split)
spotify_test <- testing(spotify_split)

library(themis)
# Create recipe to process, including PCA
recipe_spotify_pca <- recipe(track_genre ~ ., data = spotify_train) %>%
  step_downsample(track_genre) %>%
  step_zv(all_predictors()) %>%
  step_normalize(all_predictors()) %>%
  step_corr(all_predictors()) %>%
  step_pca(all_predictors()) %>%
  prep()

recipe_spotify_pca

# Take variance explained by principle components 
sdev_value <- recipe_spotify_pca$steps[[5]]$res$sdev
ve <- sdev_value^2 / sum(sdev_value^2)

# Find necessary number of principle components to get 90% variance explained
pc_sdev <- tibble(pc = fct_inorder(str_c("PC",1:43)),
                  pve = cumsum(ve))
pc_sdev %>% filter(pve >= 0.9)

library(themis)
# Because PCA does not reduce many predictors, therefore, I decided not to use PCA 
recipe_spotify <- recipe(track_genre ~ ., data = spotify_train) %>%
  step_downsample(track_genre) %>%
  step_zv(all_predictors()) %>%
  step_normalize(all_predictors()) %>%
  step_corr(all_predictors()) %>%
  prep()

recipe_spotify

# Apply recipe on the training set to process training set
pre_spotify_train <- juice(recipe_spotify)
skim(pre_spotify_train)

# Apply recipe on the testing set to process testing set
pre_spotify_test <- bake(recipe_spotify, spotify_test)

# Make cross validation resamples from preprocessed training set
spotify_cv_10 <- vfold_cv(pre_spotify_train, v = 10, strata = track_genre)
spotify_cv_10

# Build a linear discriminant analysis
## Set the model specification
lda_spotify <- discrim_linear(mode = "classification") %>%
  set_engine("MASS")

## Fit the model to cross validation resamples
lda_fit <- fit_resamples(lda_spotify, 
                         preprocessor = recipe(track_genre ~., data = pre_spotify_train),
                         resamples = spotify_cv_10)

## Get average accuracy and average AUC of the model
lda_fit %>% collect_metrics()

# A K-nearest neighbours model
doParallel::registerDoParallel()
## Set model specification
knearest_spotify <- nearest_neighbor(mode = "classification", neighbors = tune()) %>% 
  set_engine("kknn")

## Create a grid containing possible values of neighbors
k_grid <- grid_regular(neighbors(range = c(1, 100)), levels = 20)
k_grid

## Fit the model to cross validation resamples and tune neighbors
knearest_spotify_tune <- tune_grid(knearest_spotify, 
                                   preprocessor = recipe(track_genre ~ . , data = pre_spotify_train),
                                   resamples = spotify_cv_10,
                                   grid = k_grid)

## Get average accuracy and average AUC for each value of neighbor
knearest_spotify_tune %>% collect_metrics()

## Get the value of neighbors which can give the highest accuracy
k_best <- select_best(knearest_spotify_tune, "accuracy")
k_best

## Finalize the model with the best neighbors value
final_knearest <- finalize_model(knearest_spotify, k_best)
final_knearest

## Get average accuracy and average AUC of the best neighbors value
knearest_spotify_tune %>% collect_metrics() %>% filter(neighbors == k_best$neighbors)

# A random forest with 100 trees and 5 levels
## Set model specification
rand_spotify <- rand_forest(mode = "classification", trees = 100, min_n = tune(), mtry = tune()) %>%
  set_engine("ranger", importance = "permutation")

## Create a grid containing possible combinations of mtry and min_n
mtry_tune <- grid_regular(finalize(mtry(), pre_spotify_train %>% dplyr::select(-track_genre)),
                          min_n(),
                          levels = 5)

## Fit the model to cross validation resamples, and tune mtry and min_n
rand_spotify_fit <- tune_grid(rand_spotify,
                              preprocessor = recipe(track_genre ~., data = pre_spotify_train),
                              resamples = spotify_cv_10,
                              grid = mtry_tune)

## Get average accuracy and average AUC for each combination of mtry and min_n
rand_spotify_fit %>% collect_metrics()

## Get the combination of mtry and min_n which can give the highest accuracy
mtry_best <- select_best(rand_spotify_fit, "accuracy")
mtry_best

## Finalize the model with the best combination of mtry and min_n
final_randforest <- finalize_model(rand_spotify, mtry_best)
final_randforest

## Get average accuracy and average AUC of the best combination of mtry and min_n
rand_spotify_fit %>% collect_metrics() %>% filter(mtry == mtry_best$mtry, min_n == mtry_best$min_n)

# Random forest is the best model, compared to other models -> fit random forest model to processed training set
final_randforest_fit <- final_randforest %>% fit(track_genre ~., pre_spotify_train)

# Make class predictions on processed testing set
spotify_pred_class <- predict(final_randforest_fit, pre_spotify_test, type = "class") %>%
  bind_cols(pre_spotify_test)

# Make confusion matrix based on class predictions
spotify_pred_class %>% conf_mat(truth = track_genre, estimate = .pred_class)# %>% kable(caption = "Confusion matrix of track's genres")


# Calculate average sensitivity for track's genres
spotify_pred_class %>% sens(truth = track_genre, estimate = .pred_class, estimator = "macro")

## Calculate sensitivity for edm
spotify_pred_class %>% mutate(track_genre = case_when(track_genre == "edm" ~ 0, TRUE ~ 1),
                              .pred_class = case_when(.pred_class == "edm" ~ 0, TRUE ~ 1),
                              track_genre = factor(track_genre, ordered = T),
                              .pred_class = factor(.pred_class, ordered = T)) %>%
  sens(truth = track_genre, estimate = .pred_class)

## Calculate sensitivity for latin
spotify_pred_class %>% mutate(track_genre = case_when(track_genre == "edm" ~ 0, TRUE ~ 1),
                              .pred_class = case_when(.pred_class == "edm" ~ 0, TRUE ~ 1),
                              track_genre = factor(track_genre, ordered = T),
                              .pred_class = factor(.pred_class, ordered = T)) %>%
  sens(truth = track_genre, estimate = .pred_class)

## Calculate sensitivity for pop
spotify_pred_class %>% mutate(track_genre = case_when(track_genre == "edm" ~ 0, TRUE ~ 1),
                              .pred_class = case_when(.pred_class == "edm" ~ 0, TRUE ~ 1),
                              track_genre = factor(track_genre, ordered = T),
                              .pred_class = factor(.pred_class, ordered = T)) %>%
  sens(truth = track_genre, estimate = .pred_class)

## Calculate sensitivity for r&b
spotify_pred_class %>% mutate(track_genre = case_when(track_genre == "edm" ~ 0, TRUE ~ 1),
                              .pred_class = case_when(.pred_class == "edm" ~ 0, TRUE ~ 1),
                              track_genre = factor(track_genre, ordered = T),
                              .pred_class = factor(.pred_class, ordered = T)) %>%
  sens(truth = track_genre, estimate = .pred_class)

## Calculate sensitivity for rock
spotify_pred_class %>% mutate(track_genre = case_when(track_genre == "edm" ~ 0, TRUE ~ 1),
                              .pred_class = case_when(.pred_class == "edm" ~ 0, TRUE ~ 1),
                              track_genre = factor(track_genre, ordered = T),
                              .pred_class = factor(.pred_class, ordered = T)) %>%
  sens(truth = track_genre, estimate = .pred_class)

## Calculate sensitivity for rap
spotify_pred_class %>% mutate(track_genre = case_when(track_genre == "rap" ~ 1, TRUE ~ 0),
                              .pred_class = case_when(.pred_class == "rap" ~ 1, TRUE ~ 0),
                              track_genre = factor(track_genre, ordered = T),
                              .pred_class = factor(.pred_class, ordered = T)) %>%
  sens(truth = track_genre, estimate = .pred_class)

# Calculate average specificity for track's genres
spotify_pred_class %>% spec(truth = track_genre, estimate = .pred_class, estimator = "macro")

## Calculate specificity for edm
spotify_pred_class %>% mutate(track_genre = case_when(track_genre == "edm" ~ 1, TRUE ~ 0),
                              .pred_class = case_when(.pred_class == "edm" ~ 1, TRUE ~ 0),
                              track_genre = factor(track_genre, ordered = T),
                              .pred_class = factor(.pred_class, ordered = T)) %>%
  spec(truth = track_genre, estimate = .pred_class)

## Calculate specificity for latin
spotify_pred_class %>% mutate(track_genre = case_when(track_genre == "latin" ~ 1, TRUE ~ 0),
                              .pred_class = case_when(.pred_class == "latin" ~ 1, TRUE ~ 0),
                              track_genre = factor(track_genre, ordered = T),
                              .pred_class = factor(.pred_class, ordered = T)) %>%
  spec(truth = track_genre, estimate = .pred_class)

## Calculate specificity for pop
spotify_pred_class %>% mutate(track_genre = case_when(track_genre == "pop" ~ 1, TRUE ~ 0),
                              .pred_class = case_when(.pred_class == "pop" ~ 1, TRUE ~ 0),
                              track_genre = factor(track_genre, ordered = T),
                              .pred_class = factor(.pred_class, ordered = T)) %>%
  spec(truth = track_genre, estimate = .pred_class)

## Calculate specificity for r&b
spotify_pred_class %>% mutate(track_genre = case_when(track_genre == "r&b" ~ 1, TRUE ~ 0),
                              .pred_class = case_when(.pred_class == "r&b" ~ 1, TRUE ~ 0),
                              track_genre = factor(track_genre, ordered = T),
                              .pred_class = factor(.pred_class, ordered = T)) %>%
  spec(truth = track_genre, estimate = .pred_class)

## Calculate specificity for rock
spotify_pred_class %>% mutate(track_genre = case_when(track_genre == "rock" ~ 1, TRUE ~ 0),
                              .pred_class = case_when(.pred_class == "rock" ~ 1, TRUE ~ 0),
                              track_genre = factor(track_genre, ordered = T),
                              .pred_class = factor(.pred_class, ordered = T)) %>%
  spec(truth = track_genre, estimate = .pred_class)

## Calculate specificity for rap
spotify_pred_class %>% mutate(track_genre = case_when(track_genre == "rap" ~ 0, TRUE ~ 1),
                              .pred_class = case_when(.pred_class == "rap" ~ 0, TRUE ~ 1),
                              track_genre = factor(track_genre, ordered = is.ordered(c(1,0))),
                              .pred_class = factor(.pred_class, ordered = is.ordered(c(1,0)))) %>%
  spec(truth = track_genre, estimate = .pred_class)

# Calculate average accuracy for track's genres
spotify_pred_class %>% accuracy(truth = track_genre, estimate = .pred_class)

# Make probability predictions on processed testing set
spotify_pred_prob <- predict(final_randforest_fit, pre_spotify_test, type = "prob") %>% 
  bind_cols(pre_spotify_test)


# Draw roc curves for each track's genre
spotify_pred_prob
spotify_pred_prob %>% roc_curve(truth = track_genre, 1:6) %>% autoplot()


# Calculate average AUC for track's genres
spotify_pred_prob %>% roc_auc(truth = track_genre, 1:6, estimator = "hand_till")
spotify_pred_class %>% group_by(track_genre) %>% sens(truth = track_genre, .pred_class)

# Get variable importance for each predictor
final_randforest_fit %>% vip(num_features = 50)
# %>% kable(caption = "Importance of predictors in predicting track's genres")
---
title: "ModelR: a workflow for ecological niche models based on dismo"
author: "Andrea Sánchez-Tapia"
date: "`r Sys.Date()`"
output: 
    rmarkdown::html_vignette:
        toc: true
vignette: >
  %\VignetteIndexEntry{ModelR: a workflow for ecological niche models based on dismo}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
references:
- id: araujo_ensemble_2007
  title: Ensemble forecasting of species distributions
  author:
  - family: Araújo
    given: Miguel
  - family: New
    given: Mark
  container-title: Trends in Ecology and Evolution
  volume: 22
  URL: 'http://dx.doi.org/10.1016/j.tree.2006.09.010'
  DOI: 10.1016/j.tree.2006.09.010
  issue: 1
  publisher: 
  page: 42-47
  type: article-journal
  issued:
    year: 2007
---

__ModelR__ is a workflow based on package __dismo__, designed to automatize some of the common steps when performing ecological niche models. Given the occurrence records and a set of environmental predictors, it prepares the data by cleaning for duplicates, lack of environmental information and geographic <!--and environmental--> filters, executes crossvalidation, bootstrap or jacknife procedures depending on the number of occurrence points, then it performs ecological niche models using the several algorithms implemented in the `dismo` package.

## Installing 

```
library(devtools)
install_github("Model-R/modelr_pkg", build_vignettes = TRUE)
#install.packages(xxx)#soon!
```

(`build_vignettes` will include this vignette on the installation)

## The workflow

The workflow consists of mainly four functions that should be used sequentially.

0.^\*^ `setup_sdmdata()` prepares and cleans the data, samples the pseudoabsences, and organizes the experimental design (bootstrap, crossvalidation or repeated crossvalidation);  
1. `do_any()` makes the ENM for each partition and partition; optionally, 
`do_enm()` calls `do_any()` to fit multiple algorithms.
2. `final_model()` selects and joins the partition models into a final model per species per algorithm;  
3. `ensemble_model()` joins the final models per algorithm into an ensemble model.  

^\*^ `setup_sdmdata()` can be called apart or it will be called from within `do_any()` or `do_enm()`

# Folder structure created by this package

__ModelR__ writes the outputs in the hard disk, according to the following folder structure:   

    `models_dir/projection1/partitions`  
    `models_dir/projection1/final_models`  
    `models_dir/projection1/ensemble_models`  
    `models_dir/projection2/partitions`  
    `models_dir/projection2/final_models`  
    `models_dir/projection2/ensemble_models`  

+ We define a _partition_ as the individual modeling round that takes part of the data to train the algorithms and the rest of the data to test them. 
+ We define the _final models_ as joining together the partitions and obtaining __one model per species per algorithm__.
+ _Ensemble_ models join together the results obtained by different algorithms [@araujo_ensemble_2007].
+ When projecting models into the present, the projection folder is called `present`.  <!-- [The projection unto other areas and/or climate scenarios is being implemented] --> .
+ You can set `models_dir` wherever you want in the hard disk, but if you do not modify the default value, it will create the output under the working directory (its default value is `./models_dir`, where the period points to the working directory)
+ The _names_ of the `final` and `ensemble` folders can be modified, but __the nested subfolder structure will remain the same__. If you change `final_models` default value (`"final_model"`) you will need to include the new value when calling `ensemble_model()` (`final_dir = "[new name]"`), to indicate the function where to look for models. This partial flexibility allows for experimenting with final model and ensemble construction (by runnning final or ensemble twice in different output folders, for example). 


# Fitting a model per partition

Functions `do_any` and `do_enm()` create a *model per partition, per algorithm*. The available algorithms are bioclim, domain, MaxEnt, mahalanobis distances, as implemented in __dismo__, and support vector machines (SVM), as implemented by packages __kernlab__ (`svm.k`) and __e1071__ (`svm.e`). GLM from base R and Random Forest (from package __randomForest__) are also implemented. Details for the implementation of each model can be accessed in the documentation of the function:

```
?modelr::do_any()
```
<!--escrever os detalhes das implementações --> 

## Setting up the data: `setup_sdmdata()`

__ModelR__ comes with example data, a data frame called `coordenadas`, with 
occurrence data for four species, and predictor variables called 
`variaveis_preditoras`


```{r lib, echo = T}
library(devtools)
load_all()
#library(ModelR)
library(rJava) 
library(raster)
head(coordenadas)
species <- unique(coordenadas$sp)
species
```



```{r dataset, fig.width= 5, fig.height=5, fig.cap= "Figure 1. The example dataset: predictor variables and occurrence for four species."}
raster::plot(variaveis_preditoras[[1]])
points(sp::SpatialPoints(coordenadas[,c(2,3)]),
       bg = as.numeric(unclass(coordenadas$sp)), pch = 21)
```

We will filter the `coordenadas` file to select only the data for the first species: 

```{r occs, message = F}
library(dplyr)
species[1]
occs <- filter(coordenadas, sp == species[1]) %>% select(lon, lat)
head(occs)
```

__The first step of the workflow is to setup the data, that is, to partition it according to each project needs, to sample background pseudoabsences and to apply some data cleaning procedures, as well as some filters__

```{r args_setup_sdmdata}
args(setup_sdmdata)
```

xx <!-- Ö[describe] --> 
`setupsdmdata()` has a large number of parameters: 

    + `partitions`: It implements a k-fold cross-validation (argument `part`, defaults to 3) but overwrites part when n < 10, setting part to the number of occurrence records (a jacknife partition).  
    + `buffer`: can build a distance buffer around the occurrence points, by taking either the maximal, median or mean distance between points. Pseudoabsence points will be sampled (using `dismo::randomPoints()`) within this buffer.
    + `seed`: for reproducilibity purposes 


## Fitting one algorithm: `do_any()`


```{r args_do_any}
args(do_any)
```

`do_any()` performs modeling for each individual algorithm, using parameter `algo`

+ `mask`: will crop and mask the partition models into a ShapeFile


```{r do_any}
do_any(species_name = species[1],
       algo = "bioclim",
       coordinates = occs,
       predictors = variaveis_preditoras,
       models_dir = "~/modelR_test/1species",
       write_png = T,
       bootstrap = F,
       crossvalidation = T,
       cv_partitions = 5,
       cv_n = 1,
       buffer = "mean",
       plot_sdmdata = T,
       n_back = 500)
```

You can explore the list of files created at this phase, for example:

```{r partfiles}
partitions.folder <-
     list.files("~/modelR_test", recursive = T, pattern = "partitions",
                include.dirs = T, full.names = T)
partitions.folder
```

A call to: 

```
list.files(partitions.folder, recursive = T)
```

Should return something like this

```
[1] "bioclim_bin_Eugenia florida DC._1_1.png"     
[2] "bioclim_bin_Eugenia florida DC._1_1.tif"     
[3] "bioclim_cont_Eugenia florida DC._1_1.png"    
[4] "bioclim_cont_Eugenia florida DC._1_1.tif"    
[5] "bioclim_cut_Eugenia florida DC._1_1.png"     
[6] "bioclim_cut_Eugenia florida DC._1_1.tif"     
[7] "evaluate_Eugenia florida DC._1_1_bioclim.txt"
[8] "sdmdata_Eugenia florida DC..png"             
[9] "sdmdata.txt"              
```

At the end of a modeling round, the partition folder containts: 

+ A `.tif` file for each partition, continuous, binary and cut by the threshold that maximizes its TSS.
+ Figures in `.png` to explore the results readily, without reloading them into R or opening them in a SIG program. The creation of these figures can be controlled with the `write_png` parameter. 
+ A `.txt` table with the evaluation data for each partition: `evaluate_[Species name ]_[partition number]_[algorithm].txt`. These files will be read by the `final_model()` function, to generate the final model per species.
+ A file called `sdmdata.txt` with the data used for each partition
+ An optional `.png` image of the data (controlled by parameter `plot_sdmdata = T`)


### Fitting several algorithms per species: `do_enm()`

The previous modeling procedure can be also performed by using `do_enm()`, that receives the same parameters as `do_any()` but allows the user to call __more than one algorithm__ using TRUE or FALSE statements (just as BIOMOD2 functions do). 

`do_enm()` calls several instances of `do_any()`. The following code would perform only bioclim, it is equivalent to `do_any()` + `algo = "bioclim"`

```{r do_enm1, eval = F}
args(do_enm)
do_enm(species_name = species[1],
       coordinates = occs,
       predictors = variaveis_preditoras,
       models_dir = "~/modelR_test/1species",
       bootstrap = F,
       crossvalidation = T,
       cv_partitions = 5,
       cv_n = 1,
       buffer = "mean",
       plot_sdmdata = T,
       write_png = T,
       n_back = 500,
       bioclim = T)
```

The following lines call for bioclim, GLM, maxent (as implemented by __dismo__), random forests (package __randomForest__) and smv.k (from package __kernlab__)

```{r do_enm2}
args(do_enm)
do_enm(species_name = species[1],
       coordinates = occs,
       bootstrap = F,
       crossvalidation = T,
       cv_partitions = 5,
       cv_n = 1,
       buffer = "mean",
       predictors = variaveis_preditoras,
       plot_sdmdata = T,
       models_dir = "~/modelR_test/1species",
       write_png = T,
       n_back = 500,
       bioclim = T,
       glm = T,
       maxent = T,
       rf = T,
       svm.k = T)
```


## Joining partitions: `final_model()`

There are many ways to create a final model per algorithm per species. `final_model()` follows the following logic:

![](final_model_english.png)
![](https://www.flickr.com/gp/ananke/78813X)

+ It can weigh the partitions by a performance metric `weigh.partitions = TRUE` and `weight.par = "spec_sens"`, and give larger weights to partitions with better performance. This results in a continuous, uncut surface. 
+ It can select the best partitions if the parameter `select.partitions = TRUE`, selecting only those who obtained a TSS value above `TSS.value` (TSS varies between -1 and 1, defaults to 0.7). If `select.partitions` is set to FALSE, it will use all the partitions. 
+ The selected partitions form a `raster::rasterStack()` object (step 1 in figure 2). Their mean can be calculated (step 2) and a binary model can be obtained by cutting it by the mean threshold (meanTSSth) that maximizes the individual partition's TSS (step 3: called `final_model_3`). From the means and the threshold, a "cut" model can also be obtained (`final_model_4`).
+ The selected binary models (step 5) can also be joined by a mean (step 7, `final_model_7`) and a binary (step 8) or cut (step 9) model can be obtained through levels of consensus (defaults to 0.5: majority consensus approach).
+ The final models can be done using a subset of the algorithms avaliable on the hard disk, using the parameter `algorithms`. If left unspecified, all algorithms listed in the `evaluate` files will be used.


```{r final_model}
args(final_model)
```


```{r final}
final_model(species_name = species[1],
            select_partitions = F,
            select_par_val = 0.5,
            weight_par = c("TSS"),
            models_dir = "~/modelR_test/1species",
            which_models = c("final_model_7", "final_model_weighted_TSS"))
```

`final_model()` creates a .tif file for each final.model (one per algorithm) under the specified folder (default: `final_models`)
 
We can explore these models from the files:

```{r final_folder}
final.folder <- list.files("~/modelR_test/1species",
                           recursive = T,
                           pattern = "final_models",
                           include.dirs = T,
                           full.names = T)
final.folder
final_mods <- list.files(final.folder, full.names = T, pattern = "tif$")
final_mods
```

```{r plot_final, fig.width = 7, fig.height = 6}
library(raster)
final_models <- stack(final_mods)
plot(final_models)
```

## ensemble_model()

The third step of the workflow is joining the models for each algorithm into a final ensemble model. `ensemble_model()` calculates the mean, standard deviation,minimum and maximum values of the final models and saves them under the folder specified by `ensemble_dir`. It can also create cut these models by a consensus rule (what proportion of final models predict a presence in each pixel, 0.5 is a majority rule, 0.3 would be 30% of the models).

`ensemble_model()` uses a `which.model` parameter to specify which final model (in fig. 2) should be assembled together (the default is
`which.models = c("final_model_3", "final_model_7", "final_model_8")`) referring to step 3, 7 and 8 of the `final_model()` approach.

```{r ensemble_model}
ensemble_model(species[1],
               occs = occs,
               which_models = "final_model_7",
               models_dir = "~/modelR_test/1species/")
```

At any point we can explore the outputs in the folders: 

```{r check_ensemble, fig.width = 5, fig.height = 5}
ensemble_files <-  list.files("~/modelR_test/1species/",
                              recursive = T,
                              pattern = "final_model_7_ensemble.+tif",
                              full.names = T)

ensemble_files
ens_mod <- stack(ensemble_files)
plot(ens_mod)
plot(ens_mod[[2]])
maps::map( , , add = T)
```


# Workflows with multiple species

Our `coordenadas` dataset has data for four species. 
An option to do the several models is to use a `for` loop

```{r, eval = F}
especies <- unique(coordenadas$sp)
for (especie in especies) {
    occs <- coordenadas[coordenadas$sp == especie, c("lon", "lat")]
    do_enm(species_name = especie,
           coordinates = occs,
           bootstrap = F,
           crossvalidation = T,
           cv_partitions = 5,
           cv_n = 1,
           buffer = "mean",
           predictors = variaveis_preditoras,
           models_dir = "~/modelR_test/forlooptest",
           n.back = 500,
           write_png = T,
           bioclim = T,
           maxent = T,
           rf = T,
           svm.k = T)
    }
```

Another option is to use the `purrr` package:

```{r purrr example, eval = F}
library(purrr)
coordenadas %>% split(.$sp) %>%
    purrr::map(~ do_enm(species_name = unique(.$sp),
                        coordinates = .[, c("lon", "lat")],
                        bootstrap = F,
                        crossvalidation = T,
                        cv_partitions = 5,
                        cv_n = 1,
                        buffer = "mean",
                        predictors = variaveis_preditoras,
                        models_dir = "~/modelR_test/temp_purrr",
                        n_back = 500,
                        write_png = T,
                        bioclim = T,
                        maxent = T,
                        rf = T,
                        svm.k = T))
```

```{r purrr_final, eval = F}
coordenadas %>%
    split(.$sp) %>%
    purrr::map(~ final_model(species_name = unique(.$sp),
                             select_partitions = TRUE,
                             select_par = "TSS", 
                             select_par_val = 0.5,
                             consensus_level = 0.5,
                             models_dir = "~/modelR_test/temp_purrr"))
```

```{r purrr_ensemble, eval = F}
coordenadas %>% 
    split(.$sp) %>%
    purrr::map(~ ensemble_model(
        species_name = unique(.$sp),
        occs = .[, c("lon", "lat")],
        which_models = "final_model_7",
        write_png = T,
        models_dir = "~/modelR_test/temp_purrr"
        ))

```


# References

# NEWS
## 2018-05-11
+ Nova implementações: 
    +   Distância euclidiana, `centroid` e `minimum` -Preciso documentar bem os dois algoritmos ainda. 
    + O filtro geográfico `geo_filt()`, escrito por Diogo
    + Limpeza de NAs e duplicados nas ocorrências
    + Posibilidade de incluir ausências próprias 
    + `final_model()` pode executar todos os modelos, e um parâmetro `which_models` permite escolher o output
    + `ensemble()` gera min, max, sd, median e mean.
    + Faltar testar algumas funções

## 2018-04-20
+ sdmdata ficou separado da geração do modelo. agora quando cada algoritmo vai começar simplesmente procura o sdmdata.txt, se já tem ele não o gera de novo. 
+ sdmdata pode criar uma tabela com o desneho experimental para bootstrap (n repetições de um sampling proporcional), k-fold crosvalidação (separa o data set em k grupos) e crosvalidação repetida (faz cv varias vezes)
+ como agora tem runs rodadas, os arquivos são escritos acorde com isto

+ Implementei uma única função de modelagem, `do_any`com um parâmetro `algo` que seleciona entre as opções, mas chama `sdmdata` uma vez só. 

        setupsdmdata
        #seleção
        if algo == (...) {
          bc <- dismo::bioclim(predictors, pres_train)
          bc <- dismo::maxent(predictors, pres_train)
          bc <- dismo::mahal(predictors, pres_train)
          bc <- dismo::domain(predictors, pres_train)
          bc <- dismo::domain(predictors, pres_train)
        }
        
        avaliação, threshold etc...
        returns(th_table)

Isto requer de um tratamento especial para glm, rf e svm pois eles não vêm de um chamado direto a `dismo`, mas a avaliação com `evaluate()` é igual


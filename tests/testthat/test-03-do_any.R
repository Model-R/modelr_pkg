context("basic do_any test")

# objects to be used on tests
my_dir <- "../tmp_test/"
sp <- names(example_occs)[1]
part <- 4
algo <- c("bioclim")
mod_dir <- paste0(my_dir, sp, "/present/partitions/")

test_that("do_any produces model and stats file", {
  my_mod <- do_any(species_name = sp,
                   predictors = example_vars,
                   models_dir = my_dir,
                   algo = algo)
  # does it have two csv files (matrix and evaluate) ?
  expect_length(list.files(path = mod_dir,
                           pattern = "evaluate.*csv"),
                part)
  expect_length(list.files(path = mod_dir,
                           pattern = "eval_mod.*csv"),
                part)
  # does it have tif file (model)?
   expect_length(list.files(path = mod_dir,
                            pattern = paste0(algo, ".*.tif")),
                 part)

})


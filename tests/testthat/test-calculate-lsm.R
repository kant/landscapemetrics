context("calculate_lsm")

test_that("calculate_lsm can calculate patch metrics", {

    patch_metrics <- calculate_lsm(landscape, what = "patch",
                                   verbose = FALSE)

    expect_is(patch_metrics, "tbl_df")
    expect_true(all(patch_metrics$level == "patch"))
    expect_true(ncol(patch_metrics) > 0)
})

test_that("calculate_lsm can calculate class metrics", {

    class_metrics <- calculate_lsm(landscape, what = "class",
                                   verbose = FALSE)

    expect_is(class_metrics, "tbl_df")
    expect_true(all(class_metrics$level == "class"))
    expect_true(ncol(class_metrics) > 0)
})

test_that("calculate_lsm can calculate landscape metrics", {

    landscape_metrics <- calculate_lsm(landscape, what = "landscape",
                                       verbose = FALSE)

    expect_is(landscape_metrics, "tbl_df")
    expect_true(all(landscape_metrics$level == "landscape"))
    expect_true(ncol(landscape_metrics) > 0)
})

test_that("calculate_lsm can take all metrics", {

    all_metrics <- calculate_lsm(landscape,
                                 verbose = FALSE)

    expect_true(all(all_metrics$level %in% c("patch", "class","landscape")))
    expect_is(all_metrics, "tbl_df")
    expect_true(ncol(all_metrics) > 0)
})

test_that("calculate_lsm can take specific metrics", {

    specific_metrics <- calculate_lsm(landscape,
                                      what = c("lsm_p_enn", "lsm_c_ed"),
                                      verbose = FALSE)

    expect_true(all(specific_metrics$metric %in% c("ed", "enn")))
    expect_is(specific_metrics, "tbl_df")
    expect_true(ncol(specific_metrics) > 0)
})

test_that("calculate_lsm can take level argument", {

    specific_metrics_patch <- calculate_lsm(landscape,
                                            level = "patch",
                                            verbose = FALSE)

    specific_metrics_class <- calculate_lsm(landscape,
                                            level = "class",
                                            verbose = FALSE)

    specific_metrics_landscape <- calculate_lsm(landscape,
                                                level = "landscape",
                                                verbose = FALSE)

    expect_true(all(specific_metrics_patch$level == "patch"))
    expect_true(all(specific_metrics_class$level == "class"))
    expect_true(all(specific_metrics_landscape$level == "landscape"))
})


test_that("calculate_lsm can take metric argument", {

    specific_metrics_area <- calculate_lsm(landscape,
                                           metric = "area",
                                           verbose = FALSE)

    metrics <- vapply(strsplit(specific_metrics_area$metric,
                               split = "_"), FUN = function(x) x[1],
                      FUN.VALUE = character(1))

    expect_true(all(metrics == "area"))
})

test_that("calculate_lsm can take name argument", {

    specific_metrics_name <- calculate_lsm(landscape, name = "core area",
                                           verbose = FALSE)

    metrics <- vapply(strsplit(specific_metrics_name$metric,
                               split = "_"), FUN = function(x) x[1],
                      FUN.VALUE = character(1))

    expect_true(all(metrics == "core"))
})

test_that("calculate_lsm can take type argument", {

    specific_metrics_type <- calculate_lsm(landscape,
                                           type = "aggregation metric",
                                           full_name = TRUE,
                                           verbose = FALSE)

    expect_true(all(specific_metrics_type$type == "aggregation metric"))
})

test_that("calculate_lsm can take different raster inputs", {

    expect_is(calculate_lsm(landscape, what = "lsm_l_ta",
                            verbose = FALSE), "tbl_df")
    expect_is(calculate_lsm(landscape_stack, what = "lsm_l_ta",
                            verbose = FALSE), "tbl_df")
    expect_is(calculate_lsm(landscape_brick, what = "lsm_l_ta",
                            verbose = FALSE), "tbl_df")
    expect_is(calculate_lsm(landscape_list, what = "lsm_l_ta",
                            verbose = FALSE), "tbl_df")
})

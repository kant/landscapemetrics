#' sample_lsm
#'
#' @description Sample metrics
#'
#' @param landscape Raster* Layer, Stack, Brick or a list of rasterLayers.
#' @param y 2-column matrix with coordinates, SpatialPoints, SpatialLines, SpatialPolygons of sf points.
#' @param plot_id Vector with id of sample points. If not provided, sample
#' points will be labelled 1...n.
#' @param shape String specifying plot shape. Either "circle" or "square"
#' @param size Approximated size of sample plot. Equals the radius for circles or half of
#' the side-length for squares in mapunits. For lines size equals the width of the buffer.
#' @param return_raster Logical if the clipped raster of the sample plot should
#' be returned
#' @param verbose Print warning messages.
#' @param progress Print progress report.
#' @param ... Arguments passed on to \code{calculate_lsm()}.
#'
#' @details
#' This function samples the selected metrics in a buffer area (sample plot)
#' around sample points, sample lines or within provided SpatialPolygons. The size of the actual
#' sampled landscape can be different to the provided size due to two reasons.
#' Firstly, because clipping raster cells using a circle or a sample plot not directly
#' at a cell center lead to inaccuracies. Secondly, sample plots can exceed the
#' landscape boundary. Therefore, we report the actual clipped sample plot area relative
#' in relation to the theoretical, maximum sample plot area e.g. a sample plot only half
#' within the landscape will have a `percentage_inside = 50`. Please be aware that the
#' output is sligthly different to all other `lsm`-function of `landscapemetrics`.
#'
#' The metrics can be specified by the arguments `what`, `level`, `metric`, `name`
#' and/or `type` (combinations of different arguments are possible (e.g.
#' `level = "class", type = "aggregation metric"`). If an argument is not provided,
#' automatically all possibilities are selected. Therefore, to get **all**
#' available metrics, don't specify any of the above arguments.
#'
#' @seealso
#' \code{\link{list_lsm}} \cr
#' \code{\link{calculate_lsm}}
#'
#' @return tibble
#'
#' @examples
#' # use a matrix
#' sample_points <- matrix(c(10, 5, 25, 15, 5, 25), ncol = 2, byrow = TRUE)
#' sample_lsm(landscape, y = sample_points, size = 15, what = "lsm_l_np")
#'
#' # use sp points
#' points_sp <- sp::SpatialPoints(sample_points)
#' sample_lsm(landscape, y = points_sp, size = 15, what = "lsm_l_np", return_raster = TRUE)
#'
#' \dontrun{
#' # use lines (works only if rgeos is installed)
#' x1 <- c(1, 5, 15, 10)
#' y1 <- c(1, 5, 15, 25)
#'
#' x2 <- c(10, 25)
#' y2 <- c(5, 5)
#'
#' sample_lines <- sp::SpatialLines(list(sp::Lines(list(sp::Line(cbind(x1, y1)),
#' sp::Line(cbind(x2, y2))), ID = "a")))
#' sample_lsm(landscape, y = sample_lines, size = 10, what = "lsm_l_np")
#'
#' # use polygons
#' poly_1 <-  sp::Polygon(cbind(c(2.5, 2.5, 17.5, 17.5),
#'                            c(-2.5, 12.5, 12.5, -2.5)))
#' poly_2 <-  sp::Polygon(cbind(c(7.5, 7.5, 23.5, 23.5),
#'                            c(-7.5, 23.5, 23.5, -7.5)))
#' poly_1 <- sp::Polygons(list(poly_1), "p1")
#' poly_2 <- sp::Polygons(list(poly_2), "p2")
#' sample_plots <- sp::SpatialPolygons(list(poly_1, poly_2))
#'
#' sample_lsm(landscape, y = sample_plots, what = "lsm_l_np", size = 5)
#' }
#'
#' @aliases sample_lsm
#' @rdname sample_lsm
#'
#' @export
sample_lsm <- function(landscape,
                       y,
                       plot_id,
                       shape, size,
                       return_raster,
                       verbose,
                       progress,
                       ...) UseMethod("sample_lsm")

#' @name sample_lsm
#' @export
sample_lsm.RasterLayer <- function(landscape,
                                   y,
                                   plot_id = NULL,
                                   shape = "square", size,
                                   return_raster = FALSE,
                                   verbose = TRUE,
                                   progress = FALSE,
                                   ...) {

    result <- lapply(X = raster::as.list(landscape),
                     FUN = sample_lsm_int,
                     y = y,
                     plot_id = plot_id,
                     shape = shape, size = size,
                     verbose = verbose,
                     progress = progress,
                     ...)

    layer <- rep(seq_len(length(result)),
                 vapply(result, nrow, FUN.VALUE = integer(1)))

    result <- do.call(rbind, result)

    result$layer <- layer

    if (!return_raster) {
        result  <- result[, -9]
    }

    result[with(result, order(layer, plot_id, level, metric, class, id)), ]
}

#' @name sample_lsm
#' @export
sample_lsm.RasterStack <- function(landscape,
                                   y,
                                   plot_id = NULL,
                                   shape = "square", size,
                                   return_raster = FALSE,
                                   verbose = TRUE,
                                   progress = FALSE,
                                   ...) {

    landscape <- raster::as.list(landscape)

    result <- lapply(X = seq_along(landscape), FUN = function(x) {

        if (progress) {

            message("\r> Progress nlayers: ", x , "/", length(landscape),
                    appendLF = FALSE)
        }

        sample_lsm_int(landscape = landscape[[x]],
                       y = y,
                       plot_id = plot_id,
                       shape = shape,
                       size = size,
                       verbose = verbose,
                       progress = FALSE,
                       ...)
    })

    layer <- rep(seq_along(result),
                 vapply(result, nrow, FUN.VALUE = integer(1)))

    result <- do.call(rbind, result)

    result$layer <- layer

    if (!return_raster) {
        result  <- result[, -9]
    }

    if (progress) {message("")}

    result[with(result, order(layer, plot_id, level, metric, class, id)), ]
}

#' @name sample_lsm
#' @export
sample_lsm.RasterBrick <- function(landscape,
                                   y,
                                   plot_id = NULL,
                                   shape = "square", size,
                                   return_raster = FALSE,
                                   verbose = TRUE,
                                   progress = FALSE,
                                   ...) {

    landscape <- raster::as.list(landscape)

    result <- lapply(X = seq_along(landscape), FUN = function(x) {

        if (progress) {

            message("\r> Progress nlayers: ", x , "/", length(landscape),
                    appendLF = FALSE)
        }

        sample_lsm_int(landscape = landscape[[x]],
                       y = y,
                       plot_id = plot_id,
                       shape = shape,
                       size = size,
                       verbose = verbose,
                       progress = FALSE,
                       ...)
    })

    layer <- rep(seq_along(result),
                 vapply(result, nrow, FUN.VALUE = integer(1)))

    result <- do.call(rbind, result)

    result$layer <- layer

    if (!return_raster) {
        result  <- result[, -9]
    }

    if (progress) {message("")}

    result[with(result, order(layer, plot_id, level, metric, class, id)), ]
}

#' @name sample_lsm
#' @export
sample_lsm.stars <- function(landscape,
                             y,
                             plot_id = NULL,
                             shape = "square", size,
                             return_raster = FALSE,
                             verbose = TRUE,
                             progress = FALSE,
                             ...) {

    landscape <-  raster::as.list(methods::as(landscape, "Raster"))

    result <- lapply(X = seq_along(landscape), FUN = function(x) {

        if (progress) {

            message("\r> Progress nlayers: ", x , "/", length(landscape),
                    appendLF = FALSE)
        }

        sample_lsm_int(landscape = landscape[[x]],
                       y = y,
                       plot_id = plot_id,
                       shape = shape,
                       size = size,
                       verbose = verbose,
                       progress = FALSE,
                       ...)
    })

    layer <- rep(seq_along(result),
                 vapply(result, nrow, FUN.VALUE = integer(1)))

    result <- do.call(rbind, result)

    result$layer <- layer

    if (!return_raster) {
        result  <- result[, -9]
    }

    if (progress) {message("")}

    result[with(result, order(layer, plot_id, level, metric, class, id)), ]
}

#' @name sample_lsm
#' @export
sample_lsm.list <- function(landscape,
                            y,
                            plot_id = NULL,
                            shape = "square", size,
                            return_raster = FALSE,
                            verbose = TRUE,
                            progress = FALSE,
                            ...) {

    result <- lapply(X = seq_along(landscape), FUN = function(x) {

        if (progress) {

            message("\r> Progress nlayers: ", x , "/", length(landscape),
                    appendLF = FALSE)
        }

        sample_lsm_int(landscape = landscape[[x]],
                       y = y,
                       plot_id = plot_id,
                       shape = shape,
                       size = size,
                       verbose = verbose,
                       progress = FALSE,
                       ...)
    })

    layer <- rep(seq_along(result),
                 vapply(result, nrow, FUN.VALUE = integer(1)))

    result <- do.call(rbind, result)

    result$layer <- layer

    if (!return_raster) {
        result  <- result[, -9]
    }

    if (progress) {message("")}

    result[with(result, order(layer, plot_id, level, metric, class, id)), ]
}

sample_lsm_int <- function(landscape,
                           y,
                           plot_id,
                           shape, size,
                           verbose,
                           progress,
                           ...) {

    # use polygon
    if (methods::is(y, "SpatialPolygons") | methods::is(y, "SpatialPolygonsDataFrame")) {

        # convert to SpatialPolygons
        if (methods::is(y, "SpatialPolygonsDataFrame")) {

            y <- sp::SpatialPolygons(y@polygons)
        }

        # disaggregate if rgeos is installed
        if (nzchar(system.file(package = "rgeos"))) {

            y <- sp::disaggregate(y)
        }

        # warning that rgeos is not installed
        else {

            if (verbose) {

                warning("Package 'rgeos' not installed. Please make sure polygons are disaggregated.",
                        call. = FALSE)
            }
        }

        # how many plots are present
        # number_plots <- length(y)
    }

    else {

        # check if size argument is only one number
        if (length(size) != 1 | any(size <= 0)) {
            stop("Please provide only one value as size argument (size > 0).", call. = FALSE)
        }

        # use points
        if (methods::is(y, "SpatialPoints") | methods::is(y, "SpatialPointsDataFrame") | methods::is(y, "matrix")) {

            # points are matrix
            if (methods::is(y, "matrix")) {

                if (ncol(y) != 2 & verbose) {
                    warning("'y' should be a two column matrix including x- and y-coordinates.",
                            call. = FALSE)
                }
            }

            # construct plot area around sample sample_points
            y <- construct_buffer(coords = y,
                                  shape = shape,
                                  size = size,
                                  verbose = verbose)
        }

        # check if sf object is provided
        else if (methods::is(y, "sf")) {

            # check if points have the right class
            if (any(class(y) %in% c("MULTIPOINT", "POINT"))) {

                y <- matrix(sf::st_coordinates(y)[, 1:2], ncol = 2)
            }

            else if (any(class(y) %in% c("sf", "sfc"))) {

                if (all(sf::st_geometry_type(y) %in% c("POINT", "MULTIPOINT"))) {

                    y <- matrix(sf::st_coordinates(y)[, 1:2], ncol = 2)
                }

                else {

                    stop(
                        "landscapemetrics currently only supports sf point features for landscape metrics sampling"
                    )
                }
            }

            else if (any(class(y) %in% c("LINESTRING", "POLYGON", "MULTILINESTRING", "MULTIPOLYGON"))) {

                stop(
                    "landscapemetrics currently only supports sf point features for landscape metrics sampling"
                )
            }

            # construct plot area around sample sample_points
            y <- construct_buffer(coords = y,
                                  shape = shape,
                                  size = size,
                                  verbose = verbose)
        }

        # use lines
        else if (methods::is(y, "SpatialLines") | methods::is(y, "SpatialLinesDataFrame")) {

            # convert to SpatialLines
            if (methods::is(y, "SpatialLinesDataFrame")) {

                y <- sp::SpatialLines(y@lines)
            }

            # check if rgeos is installed
            if (nzchar(system.file(package = "rgeos"))) {

                # disaggregate lines
                y <- sp::disaggregate(y)

                # create buffer around lines
                y <- raster::buffer(x = y,
                                    width = size, dissolve = FALSE)
            }

            else {
                stop("To sample landscape metrics in buffers around lines, the package 'rgeos' must be installed.",
                     call. = FALSE)
            }
        }

        else {

            stop("'y' must be a matrix, SpatialPoints, SpatialLines, SpatialPolygons, POINT or MULTIPOINT.",
                 call. = FALSE)
        }
    }

    # check if length is identical if ids are provided
    if (!is.null(plot_id)) {

        if (length(plot_id) != length(y)) {

            if (verbose) {
                warning("Length of plot_id is not identical to length of y. Using 1...n as plot_id.",
                        call. = FALSE)
            }

            plot_id <- NULL
        }
    }

    # get area of all polygons
    maximum_area <- vapply(y@polygons, function(x) x@area / 10000,
                           FUN.VALUE = numeric(1))

    number_plots <- length(maximum_area)

    # loop through each sample point and calculate metrics
    result <- do.call(rbind, lapply(X = seq_along(y), FUN = function(current_plot) {

        # print progess using the non-internal name
        if (progress) {

            message("\r> Progress sample plots: ", current_plot, "/",
                    number_plots, appendLF = FALSE)
        }

        # crop sample plot
        landscape_crop <- raster::crop(x = landscape,
                                       y = y[current_plot])

        # mask sample plot
        landscape_mask <- raster::mask(x = landscape_crop,
                                       mask = y[current_plot])

        # calculate actual area of sample plot
        area <- lsm_l_ta_calc(landscape_mask,
                              directions = 8)

        # calculate lsm
        result_current_plot <- calculate_lsm(landscape = landscape_mask,
                                             verbose = verbose,
                                             progress = FALSE,
                                             ...)

        # add plot id 1...n
        if (is.null(plot_id)) {
            result_current_plot$plot_id <- current_plot
        }

        # add plot_id
        else {
            result_current_plot$plot_id <- plot_id[current_plot]
        }

        # calculate ratio between actual area and theoretical area
        result_current_plot$percentage_inside <- area$value / maximum_area[[current_plot]] * 100

        # add sample plot raster
        result_current_plot$raster_sample_plots <- raster::as.list(landscape_mask)

        return(result_current_plot)
    })
    )

    if (progress) {

        message("")
    }

    # return warning of only 3/4 of sample plot are in landscape
    if (verbose) {
        if (any(result$percentage_inside < 90)) {

            warning("Some of buffers extend over the landscape border. Consider decreasing the size argument value.",
                    call. = FALSE)
        }
    }

    return(result)
}

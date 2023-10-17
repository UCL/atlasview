# ---- GLOBALS ----

cooccurring_diseases_per_specialty <- 5

cooccurring_diseases_sector_bg_col <- "#ECECEC"
sector_grid_lines_col <- "#BFBFBF"
    

#' Make circos plot for a given index disease
#' 
#' @param atlasview_data list of atlasview data, typically from [`get_atlasview_data()`]
#'
#' @param selected_index_disease character string, the selected index disease as code
#' @param svg_filepath optional filepath. If provided, the plot will be written to the path.
#'
#' @importFrom graphics text
#' @importFrom grDevices adjustcolor dev.off
#' @importFrom utils head
circos_plot <- function(atlasview_data, selected_index_disease, svg_filepath = NULL) {
  specialty_codes <- atlasview_data$specialties
  selected_disease <- get_cooccurring_diseases(atlasview_data$MM_res, selected_index_disease)
  patient_count <- get_patient_count(atlasview_data$n_dis_spe, selected_index_disease)
  
  if (!is.null(svg_filepath)) {
    svglite::svglite(svg_filepath, width = 15, height = 15)
  }
  
  ## Globals
  cooccurring_diseases_per_specialty <- 5


  circos.clear()
  circos.par(track.height = 0.25, start.degree = (90 - 4.5), gap.after = 0.2, cell.padding = c(0, 0))
  circos_initialize_sectors(specialty_codes, cooccurring_diseases_per_specialty)

  # track for the long-names of co-occurring disease
  circos.track(
    ylim = c(0, 1), bg.border = NA, track.height = .28, track.margin = c(.01, 0),
    panel.fun = function(x, y) {
      # does this specialty sector have any co-occurring diseases?
      matches <- selected_disease[selected_disease$cooccurring_specialty_code == CELL_META$sector.index, ]
      if (nrow(matches) > 0) {
        matches <- head(matches, cooccurring_diseases_per_specialty)
        circos.text(
          x = (1:cooccurring_diseases_per_specialty - 0.5)[0:nrow(matches)],
          y = 0,
          labels = matches$phenotype_cooccurring_dis,
          facing = "clockwise", niceFacing = T, cex = 0.65, adj = c(0, .5)
        )
      }
    }
  )

  # track for short-names of specialty for each sector
  circos.track(
    ylim = c(0, 0.1), track.height = 0.05, bg.border = NA, track.margin = c(.01, 0),
    panel.fun = function(x, y) {
      # if we have co-occurring diseases for this specialty
      if (CELL_META$sector.index %in% selected_disease$cooccurring_specialty_code) {
        textcolor <- "black"

        matches <- selected_disease[selected_disease$cooccurring_specialty_code == CELL_META$sector.index, ]
        matches <- head(matches, cooccurring_diseases_per_specialty)
        for (i in 1:nrow(matches)) {
          circos.segments((1:nrow(matches)) - 0.5, -0.05, (1:nrow(matches)) - 0.5, 0.11)
        }
        draw.sector(
          get.cell.meta.data("cell.start.degree", sector.index = CELL_META$sector.index),
          get.cell.meta.data("cell.end.degree", sector.index = CELL_META$sector.index),
          rou1 = get.cell.meta.data("cell.top.radius", track.index = 2),
          rou2 = get.cell.meta.data("cell.bottom.radius", track.index = 2),
          col = specialty_codes$color[specialty_codes$code == CELL_META$sector.index], border = NA
        )
      } else {
        # otherwise, no diseases for this specialty
        textcolor <- "darkgray"
      }

      circos.text(CELL_META$xcenter, 0.05, CELL_META$sector.index, cex = 0.8, col = textcolor)
    }
  )


  # track for prevalence ratio
  # no native support for log scale - do it by hand

  # plot track grid lines (aka circles)
  prevalence_ratio_breaks <- log(c(1, 5, 10, 50, 100, 500, 1000, 10000))

  circos.track(
    ylim = c(log(1), log(10000)), bg.col = NA, bg.border = NA, track.margin = c(0, 0),
    panel.fun = function(x, y) {
      matches <- selected_disease[selected_disease$cooccurring_specialty_code == CELL_META$sector.index, ]
      if (nrow(matches) > 0) {
        circos.rect(CELL_META$cell.xlim[1], CELL_META$cell.ylim[1],
          CELL_META$cell.xlim[2], CELL_META$cell.ylim[2],
          col = cooccurring_diseases_sector_bg_col, border = NA
        )
        for (r in head(prevalence_ratio_breaks, -1)) {
          circos.segments(0, r, cooccurring_diseases_per_specialty, r, col = sector_grid_lines_col)
        }
        matches <- head(matches, cooccurring_diseases_per_specialty)
        value <- log(matches$prev_ratio)
        # circos.barplot doesn't plot on log-scale. draw rectangles instead
        xstart <- 0
        for (v in value) {
          truncate <- FALSE
          if (v > log(1000)) {
            truncate <- TRUE
            original_v <- v
            v <- log(1400)
          }
          circos.rect(xstart, log(1), xstart + 1, v, col = specialty_codes$color[specialty_codes$code == CELL_META$sector.index])
          circos.segments(xstart + 0.5, v, xstart + 0.5, log(10000), straight = TRUE, lwd = 1, lty = "dashed", col = sector_grid_lines_col)
          if (truncate) {
            circos.text(xstart + 0.5, v, "=", facing = "clockwise", niceFacing = TRUE) # can't plot unicode characters...?
          }
          if (truncate) {
            circos.text(xstart + 0.5, v + 0.3, round(exp(original_v), 1), facing = "clockwise", niceFacing = TRUE, adj = c(0, 0.5), cex = 0.5)
          } else {
            circos.text(xstart + 0.5, v + 0.2, round(exp(v), 2), facing = "clockwise", niceFacing = TRUE, adj = c(0, 0.5), cex = 0.5)
          }

          xstart <- xstart + 1
        }
      } else {
        for (r in head(prevalence_ratio_breaks, -1)) {
          circos.segments(0, r, cooccurring_diseases_per_specialty, r, col = sector_grid_lines_col)
        }
      }
    }
  )

  # track for prevalence
  prevalence_breaks <- log(c(1, 5, 10, 50, 100))
  circos.track(
    ylim = c(log(100), log(1)), bg.col = NA, bg.border = NA, track.margin = c(0, 0),
    panel.fun = function(x, y) {
      # does this specialty sector have any co-occurring diseases?
      matches <- selected_disease[selected_disease$cooccurring_specialty_code == CELL_META$sector.index, ]
      if (nrow(matches) > 0) {
        circos.rect(CELL_META$cell.xlim[1], CELL_META$cell.ylim[1],
          CELL_META$cell.xlim[2], CELL_META$cell.ylim[2],
          col = cooccurring_diseases_sector_bg_col, border = NA
        )
        for (r in prevalence_breaks) {
          circos.segments(0, r, cooccurring_diseases_per_specialty, r, col = sector_grid_lines_col)
        }
        sectorcolor <- specialty_codes$color[specialty_codes$code == CELL_META$sector.index]
        # make transparent
        sectorcolor <- adjustcolor(sectorcolor, alpha.f = 0.2)
        matches <- head(matches, cooccurring_diseases_per_specialty)
        value <- log(matches$prevalence)
        xstart <- 0
        for (v in value) {
          circos.rect(xstart, log(1), xstart + 1, v, col = sectorcolor, border = adjustcolor("black", alpha.f = 0.2))
          xstart <- xstart + 1
        }
      } else {
        for (r in prevalence_breaks) {
          circos.segments(0, r, cooccurring_diseases_per_specialty, r, col = sector_grid_lines_col)
        }
      }
    }
  )

  circos.text(x = 2.5, y = prevalence_ratio_breaks, track.index = 3, sector.index = " ", labels = c("1", "5", "10", "50", "100", "500", "1000"), adj = c(0, 0.5), cex = 0.65)
  circos.text(x = 1, y = 3.5, "Standardised prevalence ratio", facing = "clockwise", track.index = 3, sector.index = " ", cex = 0.65)

  circos.text(x = 2.5, y = prevalence_breaks, track.index = 4, sector.index = " ", labels = c("1", "5", "10", "50", "100"), adj = c(0, 0.5), cex = 0.65)
  circos.text(x = 1, y = 2.25, "Prevalence (%)", facing = "reverse.clockwise", track.index = 4, sector.index = " ", cex = 0.65)

  # disease name in center of circle
  disease_name <- stringr::str_wrap(selected_disease$phenotype_index_dis[1], width = 20)
  disease_name <- paste0(disease_name, "\n", "(n=", patient_count, " patients)")
  text(0, 0, disease_name)

  if (!is.null(svg_filepath)) {
    dev.off()
  }
}

circos_initialize_sectors <- function(specialty_codes, cooccurring_diseases_per_specialty) {
  # prepare the sectors
  spec_codes_merged_sectors <- as.data.frame(specialty_codes)
  spec_codes_merged_sectors$xlim1 <- 0
  spec_codes_merged_sectors$xlim2 <- cooccurring_diseases_per_specialty
  spec_codes_merged_sectors <- rbind(spec_codes_merged_sectors, c("_LABELS_", " ", " ", 0, 5))

  circos.initialize(spec_codes_merged_sectors$code, xlim = c(0, cooccurring_diseases_per_specialty))
}


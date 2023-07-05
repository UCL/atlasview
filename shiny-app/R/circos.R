# ---- LIBRARIES ----
library(circlize)
library(readr)
library(stringr)
library(svglite)


# ---- GLOBALS ----
speciality_colours <- c(
  '#a9a9a9', '#2f4f4f', '#556b2f', '#a0522d', '#7f0000', '#006400', '#808000', 
           '#483d8b', '#3cb371', '#4682b4', '#808080', '#9acd32', '#20b2aa', '#32cd32', 
           '#daa520', '#7f007f', '#b03060', '#ff0000', '#ff8c00', '#ffd700', '#f4a460', 
           '#00ff00', '#00fa9a', '#dc143c', '#00ffff', '#00bfff', '#9370db', '#a020f0', 
           '#f08080', '#adff2f', '#ff7f50', '#ff00ff', '#1e90ff', '#f0e68c', '#dda0dd', 
           '#afeeee', '#ee82ee', '#ff69b4', '#ffe4c4', '#ffc0cb')
           
cooccurring_diseases_per_speciality <- 5

cooccurring_diseases_sector_bg_col <- "#ECECEC"
sector_grid_lines_col <- "#BFBFBF"
    
# ---- FUNCTIONS ----
# get the data for a specific disease using the phecode
get_cooccurring_diseases <- function(all_diseases, phecode_index_dis) {
  selected_disease <- all_diseases[all_diseases$phecode_index_dis == phecode_index_dis, ]
  # order cooccurring diseases by descending prevalence ratio
  selected_disease <- selected_disease[order(selected_disease$prev_ratio, decreasing = T), ]
  selected_disease
}


# plot figure for a given disease
make_plot <- function(selected_disease, to_svg=FALSE) {
  # prepare the sectors
  spec_codes_merged_sectors <- spec_codes_merged
  spec_codes_merged_sectors$xlim1 <- 0
  spec_codes_merged_sectors$xlim2 <- cooccurring_diseases_per_speciality
  spec_codes_merged_sectors <- rbind(spec_codes_merged_sectors, c('_LABELS_', ' ', 0, 5))
  
  if (to_svg) {
    svglite(paste0('plot_', selected_disease$phecode_index_dis[1], '.svg'), width = 15, height = 15)
  }
  
  circos.clear()
  circos.par(track.height=0.25, start.degree=(90-4.5), gap.after=0.2, cell.padding=c(0,0))
  circos.initialize(spec_codes_merged_sectors$code, xlim = c(0, cooccurring_diseases_per_speciality))
  
  # track for the long-names of co-occurring disease
  circos.track(ylim=c(0,1), bg.border=NA, track.height=.28, track.margin=c(.01,0), 
               panel.fun=function(x,y) {
                 # does this speciality sector have any co-occurring diseases?
                 matches <- selected_disease[selected_disease$code == CELL_META$sector.index, ]
                 if (nrow(matches) > 0) {
                   matches <- head(matches, cooccurring_diseases_per_speciality)
                   circos.text(
                     x=(1:cooccurring_diseases_per_speciality - 0.5)[0:nrow(matches)], 
                     y=0,
                     labels=matches$phenotype_cooccurring_dis, 
                     facing="clockwise", niceFacing=T, cex=0.65, adj=c(0, .5))
                 }
               }
  )
  
  # track for short-names of speciality for each sector
  circos.track(ylim=c(0, 0.1), track.height=0.05, bg.border=NA, track.margin=c(.01, 0), 
               panel.fun=function(x,y) {
                 # if we have co-occurring diseases for this speciality
                 if (CELL_META$sector.index %in% selected_disease$code) {
                   textcolor <- 'black'
                     
                   matches <- selected_disease[selected_disease$code == CELL_META$sector.index, ]
                   matches <- head(matches, cooccurring_diseases_per_speciality)
                   for (i in 1:nrow(matches)) {
                     circos.segments((1:nrow(matches)) - 0.5, -0.05, (1:nrow(matches)) - 0.5, 0.11)
                   }
                   draw.sector(
                     get.cell.meta.data("cell.start.degree", sector.index = CELL_META$sector.index),
                     get.cell.meta.data("cell.end.degree", sector.index = CELL_META$sector.index),
                     rou1 = get.cell.meta.data("cell.top.radius", track.index = 2),
                     rou2 = get.cell.meta.data("cell.bottom.radius", track.index = 2),
                     col = speciality_colours[CELL_META$sector.numeric.index], border=NA
                     )
                 } else {
                   # otherwise, no diseases for this speciality
                   textcolor <- 'darkgray'
                 }
                 
                 circos.text(CELL_META$xcenter, 0.05, CELL_META$sector.index, cex=0.8, col=textcolor)
               }
  )
  
  
  # track for prevalence ratio
  # no native support for log scale - do it by hand
  
  # plot track grid lines (aka circles)
  prevalence_ratio_breaks = log(c(1, 5, 10, 50, 100, 500, 1000, 10000))
  
  circos.track(ylim = c(log(1), log(10000)), bg.col=NA, bg.border=NA, track.margin=c(0, 0),
               panel.fun = function(x, y) {
                 matches <- selected_disease[selected_disease$code == CELL_META$sector.index, ]
                 if (nrow(matches) > 0) {
                   circos.rect(CELL_META$cell.xlim[1], CELL_META$cell.ylim[1],
                               CELL_META$cell.xlim[2], CELL_META$cell.ylim[2], 
                               col = cooccurring_diseases_sector_bg_col, border = NA)
                   for (r in head(prevalence_ratio_breaks,-1)) {
                     circos.segments(0, r, cooccurring_diseases_per_speciality, r, col=sector_grid_lines_col)
                   }
                   matches <- head(matches, cooccurring_diseases_per_speciality)
                   value <- log(matches$prev_ratio)
                   # circos.barplot doesn't plot on log-scale. draw rectangles instead
                   xstart = 0
                   for (v in value) {
                     truncate = FALSE
                     if (v > log(1000)) {
                       truncate = TRUE
                       original_v = v
                       v =  log(1400)
                     }
                     circos.rect(xstart, log(1), xstart + 1, v, col=speciality_colours[ CELL_META$sector.numeric.index])
                     circos.segments(xstart + 0.5, v, xstart + 0.5, log(10000), straight=TRUE, lwd=1, lty='dashed', col=sector_grid_lines_col)
                     if (truncate) {
                       circos.text(xstart + 0.5, v, "=", facing='clockwise', niceFacing=TRUE)  # can't plot unicode characters...?
                       # circos.triangle(x1=xstart, y1=log(1000), x2=xstart+1, y2=log(1000), x3=xstart+0.5, y3=log(2000), border=speciality_colours[ CELL_META$sector.numeric.index], col=speciality_colours[ CELL_META$sector.numeric.index])
                     }
                     if (truncate) {
                      circos.text(xstart + 0.5, v + 0.3, round(exp(original_v), 1), facing = 'clockwise', niceFacing = TRUE, adj=c(0, 0.5), cex=0.5)
                     } else {
                      circos.text(xstart + 0.5, v + 0.2, round(exp(v), 2), facing = 'clockwise', niceFacing = TRUE, adj=c(0, 0.5), cex=0.5)                      
                     }

                     xstart = xstart + 1
                   }
                   # note: value+log(3) is padding to place the values at top of rectangle
                   # circos.text((1:cooccurring_diseases_per_speciality - 0.5)[0:nrow(matches)], value + log(3), round(exp(value), 2), facing = 'clockwise', niceFacing = TRUE, cex=0.6)
                 } else {
                   for (r in head(prevalence_ratio_breaks,-1)) {
                     circos.segments(0, r, cooccurring_diseases_per_speciality, r, col=sector_grid_lines_col)
                   }
                 }
               }
  )
  
  # track for prevalence
  prevalence_breaks = log(c(1, 5, 10, 50, 100))
  circos.track(ylim = c(log(100), log(1)), bg.col=NA, bg.border=NA, track.margin=c(0, 0),
               panel.fun = function(x, y) {
                 # does this speciality sector have any co-occurring diseases?
                 matches <- selected_disease[selected_disease$code == CELL_META$sector.index, ]
                 if (nrow(matches) > 0) {
                   circos.rect(CELL_META$cell.xlim[1], CELL_META$cell.ylim[1],
                               CELL_META$cell.xlim[2], CELL_META$cell.ylim[2], 
                               col = cooccurring_diseases_sector_bg_col, border = NA)
                   for (r in prevalence_breaks) {
                     circos.segments(0, r, cooccurring_diseases_per_speciality, r, col=sector_grid_lines_col)
                   }                 
                   sectorcolor <- speciality_colours[ CELL_META$sector.numeric.index]
                   # make transparent
                   sectorcolor <- adjustcolor(sectorcolor, alpha.f = 0.2)
                   matches <- head(matches, cooccurring_diseases_per_speciality)
                   value <- log(matches$prevalence)
                   xstart = 0
                   for (v in value) {
                     circos.rect(xstart, log(1), xstart + 1, v, col=sectorcolor, border=adjustcolor("black", alpha.f=0.2))
                     xstart = xstart + 1
                   }
                 } else {
                   for (r in prevalence_breaks) {
                     circos.segments(0, r, cooccurring_diseases_per_speciality, r, col=sector_grid_lines_col)
                   }                 
                 }

               }
  )
  
    circos.text(x=2.5, y=prevalence_ratio_breaks, track.index=3, sector.index=' ', labels=c("1", "5", "10", "50", "100", "500", "1000"), adj=c(0, 0.5), cex=0.65)
    circos.text(x=1, y=3.5, "Standardised prevalence ratio", facing="clockwise", track.index=3, sector.index=' ', cex=0.65)
    
    circos.text(x=2.5, y=prevalence_breaks, track.index=4, sector.index=' ', labels=c("1", "5", "10", "50", "100"), adj=c(0, 0.5), cex=0.65)
    circos.text(x=1, y=2.25, "Prevalence (%)", facing="reverse.clockwise", track.index=4, sector.index=' ', cex=0.65)
  
  # disease name in center of circle
  disease_name = stringr::str_wrap(selected_disease$phenotype_index_dis[1], width=20)
  disease_name = paste0(disease_name, '\n', '(n=', selected_disease$nphecode[1], ' patients)')
  text(0,0, disease_name)
  
  # to save to file:
  # dev.print(pdf, paste0('plot_', selected_disease$phecode_index_dis[1], '.pdf'), width=15, height=15)
  
  if (to_svg) {
    dev.off()
  }

} 


# ---- DATA ----
# (From Ana)
home_res <- Sys.getenv("ATLASVIEW_DATA_PATH")

fpath1 <- paste0(home_res, "/MM_for_circo_network_vis_29112022.csv")
fpath2 <- paste0(home_res, "/lkp_unique_spec_circo_plot.csv")
fpath3 <- paste0(home_res, "/lkp_unique_spec_circo_plot_codes.csv")

MM_for_circo_network_vis_29112022 <- read_csv(fpath1)
lkp_unique_spec_circo_plot <- read_csv(fpath2)
lkp_unique_spec_circo_plot_codes <- read_csv(fpath3)

# lookup for speciality codes
spec_codes_merged <- cbind(lkp_unique_spec_circo_plot, lkp_unique_spec_circo_plot_codes)
spec_codes_merged <- spec_codes_merged[order(spec_codes_merged$code), ]

# ---- add placeholder N ----
# dummy df with placeholder of N cases in index disease (nphecode)
df_dummy_N <- data.frame(index_dis = unique(MM_for_circo_network_vis_29112022$phecode_index_dis),
                         nphecode = ' ')

df_dummy_N$nphecode <- sample(100:1000, length(df_dummy_N$nphecode))


# ---- PLOT ----
# add four-letter abbreviations for specialities
MM_processed <- merge(MM_for_circo_network_vis_29112022, spec_codes_merged, by.x='speciality_cooccurring_dis', by.y='speciality')

# merge placeholder N in index disease
MM_processed <- merge(MM_processed, df_dummy_N, 
                      by.x='phecode_index_dis', 
                      by.y='index_dis')


# # create plot for each disease code
# all_disease_phecodes <- unique(MM_processed$phecode_index_dis)
# # for (disease_code in head(all_disease_phecodes)) {
# for (disease_code in all_disease_phecodes) {
#   # disease_code <- 'X564_0_2'  # 'XREMAPI688'
#   make_plot(get_cooccurring_diseases(MM_processed, disease_code))
# }

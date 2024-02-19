##convert cover + constancy into importance value for analysis
## apply to table built from VegdatSUsummary function
#vegsum = veg_anal.tree; minimportance = 1; minconstancy = 60; noiseconstancy = 40; minplots = 0; covadj = .75
# minimportance = 0.5; minconstancy = .6; noiseconstancy = 0; minplots = 5; covadj = 1
# use.ksi = FALSE; reduce.lifeform = FALSE; reduction = 1; dom = 10; high_cons_cut = .6; minor = 1
# d1 = 4; dd1 = 4
create_diagnostic_veg <- function(veg.dat, su, minimportance = 0, minconstancy = 50, noiseconstancy = 0, minplots = 5, 
                                  use.ksi = FALSE, ksi, ksi.value, reduce.lifeform = TRUE, reduced.lifeforms, reduction = .1, dom = 10,  minor = 1){
  vegsum <- create_su_vegdata(veg.dat, su) %>% 
    create_analysis_vegsum(minimportance = minimportance, minconstancy = minconstancy, noiseconstancy = noiseconstancy, minplots = minplots)
  
  vegsum <- vegsum %>% rowwise() %>% mutate(constant_type = ifelse((Constancy >=minconstancy & MeanCov >=dom), "cd",
                                                                   ifelse((Constancy >=minconstancy & MeanCov <= minor), "cm",
                                                                          ifelse(Constancy >= minconstancy, "c", NA))))
  
  #d1 =4 
  ###Calculate diagnostic potential
  vegsum <- vegsum %>% mutate(d.potential = ifelse(constant_type %in% c("c", "cd"), 4,
                                                   ifelse(constant_type %in% c("cm"), 2,0)))     
  vegsum <- vegsum %>% mutate(dd.potential = ifelse(constant_type == "cd", ((MeanCov^0.5)-1), 0)) 
  vegsum <- vegsum %>% mutate(dd.potential = ifelse(dd.potential >4 , 4,
                                                    ifelse(dd.potential <0, 0, dd.potential)))
  
  vegsum <- vegsum %>% mutate(diagnostic.potential = ifelse((Constancy >= minconstancy & MeanCov >=dom), ((d.potential+dd.potential)*1.25)*(Constancy/100), 
                                                            ifelse(Constancy >= minconstancy, d.potential *(Constancy/100), 0)))
  
  if (isTRUE(reduce.lifeform)){
  vegsum <- left_join(vegsum, taxon.lifeform, by = c("Species" = "Code")) %>% 
    mutate(diagnostic.potential = ifelse(Lifeform %in% reduced.lifeform, (diagnostic.potential  * reduction),diagnostic.potential))%>% select(-Lifeform)
  }
  
  if (isTRUE(use.ksi)){
  vegsum <- vegsum %>% mutate(diagnostic.potential = ifelse(Species %in% ksi, diagnostic.potential * ksi.value,diagnostic.potential))
  }
  
  vegsum <- vegsum %>% dplyr::group_by(SiteUnit) %>% mutate(unit.diag.sum = sum(diagnostic.potential)) 
  return(vegsum)
}
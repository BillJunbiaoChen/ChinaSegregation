

clear all 
set more off 

cd "/Users/junbiao/Dropbox/Segregation/Quantification/"

local out_opt_idx = 5 // Miyun


// Housing price 
use "data/Beijing_housing_18.dta" // (18 indicating there are 18 counties)
replace price = price/1000
drop if year == 2006

rename county j_name 
keep j_name price year

replace j_name = "密云县" if j_name == "密云区" 
replace j_name = "延庆县" if j_name == "延庆区" 

merge m:1 j_name using "data/geography_crosswalk.dta", assert(match) nogen 

sort j_code year 
gen t = year - 2006

drop if j_code == `out_opt_idx'
egen j = group(j_code)

save "data/temp/Beijing_housing_price_clean.dta", replace



// Greenland
import delimited "data/temp/LUCC_bjcounty_forest_grassland_05to15.csv", clear
keep if inrange(year, 2007, 2014)

rename county_200 j_name 
gen t = year - 2006
merge m:1 j_name using "data/geography_crosswalk.dta", assert(match) nogen 

drop if j_code == `out_opt_idx'
egen j = group(j_code)
save "data/temp/Beijing_greenland_clean.dta", replace


// Commuting costs 






// Main Demand Estimation 

use "ChinaSegregation/tasks/demand_estimation/output/relative_likelihood_renewal_path_lowedu.dta", clear 
merge m:1 j t using "data/temp/Beijing_housing_price_clean.dta", nogen 
merge m:1 j t using "data/temp/Beijing_greenland_clean.dta", nogen 


gen log_price = log(price)
gen log_forest = log(forest + 0.01)
gen log_grassland = log(grassland + 0.01)


reghdfe Y log_price, a(t)




reghdfe Y log_price log_forest log_grassland, a(w t)









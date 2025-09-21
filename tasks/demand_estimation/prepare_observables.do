

clear all 
set more off 

cd "/Users/junbiao/Dropbox/Segregation/Quantification/"

local wker_type = "`1'" // "lowedu" or "highedu"
local out_opt_code = 18 // the reference location is always labeled by 18

// migration distance 
clear
import delimited "data/temp/beijing_geodist.csv"
rename county_code_i county_code 
merge m:1 county_code using "data/geography_crosswalk_Beijing_final.dta", keepusing(jj) assert(match) nogen
rename jj j_origin
drop county_code
rename county_code_j county_code 
merge m:1 county_code using "data/geography_crosswalk_Beijing_final.dta", keepusing(jj) assert(match) nogen
rename jj j_dest

order j_origin j_dest distance_km 


* adjust by distance w.r.t. the reference location 


save "data/temp/beijing_geodist_clean.dta", replace




// Housing price 
use "data/Beijing_housing_18.dta" // (18 indicating there are 18 counties)
replace price = price
drop if year == 2006

rename county j_name 
keep j_name price year
gen t = year - 2006
replace j_name = "密云县" if j_name == "密云区" 
replace j_name = "延庆县" if j_name == "延庆区" 

merge m:1 j_name using "data/geography_crosswalk_Beijing_final.dta", keepusing(jj) assert(match) nogen 
rename jj j 
save "data/temp/Beijing_housing_price_clean.dta", replace

// Instrumental variables 
import delimited using "ChinaSegregation/tasks/initial_data/housing_vars_0515.csv", clear 
rename county_2000 j_name 
rename ydate year
keep if inrange(year, 2007, 2014)
gen t = year - 2006
merge m:1 j_name using "data/geography_crosswalk_Beijing_final.dta", keepusing(jj) assert(match) nogen 
rename jj j 
keep t j_name j median_unitsize mean_unitsize n_obs
fillin t j

preserve
    keep j t median_unitsize mean_unitsize n_obs
    tempfile characteristics_tf
    save `characteristics_tf', replace
    clear
restore

keep j t 
expand 18
rename j j_own
bysort j_own t: gen j = _n

merge m:1 t j using `characteristics_tf'
drop if j_own == j 
collapse (sum)mean_unitsize median_unitsize [fweight=n_obs], by(t j_own)
gen log_mean_unitsize = log(mean_unitsize)
rename j_own j 
save "data/temp/housing_characteristics_BLP.dta", replace


// Greenland
import delimited "data/temp/LUCC_bjcounty_forest_grassland_05to15.csv", clear
keep if inrange(year, 2007, 2014)

rename county_200 j_name 
gen t = year - 2006
merge m:1 j_name using "data/geography_crosswalk_Beijing_final.dta",  keepusing(jj) assert(match) nogen 
rename jj j 
save "data/temp/Beijing_greenland_clean.dta", replace


// Commuting costs 






// Main Demand Estimation 

use "ChinaSegregation/tasks/demand_estimation/output/relative_likelihood_renewal_path_`wker_type'.dta", clear 
merge m:1 j t using "data/temp/Beijing_housing_price_clean.dta", keep(match) nogen 
merge m:1 j t using "data/temp/Beijing_greenland_clean.dta", keep(match) nogen 
merge m:1 j t using "data/temp/housing_characteristics_BLP.dta", keep(match) nogen 

rename (jprev j) (j_origin j_dest)
merge m:1 j_origin j_dest using "data/temp/beijing_geodist_clean.dta", keepusing(distance_km) keep(match) nogen 
rename (j_dest distance_km) (j prev_migr_dist)

gen j_dest = `out_opt_code'
merge m:1 j_origin j_dest using "data/temp/beijing_geodist_clean.dta", keepusing(distance_km) keep(match) nogen 
drop j_dest
rename (j_origin distance_km) (jprev prev_migr_dist0)
replace prev_migr_dist = prev_migr_dist - prev_migr_dist0



rename (j j_tilde) (j_origin j_dest)
merge m:1 j_origin j_dest using "data/temp/beijing_geodist_clean.dta", keepusing(distance_km) keep(match) nogen 
rename (j_origin distance_km) (j renew_migr_dist)


gen j_origin = `out_opt_code'
merge m:1 j_origin j_dest using "data/temp/beijing_geodist_clean.dta", keepusing(distance_km) keep(match) nogen 
drop j_origin
rename (j_dest distance_km) (j_tilde renew_migr_dist0)
replace renew_migr_dist = renew_migr_dist - renew_migr_dist0


gen log_price = log(price)
gen log_price_sqr = log_price*log_price
gen log_forest = log(forest + 0.01)
gen log_grassland = log(grassland + 0.01)


rename Y rela_likelihood

gen log_prev_migr_dist = log(prev_migr_dist)
gen log_renew_migr_dist = log(renew_migr_dist)


// ivreghdfe rela_likelihood log_prev_migr_dist (log_price=median_unitsize), absorb(j w t) tol(1e-6)
// ivreghdfe rela_likelihood log_prev_migr_dist (log_price=mean_unitsize), absorb(j w t) tol(1e-6)
ivreghdfe rela_likelihood log_prev_migr_dist log_grassland log_forest (log_price=mean_unitsize), absorb(j w t) tol(1e-6)













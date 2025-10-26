

clear all 
set more off 

cd "/Users/junbiao/Dropbox/Segregation/Quantification/"

local wker_type = "`1'" // "lowedu" or "highedu"

local out_opt_code = 18 // the reference location is always labeled by 18

local beta = 0.9

// migration distance 
/*
clear
import delimited "ChinaSegregation/tasks/initial_data/bilateral_distances_across_counties.csv"
drop county_code*
rename county_name1 j_name 
merge m:1 j_name using "data/geography_crosswalk_Beijing_final.dta", keepusing(jj) assert(match) nogen
drop j_name
rename jj j_origin

rename county_name2 j_name 
merge m:1 j_name using "data/geography_crosswalk_Beijing_final.dta", keepusing(jj) assert(match) nogen
drop j_name
rename jj j_dest

order j_origin j_dest distance_km 
sort j_origin j_dest

save "data/temp/beijing_geodist_clean.dta", replace
*/



// Housing price 
use "data/Beijing_housing_18.dta" // (18 indicating there are 18 counties)
replace price = price
keep if inrange(year, 2007, 2014) // ECCP starts with the year 2007

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
keep t j_name j median_unitsize mean_unitsize tenure n_obs
fillin t j


sort t j
insobs 18 
replace t = 5 if missing(t)
replace j = _n - 108 if t == 5

insobs 18 
replace t = 6 if missing(t)
replace j = _n - 126 if t == 6

sort j t
* Linear interpolation
bysort j: ipolate mean_unitsize t, gen(mean_unitsize_itp)
bysort j: ipolate median_unitsize t, gen(median_unitsize_itp)
bysort j: ipolate tenure t, gen(tenure_itp)
bysort j: ipolate n_obs t, gen(n_obs_itp)


replace n_obs_itp = int(n_obs_itp)
unique t 

preserve
    keep j t median_unitsize_itp mean_unitsize_itp tenure_itp n_obs_itp
    tempfile characteristics_tf
	unique t 
    save `characteristics_tf', replace
    clear
restore

keep j t 
expand 18
rename j j_own
bysort j_own t: gen j = _n

merge m:1 t j using `characteristics_tf'
drop if j_own == j 

collapse (sum)mean_unitsize_itp median_unitsize_itp tenure_itp [fweight=n_obs_itp], by(t j_own)
gen log_mean_unitsize = log(mean_unitsize)
gen log_tenure = log(tenure)
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

/*
// MC(j, j_{t-1})
rename (jprev j) (j_origin j_dest)
merge m:1 j_origin j_dest using "data/temp/beijing_geodist_clean.dta", keepusing(distance_km) keep(match) nogen 
rename (j_dest distance_km) (j prev_moving_dist)

// MC(0, j_{t-1})
gen j_dest = `out_opt_code'
merge m:1 j_origin j_dest using "data/temp/beijing_geodist_clean.dta", keepusing(distance_km) keep(match) nogen 
drop j_dest
rename (j_origin distance_km) (jprev prev_moving_dist0)
replace prev_moving_dist = prev_moving_dist - prev_moving_dist0


// MC(\tilde{j}, j)
rename (j j_tilde) (j_origin j_dest)
merge m:1 j_origin j_dest using "data/temp/beijing_geodist_clean.dta", keepusing(distance_km) keep(match) nogen 
rename (j_origin distance_km) (j renew_moving_dist)


gen j_origin = `out_opt_code'
merge m:1 j_origin j_dest using "data/temp/beijing_geodist_clean.dta", keepusing(distance_km) keep(match) nogen 
drop j_origin
rename (j_dest distance_km) (j_tilde renew_moving_dist0)
replace renew_moving_dist = renew_moving_dist - renew_moving_dist0

gen delta_MC = prev_moving_dist - `beta' * renew_moving_dist
*/


gen log_price = log(price)
gen log_price_sqr = log_price*log_price
gen log_forest = log(forest + 0.01)
gen log_grassland = log(grassland + 0.01)


rename Y rela_likelihood

// gen log_prev_moving_dist = log(prev_moving_dist)
// gen log_renew_moving_dist = log(renew_moving_dist)


// ivreghdfe rela_likelihood log_prev_moving_dist (log_price=median_unitsize), absorb(j w t) tol(1e-6)
// ivreghdfe rela_likelihood log_prev_moving_dist (log_price=mean_unitsize), absorb(j w t) tol(1e-6)
// ivreghdfe rela_likelihood log_prev_moving_dist log_grassland log_forest (log_price=mean_unitsize), absorb(j w t) tol(1e-6)

ivreghdfe rela_likelihood log_grassland (log_price=tenure median_unitsize), absorb(j t) tol(1e-5)
// ivreghdfe rela_likelihood forest grassland (log_price= tenure median_unitsize ), absorb(j t) tol(1e-6)












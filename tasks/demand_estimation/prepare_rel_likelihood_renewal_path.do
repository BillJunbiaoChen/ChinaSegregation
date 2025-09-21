* This do file prepares the relative likelihood of renewal path, i.e., the LHS of the main demand ECCP regression.

clear all
set more off

cd "/Users/junbiao/Dropbox/Segregation/Quantification"

cap mkdir "ChinaSegregation/tasks/demand_estimation/output" 

local beta = 0.9 // discount factor
local T = 8
local J = 18 // N.B. This last county is always the outside option.
local W = 2


local wker_type = "`1'" // "lowedu" or "highedu"


// Import transition matrix
use "data/temp/probability_matrix_j_jp_w_`wker_type'.dta"


// Update j and jprev 
rename j j_temp 
merge m:1 j_temp using "data/geography_crosswalk_Beijing_final.dta", keepusing(jj) assert(match) nogen 
drop j_temp 
rename jj j 

rename jprev j_temp 
merge m:1 j_temp using "data/geography_crosswalk_Beijing_final.dta", keepusing(jj) assert(match) nogen
drop j_temp 
rename jj jprev 

order t w jprev j
sort t w jprev j



// Examine the input data (conditional prob)
bysort t w jprev: egen pr_total = sum(p_tjpw_`wker_type')
assert abs(pr_total - 1.0) < 1e-6
drop pr_total 
summ p_tjpw_`wker_type'


// More data cleaning
rename p_tjpw_`wker_type' phat
gen log_phat = log(phat)
replace t = t - 2006


// Select the outside option data
preserve 
	keep if j == `J'
	rename log_phat log_phat_reference
	tempfile log_phat_reference_tf 
	keep t jprev j w log_phat_reference 
	save `log_phat_reference_tf', replace 
	clear 
restore 


drop if j == `J'
drop nobs _fillin _ppmlhdfe_d mu denom


merge m:1 t jprev w using `log_phat_reference_tf', keepusing(log_phat_reference) assert(match) nogen 
count 
local total_obs = r(N)
assert `total_obs' == (`T') * (`J') * (`J' - 1) * (`W') // we remove the outside opt so J -1

save "transition_prob_main.dta", replace


preserve 
	drop if t == 1
	gen intertemp_merger = t - 1
	label variable intertemp_merger "label for t+1, starting from 1"
	keep jprev j w log_phat log_phat_reference intertemp_merger
	label variable jprev "current loc"
	label variable j "renewal loc"
	label variable log_phat "transition prob in the next period"
	label variable log_phat_reference "reference trans prob in the next period"
	
	drop if j == jprev // renewal loc != current loc
	drop if jprev == 18 // because current loc excludes the outside opt
	save "transition_prob_next.dta", replace 
	clear 
restore 

// Current period relative likelihood
gen term1 = log_phat - log_phat_reference

	
// Compute the renewal action component
expand `J' - 1
bysort t jprev w j: gen j_tilde = _n 
drop if j == j_tilde
order t w jprev j j_tilde 
sort t w jprev j j_tilde 

* merge current file with "transition_prob_next.dta" 
gen intertemp_merger = t 
label variable intertemp_merger "label for t+1, starting from 1"

rename (jprev j j_tilde log_phat log_phat_reference) (jprev_f j_f j_tilde_f log_phat_f log_phat_reference_f)
gen jprev = j_f
gen j = j_tilde_f

drop if intertemp_merger == 8 

merge m:1 w intertemp_merger jprev j using "transition_prob_next.dta", keepusing(log_phat log_phat_reference) assert(match) nogen 

gen term2 = `beta' * (log_phat - log_phat_reference)

// remove auxilliary variables
drop intertemp_merger jprev j log_phat log_phat_reference

rename (jprev_f j_f j_tilde_f log_phat_f log_phat_reference_f) (jprev j j_tilde log_phat log_phat_reference)


gen Y = term1 + term2 



count 
local total_obs = r(N)
assert `total_obs' == (`T' - 1) * (`J') * (`J' - 1) * (`J' - 2) * (`W')

label variable Y "relative likelihood: Y_{t, j, j_{t-1}, \tilde{j}, w}"
save "ChinaSegregation/tasks/demand_estimation/output/relative_likelihood_renewal_path_`wker_type'.dta", replace

	
	


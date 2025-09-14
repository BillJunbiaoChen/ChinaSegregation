* This do file prepares the relative likelihood of renewal path, i.e., the LHS of the main demand ECCP regression.

clear all
set more off

cd "/Users/junbiao/Dropbox/Segregation/Quantification"

cap mkdir "ChinaSegregation/tasks/demand_estimation/output" 

local beta = 0.85 // discount factor
local T = 8
local J = 17 // using a remote county as an outside option
local W = 2
local out_opt_idx = 16 // Tongzhou

local wker_type = "lowedu"
use "data/temp/probability_matrix_j_jp_w_`wker_type'.dta"



// Examine the input data (conditional prob)
bysort t w jprev: egen pr_total = sum(p_tjpw_`wker_type')
assert abs(pr_total - 1.0) < 1e-6
drop pr_total 
summ p_tjpw_`wker_type'


// More data cleaning
rename p_tjpw_`wker_type' phat
gen log_phat = log(phat)
replace t = t - 2006
rename j j_code
rename jprev jprev_code

drop if jprev_code == `out_opt_idx'

* !!WARNING!! update jprev after removing the outside option 
egen jprev = group(jprev_code)




// Define Tongzhou (j = 16) as the outside option 
preserve 
	keep if j_code == `out_opt_idx'
	rename log_phat log_phat_reference
	tempfile log_phat_reference_tf 
	keep t j_code jprev w log_phat_reference 
	
	* !!WARNING!! update j after removing the outside option 
	egen j = group(j_code)	
	assert j_code >= j 
	
	save `log_phat_reference_tf', replace 
	clear 
restore 


drop if j_code == `out_opt_idx'

* !!WARNING!! update j after removing the outside option 
egen j = group(j_code)	
assert jprev_code >= jprev
assert j_code >= j 

drop nobs _fillin _ppmlhdfe_d mu denom


merge m:1 t jprev w using `log_phat_reference_tf', keepusing(log_phat_reference) assert(match) nogen 


save "transition_prob_main.dta", replace

preserve 
	drop if j == jprev // staying in the same location doesn't count renewal action
	drop if t == 1
	gen tprime = t - 1
	label variable tprime "label for t+1, starting from 1"
	keep jprev j w log_phat log_phat_reference tprime
	label variable jprev "current loc"
	label variable j "renewal loc"
	label variable log_phat "transition prob in the next period"
	label variable log_phat_reference "reference trans prob in the next period"
	
	save "transition_prob_next.dta", replace 
	clear 
restore 

// Current period relative likelihood
gen term1 = log_phat - log_phat_reference

	
// Compute the renewal action component
expand `J'
bysort t jprev w j: gen j_tilde = _n 
drop if j == j_tilde
order t w jprev j j_tilde 
sort t w jprev j j_tilde 

* merge current file with "transition_prob_next.dta" 
gen tprime = t 
label variable tprime "label for t+1, starting from 1"

rename (jprev j j_tilde log_phat log_phat_reference) (jprev_f j_f j_tilde_f log_phat_f log_phat_reference_f)
gen jprev = j_f
gen j = j_tilde_f

drop if tprime == 8 

merge m:1 w tprime jprev j using "transition_prob_next.dta", keepusing(log_phat log_phat_reference) assert(match) nogen 

gen term2 = `beta' * (log_phat - log_phat_reference)

// remove auxilliary variables
drop tprime jprev j log_phat log_phat_reference

rename (jprev_f j_f j_tilde_f log_phat_f log_phat_reference_f) (jprev j j_tilde log_phat log_phat_reference)


gen Y = term1 + term2 



count 
local total_obs = r(N)
assert `total_obs' == (`T' - 1) * (`J') * (`J') * (`J' - 1) * (`W')

save "ChinaSegregation/tasks/demand_estimation/output/relative_likelihood_renewal_path_`wker_type'.dta", replace

	
	


*******************************************************
* Beijing Sorting Model — PPML Transition Matrices
* Starts from: $temp/panel_final_town_updated.dta
* Updated: 2025-09-05
*******************************************************



* Path
// cd "/Users/fxr/Desktop/Draft_202409/sorting"  
cd "/Users/junbiao/Dropbox/Segregation/Quantification/data"

// global raw "raw"
// global temp "temp"
// global outp "outputs"

clear
set more off, permanently


*** Data ***

forvalues edu_level = 1(1)2 {
	
	use "temp/panel_final_town_updated.dta", clear

	keep if id_firms_worked == 1 // 把贷款发生当期的公司地址看作这个人不变的公司地址，只保留没有更改过workplace的样本

	
	keep firm_townname homeloc_lastyear year homeloc edu_2group


    keep if edu_2group == `edu_level'
	
	rename homeloc_lastyear townname 
	merge m:1 townname using "../ChinaSegregation/tasks/initial_data/township_crosswalk_updated.dta", keep(master match) nogen
	rename towncode jprev
	drop townname 
	
	rename homeloc townname 
	merge m:1 townname using "../ChinaSegregation/tasks/initial_data/township_crosswalk_updated.dta", keep(master match)  nogen
	rename towncode j
	drop townname 
    
    rename year t


    gen w_county_name = substr(firm_townname, 1, strpos(firm_townname, "_") - 1)


    // * aggregate workplace 
	gen w = .
    * Downtown districts (index 1)
    replace w = 1 if w_county_name == "Dongcheng"
    replace w = 1 if w_county_name == "Xicheng"
    replace w = 1 if w_county_name == "Chaoyang"
    replace w = 1 if w_county_name == "Haidian"
    replace w = 1 if w_county_name == "Fengtai"
    replace w = 1 if w_county_name == "Shijingshan"
    replace w = 1 if w_county_name == "Chongwen"
    replace w = 1 if w_county_name == "Xuanwu"

    * Suburb districts/counties (index 2)
    replace w = 2 if w_county_name == "Changping"
    replace w = 2 if w_county_name == "Daxing"
    replace w = 2 if w_county_name == "Fangshan"
    replace w = 2 if w_county_name == "Huairou"
    replace w = 2 if w_county_name == "Mentougou"
    replace w = 2 if w_county_name == "Miyun"
    replace w = 2 if w_county_name == "Pinggu"
    replace w = 2 if w_county_name == "Shunyi"
    replace w = 2 if w_county_name == "Tongzhou"
    replace w = 2 if w_county_name == "Yanqing"


    label variable w "1 := urban, 2 := suburban"


    //label var m "marital group"
    //label var k "income group,3 groups"
    label var t "year"
    label var jprev "previous home (t-1)"
    label var w "workplace"
    label var j "destination town (t)"

    * missing
    drop if missing(t,jprev,w,j) // (189,119 observations deleted)

    * aggregate
    contract t jprev w j, freq(nobs)
    count

    * 填充所有组合
    fillin t jprev w j
    replace nobs = 0 if missing(nobs)
    count

    * PPML 
    ppmlhdfe nobs, absorb(t jprev w) vce(robust) d

    capture noisily predict double mu, mu
    if _rc {
        capture noisily predict double eta, eta
        gen double mu = exp(eta) if missing(mu)
    }

    replace mu = 0 if missing(mu)

    *  P^{t(j | j', w)
    bysort t jprev w: egen double denom = total(mu)
    gen double p_tjpw = mu/denom
    

    if `edu_level' == 1{
        label var p_tjpw "P^t(j | j', w) from PPML: Low Education group"
        rename p_tjpw p_tjpw_lowedu
        order t jprev j w p_tjpw_lowedu nobs 
        save "temp/probability_matrix_j_jp_w_lowedu.dta",replace 
    }
    
    if `edu_level' == 2{
        label var p_tjpw "P^t(j | j', w) from PPML: High Education group"
        rename p_tjpw p_tjpw_highedu
        order t jprev j w p_tjpw_highedu nobs 
        save "temp/probability_matrix_j_jp_w_highedu.dta",replace 
    }
}





* ---------
* Project: Residential Segregation in Chinese Cities 
* Purpose: This dofile defines the outside option for the housing mkt in Beijing.
* ---------

clear all 

cd "/Users/junbiao/Dropbox/Segregation/Quantification/"
use "data/geography_crosswalk.dta"

rename j_code j_temp

local out_opt_code = `1'



gen county_code = . 
replace county_code = 110101 if j_name == "东城区"
replace county_code = 110102 if j_name == "西城区"
replace county_code = 110103 if j_name == "崇文区"
replace county_code = 110104 if j_name == "宣武区"
replace county_code = 110105 if j_name == "朝阳区"
replace county_code = 110106 if j_name == "丰台区"
replace county_code = 110107 if j_name == "石景山区"
replace county_code = 110108 if j_name == "海淀区"
replace county_code = 110109 if j_name == "门头沟区"
replace county_code = 110111 if j_name == "房山区"
replace county_code = 110112 if j_name == "通州区"
replace county_code = 110113 if j_name == "顺义区"
replace county_code = 110114 if j_name == "昌平区"
replace county_code = 110115 if j_name == "大兴区"
replace county_code = 110116 if j_name == "怀柔区"
replace county_code = 110117 if j_name == "平谷区"
replace county_code = 110228 if j_name == "密云县"
replace county_code = 110229 if j_name == "延庆县"



replace county_code = 999999 if county_code == `out_opt_code'

egen jj = group(county_code)
sort jj // always put the outside option at last

replace county_code = `out_opt_code' if county_code == 999999


save "data/geography_crosswalk_Beijing_final.dta", replace






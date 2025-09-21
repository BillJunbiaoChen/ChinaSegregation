

clear all 

local main_dir = "/Users/junbiao/Dropbox/Segregation/Quantification/ChinaSegregation/tasks/"

cd `main_dir'
do "demand_estimation/clean_county_list.do" 110115 // 110115, 110109

cd `main_dir'
do "demand_estimation/prepare_rel_likelihood_renewal_path.do" "lowedu"
cd `main_dir'
do "demand_estimation/prepare_rel_likelihood_renewal_path.do" "highedu"

cd `main_dir'
do "demand_estimation/prepare_observables.do" "highedu"
cd `main_dir'
do "demand_estimation/prepare_observables.do" "lowedu"

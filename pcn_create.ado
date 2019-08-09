/*==================================================
project:       Create text file and other povcalnet files
Author:        R.Andres Castaneda Aguilar 
E-email:       acastanedaa@worldbank.org
url:           
Dependencies:  The World Bank
----------------------------------------------------
Creation Date:     9 Aug 2019 - 08:51:26
Modification Date:   
Do-file version:    01
References:          
Output:             
==================================================*/

/*==================================================
              0: Program set up
==================================================*/
program define pcn_create, rclass   
syntax [anything(name=subcmd id="subcommand")],  ///
[                                   ///
			countries(string)               ///
			Years(numlist)                 ///
			maindir(string)               ///
			type(string)                  ///
			survey(string)                ///
			replace                       ///
			vermast(string)               ///
			veralt(string)                ///
			MODule(string)                ///
			clear                         ///
			pause                         ///
			*                             ///
] 

version 15

*---------- conditions
if ("`pause'" == "pause") pause on
else                      pause off


* ---- Initial parameters

local date = date("`c(current_date)'", "DMY")  // %tdDDmonCCYY  
local time = clock("`c(current_time)'", "hms") // %tcHH:MM:SS  
local date_time = `date'*24*60*60*1000 + `time'  // %tcDDmonCCYY_HH:MM:SS  
local datetimeHRF: disp %tcDDmonCCYY_HH:MM:SS `date_time' 
local datetimeHRF = trim("`datetimeHRF'")	
local user=c(username) 



/*==================================================
            1: primus query
==================================================*/
qui pcn_primus_query, countries(`countries') years(`years') ///
`pause' vermast("`vermast'") veralt("`veralt'") 

local varlist = "`r(varlist)'"
local n = _N

/*==================================================
        2:  Loop over surveys
==================================================*/
mata: P  = J(0,0, .z)   // matrix with information about each survey
local i = 0
local previous ""
while (`i' < `n') {
	local ++i

	mata: pcn_ind(R)
	
	if ("`previous'" == "`country'-`year'") continue
	else local previous "`country'-`year'"


	*--------------------2.2: Load data
	cap noi pcn_load, country(`country') year(`year') type(`type') /*
		*/ maindir("`maindir'") vermast(`vermast') veralt(`veralt')  /*
		*/ survey("`survey'") `pause' `clear' `options'

	if (_rc) continue

	local filename = "`r(filename)'"
	local survin   = "`r(survin)'"
	local survid   = "`r(survid)'"
	local surdir   = "`r(surdir)'"
	return add

	/*==================================================
	            3:  Clear and save data
	==================================================*/
	*----------1.1:  
	* make sure no information is lost
	svyset, clear
	recast double welfare
	recast double weight    

	* monthly data
	quietly replace welfare=welfare/12

	* keep weight and welfare
	keep weight welfare
	sort welfare

	* collapse data
	collapse (sum) weight, by(welfare)

	* drop missing values
	quietly drop if welfare==.
	quietly drop if weight==.
	order weight welfare


	*--------Create folders
	cap mkdir "`surdir'/`survin'PCN"
	cap mkdir "`surdir'/`survin'PCN/Data"

	saveold "`surdir'/`survin'PCN/Data/`survin'collapsed.dta", `replace'

	export delimited using "`surdir'/`survin'PCN/Data/`country'`year'.txt", ///
		novarnames nolabel delimiter(tab) `replace'

	* mata: P = pcn_info(P)

} // end of while 

end


/*====================================================================
Mata functions
====================================================================*/
mata
mata drop pcn*()
mata set mataoptimize on
mata set matafavor speed

void pcn_ind(string matrix R) {
	i = strtoreal(st_local("i"))
	vars = tokens(st_local("varlist"))
	for (j =1; j<=cols(vars); j++) {
		//printf("j=%s\n", R[i,j])
		st_local(vars[j], R[i,j] )
	} 
} // end of IDs variables

string matrix pcn_info(matrix P) {

	survey = st_local("survey_id")

	status = st_local("status")

	dlwnote = st_local("dlwnote")


	if (rows(P) == 0) {
		P = survey, status, dlwnote
	}
	else {
		P = P \ (survey, status, dlwnote)
	}
	
	return(P)
}


end





exit
/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

Notes:
1.
2.
3.


Version Control:



/*==================================================
project:       Load working data stored in P drive
Author:        David L. Vargas
E-email:       acastanedaa@worldbank.org
url:
Dependencies:  The World Bank
----------------------------------------------------
Creation Date:     5 Feb 2020 -
Modification Date:
Do-file version:    01
References:
Output:
==================================================*/

/*==================================================
0: Program set up
==================================================*/
program define pcn_load_estimates, rclass
syntax [anything(name=subcmd id="subcommand")],  ///
[                                   ///
maindir(string)               ///
REshaped					///
VERsion(string) 			///
clear                   ///
pause                   ///
]

version 14

*---------- pause
if ("`pause'" == "pause") pause on
else                      pause off


* ---- Initial parameters

local date = date("`c(current_date)'", "DMY")  // %tdDDmonCCYY
local time = clock("`c(current_time)'", "hms") // %tcHH:MM:SS
local date_time = `date'*24*60*60*1000 + `time'  // %tcDDmonCCYY_HH:MM:SS
local datetimeHRF: disp %tcDDmonCCYY_HH:MM:SS `date_time'
local datetimeHRF = trim("`datetimeHRF'")
local user=c(username)


//========================================================
// Check version of pending data
//========================================================

qui {
	* working month
	local cmonth: disp %tdnn date("`c(current_date)'", "DMY")
	
	*Working year
	local wkyr:  disp %tdCCyy date("`c(current_date)'", "DMY")
	
	* Either Annual meeting (AM) or Spring meeting (SM)
	
	if inrange(`cmonth', 1, 4) | inrange(`cmonth', 11, 12)  local meeting "SM"
	if inrange(`cmonth', 5, 10) local meeting "AM"
	
	if inrange(`cmonth', 11, 12) {
		local wkyr = `wkyr' + 1  // workign for the next year's meeting
	}
	
	return local wkyr = `wkyr'
	return local meeting = "`meeting'"
	
	local maindir "`maindir'/`wkyr'_`meeting'/estimates"
	
	//========================================================
	// conditions
	//========================================================
	
	/* clean version */
	
	if ("`version'" != ""){
		if ("`version'" != "list"){
			if regexm("`version'","/"){
				if (strlen("`version'") == 8 | strlen("`version'") == 10){
					local version = date("`version'", "MDY")
				}
				else{
					noi di as err "Version should be list or a date in either stata, mm/dd/yy or mm/dd/yyyy format."
				}
			}
		}
	}
	
	/*==================================================
	1: Load data in memory
	==================================================*/
	
	/* reshpaed or regular
	
	if ("`REshaped'" != "" ){
	local fileroot "primus_estimates_reshaped"
	}
	else{
	local fileroot "primus_estimates"
	}
	*/
	
	/* filename according to version */
	local files: dir "`maindir'" files "*.dta", respectcase
	
	if (wordcount(`"`files'"') == 0) {
		noi disp in r "No estimates files found"
		error
	}
	else{
		if ("`version'" == ""){
			local filename "`fileroot'"
		}
		else if ("`version'"=="list"){
			if (wordcount(`"`files'"') == 1) {
				local filename = regexr(`files',`".dta"',"")
				noi disp in r "Loading Only available"
			}
			else {
				noi disp as text "list of available estimates files:"
				
				local i = 0
				foreach file of local files {
					local ++i
					local file = regexr("`file'",`".dta"',"")
					*if ("`avfile'" == "") loc avfile "`fileroot'"
					noi disp `"  `i' {c |} {stata `file'}"'
				}
				noi disp _n "select file to load" _request(_file)
				local filename = regexr(`"`file'"',".dta",`""')
			}
		}
		else{
			cap confirm "`maindir'/`fileroot'_`version'.dta"
			if _rc {
				local verstart : di %13.0f cofd(`version')
				local verstart = substr("`verstart'",1,5)
				di "`verstart'"
				foreach file of local files {
					if regexm(`"`file'"', "(.+)_(`verstart'.+)\.dta"){
						local a = regexs(2)
						local versions "`versions' `a'"
					}
				}
				if (wordcount(`"`versions'"') == 0) {
					noi disp in r "No estimates files found for that date"
					exit
				}
				if (wordcount(`"`versions'"') == 1) {
					local version = subinstr("`versions'"," ","",.)
					noi di as text "Loading only available for that date"
				}
				else {
					noi disp as text "list of available versions for that date:"
					local i = 0
					foreach version of local versions{
						loc ++i
						noi di `"  `i' {c |} {stata `version'}"'
					}
					noi disp _n "select file to load" _request(_version)
				}
				local filename "`fileroot'_`version'"
			}
			else{
				local filename "`fileroot'_`version'"
			}
		}
	}
	
	noi di as text "loading `filename'.dta ..."
	use "`maindir'/`filename'.dta", clear
	noi disp as text "`filename'.dta" as res " successfully loaded"
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
03feb2020 20:56:07
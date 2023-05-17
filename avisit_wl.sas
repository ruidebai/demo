%macro avisit_wl(indata=, domain=,dtc= ,outdata=);

/*epoch*/
data temp_se;
	set raw.se;
	if SESTDTC^='' then SESTDTC1=input(SESTDTC,e8601da.);
	format SESTDTC1 e8601da.;
proc sort;by usubjid seseq;run;
run;

proc transpose data=temp_se out=temp_se_t prefix=col;
	by usubjid ;
	id seseq;
	var SESTDTC1 ;
quit;


proc sql;
create table temp_&domain. as
	select a.*,se.col1 as SCRN ,se.col2 as P , se.col3 as PAB , se.col4 as AB1, se.col5 as AB2
	from &indata. as a
	left join temp_se_t  as se on a.usubjid=se.usubjid
	order by a.usubjid,a.&domain.test ,a.&domain.dtc,a.VISITNUM;
quit;
	
data temp_1;
 
	set temp_&domain.;
	by  usubjid &domain.test  &domain.dtc VISITNUM;
	if &dtc. not in ("","uk") then dtc=input(&dtc.,e8601da.);
	if ADT>. and TRTSDT>. then do;
	    if .<ADT < TRTSDT then ADY=ADT - TRTSDT ;
	    if  ADT >= TRTSDT then ADY=ADT - TRTSDT + 1;
	end;
/*if dtc^=.  and tr01sdt^=. then dy=intck('DAY',tr01sdt,dtc);*/
	if ADY<1 and last.&domain.dtc  and dtc^=. then bflag='Y';	
proc sort ;by usubjid  param &domain.test  bflag dtc VISITNUM ;
run;
 
data &outdata.;
	set temp_1;
	by  usubjid  param &domain.test  bflag dtc VISITNUM; 
	length AWRANGE avisit $200.;
	if TR02SDT^=. then T02dy=TR02SDT-TRtSDT+1;
	if TR02SDT=. and RFENDTC^=""  then T02dy=input(RFENDTC,e8601da.)-TRtSDT+1;
	if dtc<=tr02sdt   or ab1=.  then do;
		if last.bflag and bflag='Y' then do;avisit='基线';avisitn=0;ablfl="Y";pdy=0;AWRANGE="≤1";end;	
		if 1<=ADY<=42 then do;avisit='第4周';avisitn=4;pdy=28;AWRANGE="[1,42]";end;
		if 42<ADY<=70 then do;avisit='第8周';avisitn=8;pdy=56;AWRANGE="(42,70]";end;
		if 70<ADY and T02dy<98 then do;avisit='第12周';avisitn=12;pdy=84;AWRANGE="(70,98]";end;
		if 70<ADY and 98<=T02dy then do;avisit='第12周';avisitn=12;pdy=84;AWRANGE="(70,"||cats(TR02SDT)||"]";end;
	end;
	if dtc<=tr03sdt   or ab1=.  then do;
		if 98<ADY<=126 then do;avisit='第16周';avisitn=16;pdy=112;AWRANGE="("||cats(TR02SDT)||",126]";end;
		if 126<ADY<=154 then do;avisit='第20周';avisitn=20;pdy=140;AWRANGE="(126,154]";end;
		if 154<ADY<=182 then do;avisit='第24周';avisitn=24;pdy=168;AWRANGE="(154,182]";end;
	end;
	if  tr03sdt <dtc and ab2^=. then do; 
		if 182<ADY<=238 then do;avisit='第28周';avisitn=28;pdy=196;AWRANGE="(182,238]";end;
		if  238<ADY<=322 then do;avisit='第40周';avisitn=40;pdy=280;AWRANGE="(238,322]";end;
		if  322<ADY then do;avisit='第52周';avisitn=52;pdy=364;AWRANGE="(322,研究结束]";end;
	end;
	AWTARGET=pdy;
	AWTDIFF=abs(ADY-AWTARGET);


run;

proc datasets lib=work memtype=data nolist;
              delete temp:;
              quit;
run;

%mend;
 

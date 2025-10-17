libname hw4 "/home/u64140125/805/HW/HW4";
run;

/*importing xlsx file via proc import macro*/
%macro import (data_out, Filepath);
proc import out= hw4.&data_out
datafile= &Filepath
dbms = xlsx replace; 
getnames=yes ; 
run; 
%mend import;

%import (trial01, "/home/u64140125/805/HW/HW4/trial01_f25.xlsx");
%import (trial02, "/home/u64140125/805/HW/HW4/trial02_f25.xlsx");
%import (trial03, "/home/u64140125/805/HW/HW4/trial03_f25.xlsx");
%import (trial04, "/home/u64140125/805/HW/HW4/trial04_f25.xlsx");
%import (trial05, "/home/u64140125/805/HW/HW4/trial05_f25.xlsx");

/*making sure trials are sorted*/
%macro sort (trial, var);
proc sort data=hw4.&trial;
by &var;
run;
%mend sort;

%sort (trial01, id);
%sort (trial02, id);
%sort (trial03, id);
%sort (trial04, id);

/*Appending trial 1-4 data into ALLTRIALS w/ marker for trial*/
data ALLTRIALS;
set hw4.trial01 (in=in1) hw4.trial02 (in=in2) hw4.trial03 (in=in3)
 hw4.trial04 (in=in4);
 by id;
if (in1=1) then trial=1;
 else if (in2=1) then trial=2;
  else if (in3=1) then trial=3;
   else if (in4=1) then trial=4;
run;

proc sort data=alltrials;
by id;
run;

/*Using proc means to get mean tender joint count ouput*/
proc means data=ALLTRIALS noprint;
	where trial in (1 2 3);
	by id;
	var tjc;
	output out=STATS1 mean= tjc_mean n=trial_count;
run;

/*Ensuring only data from all 3 trials is included*/
data stats1;
set stats1;
if trial_count=3;
run;

/****Part B****/
/*Merging trial 4 data with STATS1*/
proc sql; create table
trials1_4 as select * from stats1 as in1
left join hw4.trial04 as in2
on in1.id=in2.id;
quit;

data trials1_4;
set trials1_4;
tjcdif = tjc-tjc_mean; /*creating difference variable, subtracting
 trial 4 TJC from 1-3 means*/
run;

/*Generating a report of the mean of difference var*/
proc means data=trials1_4 std mean n;
var tjcdif;
run;


/****Part C****/
%sort (trial05, id);
proc print data=hw4.trial05;
run;

/*merging trial 5 with trials1_4 data*/
proc sql; create table
trials1_5 as select * from trials1_4 as in1
left join hw4.trial05 as in2
on in1.id=in2.id;
quit;


proc contents data=trials1_5;
run;
/*ANOVA testing for interaction*/
proc glm data=trials1_5; 
	class treatment duration; 
	model tjcdif=treatment|duration / solution; 
	lsmeans treatment|duration / pdiff cl adjust=tukey;
run;

/*Anova stratified by disease duration*/
proc sort data=trials1_5;
by duration;
run;

proc glm data=trials1_5; 
by duration;
	class treatment; 
	model tjcdif=treatment / solution; 
	lsmeans treatment / pdiff cl;
run;


/****Part D****/
/*Age as potential confounder in duration=3*/
/*Test for association*/
proc corr data=trials1_5;
var tjcdif age;
where duration=3;
run;

/*Adjusted Model*/
proc glm data=trials1_5; 
where duration=3;
	class treatment; 
	model tjcdif=treatment age / solution; 
	lsmeans treatment / pdiff cl;
run;


/****Part E****/
/*Merging Trial 5 and ALLTRIALS by ID*/
%sort(trial05, ID);
proc sort data=alltrials;
by id;
run;

/*creating graphics dataset*/
data GRAPHICS;
merge alltrials (in=a) hw4.trial05 (in=b);
by id;
run;


/*Means of TJC for combo of trial, duration, and treatment*/
proc sort data=graphics;
by trial duration descending treatment;
run; 

proc means data=graphics noprint;
class trial duration treatment;
var tjc;
output out=gout mean=meantjc;
run;

data gout;
set gout;
where _type_=7;
run;


proc sort data=gout;
by duration;
run;

proc sgplot data=gout; by duration;
  styleattrs datacontrastcolors=(black red) datalinepatterns=(solid);
  series y=meantjc x=trial /group=treatment lineattrs=(thickness=3);
run;quit;



	
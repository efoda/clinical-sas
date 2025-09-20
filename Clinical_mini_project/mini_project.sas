/*Let’s build a complete mini clinical trial project that simulates real-life clinical SAS programming.

We’ll go end-to-end: multiple domains, multiple visits, derivations, analysis flags, TLFs, and export-ready datasets. I’ll include SAS code and explanations at every stage.

Complete Mini Clinical Trial Example
Scenario

Study ID: ST01

Subjects: 5 (101–105)

Treatments: TRT (active) vs PBO (placebo)

Domains: DM, VS, LB, AE

Visits: Baseline, Week 4, Week 8

Objective: Compare change from baseline SBP and lab results, summarize adverse events.

Include missing data handling (LOCF) and analysis flags.
*/

/*Step 1 — Raw Data

DM (Demographics)
*/

data raw_dm;
input Subject	Sex $	Age	Trt_Group $;
datalines;
101 M 54 TRT
102 F 60 PBO
103 M 48 TRT
104 F 55 PBO
105 M 50 TRT
;
run;

*VS (Systolic BP);
data raw_vs;
input Subject	Visit $	Day	SBP;
datalines;
101 Baseline 0 148
101 Week 4   28 142
101 Week 8   56 138
102 Baseline 0 159
102 Week 4   28 155
102 Week 8   56 .
103 Baseline 0 142
103 Week 4   28 140
103 Week 8   56 135
104 Baseline 0 150
104 Week 4   28 148
104 Week 8   56 145
105 Baseline 0 140
105 Week 4   28 138
105 Week 8   56 135
;
run;

*LB (Glucose);
data raw_lb;
input Subject	Visit $8.	Day	Glucose; 
datalines;
101 Baseline 0 90
101 Week 4   28 100
101 Week 8   56 105
102 Baseline 0 95
102 Week 4   28 .
102 Week 8   56 98
103 Baseline 0 85
103 Week 4   28 90
103 Week 8   56 92
104 Baseline 0 100
104 Week 4   28 102
104 Week 8   56 101
105 Baseline 0 88
105 Week 4   28 90
105 Week 8   56 87
;
run;

*AE (Adverse Events);
data raw_ae;
input  Subject	AE_Term $	StartDay	EndDay	Severity;
datalines;
101 Headache 5 6 Mild
102 Rash 10 15 Moderate
103 Nausea 2 2 Mild
105 Fatigue 20 25 Mild
;
run;


*Step 2 — Import and SDTM Mapping;
/* Example: DM domain */
data dm;
    set raw_dm;
    STUDYID = "ST01";
    USUBJID = put(Subject,8.);
    ARM = Trt_Group;
    keep STUDYID USUBJID SEX AGE ARM;
run;

/* VS domain */
data vs;
    set raw_vs;
    STUDYID = "ST01";
    USUBJID = put(Subject,8.);
    VSTEST = "Systolic BP";
    VSSTRESN = SBP;
    VISIT = Visit;
    VISITDY = Day;
    keep STUDYID USUBJID VSTEST VISIT VISITDY VSSTRESN;
run;

/* LB domain */
data lb;
    set raw_lb;
    STUDYID = "ST01";
    USUBJID = put(Subject,8.);
    LBCAT = "Chemistry";
    LBTEST = "Glucose";
    LBSTRESN = Glucose;
    VISIT = Visit;
    VISITDY = Day;
    keep STUDYID USUBJID LBCAT LBTEST LBSTRESN VISIT VISITDY;
run;

/* AE domain */
data ae;
    set raw_ae;
    STUDYID = "ST01";
    USUBJID = put(Subject,8.);
    AETERM = AE_Term;
    AESTDTC = put(StartDay,3.);
    AEENDTC = put(EndDay,3.);
    AESEV = Severity;
    keep STUDYID USUBJID AETERM AESTDTC AEENDTC AESEV;
run;

/*Step 3 — ADaM Datasets
3a — ADVS (Systolic BP Analysis Dataset)

Derive baseline, each visit value, change, LOCF for missing Week 8
*/
proc sort data=vs; by USUBJID VISITDY; run;

data advs;
    retain BASE;
    set vs;
    by USUBJID;

    if VISIT="Baseline" then BASE = VSSTRESN;

    /* Analysis for Week 4 and Week 8 */
    if VISIT in ("Week 4", "Week 8") then do;
        AVAL = VSSTRESN;
        /* LOCF */
        if AVAL = . then AVAL = BASE;
        CHG = AVAL - BASE;
        ANL01FL = "Y";
    end;

    if VISIT in ("Week 4", "Week 8") then output;
    keep USUBJID VSTEST VISIT AVAL BASE CHG ANL01FL VISITDY;
run;

/*3b — ADLB (Glucose Analysis Dataset)

Similar derivation, LOCF for missing Week 4 for subject 102
*/
proc sort data=lb; by USUBJID VISITDY; run;

data adlb;
    retain BASE;
    set lb;
    by USUBJID;

    if VISIT="Baseline" then BASE = LBSTRESN;

    if VISIT in ("Week 4","Week 8") then do;
        AVAL = LBSTRESN;
        if AVAL = . then AVAL = BASE; /* LOCF */
        CHG = AVAL - BASE;
        ANL01FL = "Y";
    end;

    if VISIT in ("Week 4","Week 8") then output;
    keep USUBJID LBTEST VISIT AVAL BASE CHG ANL01FL VISITDY;
run;

/*3c — ADAE (Adverse Events Analysis Dataset)

Flag all TEAEs
*/
data adae;
    set ae;
    TRTEMFL = "Y";
    keep USUBJID AETERM AESEV TRTEMFL;
run;

/*Step 4 — Merge Treatment Info*/
proc sql;
    create table advs2 as
    select a.*, b.ARM as TRT
    from advs a left join dm b
    on a.USUBJID = b.USUBJID;
quit;

proc sql;
    create table adlb2 as
    select a.*, b.ARM as TRT
    from adlb a left join dm b
    on a.USUBJID = b.USUBJID;
quit;

proc sql;
    create table adae2 as
    select a.*, b.ARM as TRT
    from adae a left join dm b
    on a.USUBJID = b.USUBJID;
quit;

/*Step 5 — TLFs
5a — Table: Systolic BP Change by Visit and Treatment
*/
proc means data=advs2 n mean std;
    class TRT VISIT;
    var CHG;
    output out=vs_summary mean=Mean std=StdDev n=N;
run;

proc print data=vs_summary noobs;
    var TRT VISIT N Mean StdDev;
    title "Table: Change from Baseline in Systolic BP by Visit";
run;

*5b — Table: Glucose Change;
proc means data=adlb2 n mean std;
    class TRT VISIT;
    var CHG;
    output out=lb_summary mean=Mean std=StdDev n=N;
run;

proc print data=lb_summary noobs;
    var TRT VISIT N Mean StdDev;
    title "Table: Change from Baseline in Glucose by Visit";
run;

*5c — Table: Adverse Events by Severity;
proc freq data=adae2;
    tables TRTEMFL*AESEV / norow nocol nopercent;
    title "Table: Treatment-Emergent Adverse Events by Severity";
run;

*5d — Figure: Mean Change SBP by Visit;
proc sgplot data=advs2;
    vline VISIT / response=CHG stat=mean group=TRT datalabel;
    title "Figure: Mean Change from Baseline Systolic BP";
run;

*Step 6 — Export ADaM Datasets for Submission;
libname xpt xport "advs.xpt";
proc copy in=work out=xpt;
    select advs2 adlb2 adae2 dm;
run;


/*Now these datasets are FDA-ready (XPT format).

A define.xml can be generated to describe all variables (usually via metadata tools).

✅ Key Real-Life Takeaways

Multiple domains: DM, VS, LB, AE → SDTM

ADaM derivations: Baseline, change from baseline, LOCF, flags

TLFs: Tables, Listings, Figures for clinical report

Missing data handling: critical in real trials

Export datasets: XPT format for regulatory submission

SAS code is your main tool for all stages

This mini-project simulates almost exactly what clinical SAS programmers do on the job, just scaled down.

*/

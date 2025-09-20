/*
synthetic Bells Palsy clinical trial dataset.
Step 1: Create a Synthetic Dataset

We’ll simulate a small clinical trial:

Study: A new drug for Bells Palsy

Arms: Placebo vs Drug A

Subjects: 20 patients

Variables: demographics, baseline & post-baseline scores, adverse events
*/

data raw;
input SUBJID	AGE	SEX $	ARM	$7. BASELINE	WEEK4	AE_DESC $	AE_SEV $;
datalines;
101 34 M Placebo 75 70 Headache Mild
102 42 F Drug A  65 50 Dizziness Moderate
103 29 M Drug A  80 55 Nausea Mild
104 51 F Placebo 70 68 None None
105 37 F Drug A  60 40 Fatigue Severe
;
run;

/*Step 2: Convert to SDTM

We’ll create:

DM (Demographics)

LB (Lab/efficacy scores)

AE (Adverse events)
*/
data dm;
    set raw;
    STUDYID = "BELLP001";
    DOMAIN = "DM";
    USUBJID = cats("BELLP-", SUBJID);
    ARMCD = ifc(ARM="Drug A","DRUGA","PLAC");
    ARM = ARM;
    AGE = AGE;
    SEX = SEX;
    keep STUDYID DOMAIN USUBJID ARMCD ARM AGE SEX;
run;

data lb;
    set raw;
    STUDYID = "BELLP001";
    DOMAIN = "LB";
    USUBJID = cats("BELLP-", SUBJID);

    VISITNUM = 1; VISIT = "Baseline"; AVAL = BASELINE; output;
    VISITNUM = 2; VISIT = "Week 4";  AVAL = WEEK4; output;

    keep STUDYID DOMAIN USUBJID VISITNUM VISIT AVAL;
run;

data ae;
    set raw;
    STUDYID = "BELLP001";
    DOMAIN = "AE";
    USUBJID = cats("BELLP-", SUBJID);

    if AE_DESC ne "None" then do;
        AETERM = AE_DESC;
        AESEV = AE_SEV;
        output;
    end;

    keep STUDYID DOMAIN USUBJID AETERM AESEV;
run;
/*Step 3: Create ADaM Datasets

ADSL: Subject-level (demographics, treatment)

ADLB: Lab scores + change from baseline
*/
proc sort data=lb out=lb; by USUBJID VISITNUM; run;

data adlb;
    set lb;
    by USUBJID;
    retain baseline;
    if VISITNUM=1 then baseline=AVAL;
    change = AVAL - baseline;
    if VISITNUM>1;
    keep USUBJID VISITNUM VISIT AVAL baseline change;
run;

/*Step 4: Generate TLFs

Table 1: Demographics summary (mean age, sex count, by ARM)

Listing: Adverse Events

Figure: Change from baseline plot
*/
proc means data=dm n mean std;
    class ARM;
    var AGE;
run;

proc freq data=dm;
    tables ARM*SEX / nocum nopercent;
run;

/*Step 5: Define-XML (Snippet)
<ItemDef OID="IT.ADLB.CHANGE" Name="CHANGE" DataType="float">
    <Description>
        <TranslatedText xml:lang="en">Change from Baseline</TranslatedText>
    </Description>
</ItemDef>
*/


/*By following these steps, you’ll have:

Raw data → patients.csv

SDTM datasets → DM.sas7bdat, LB.sas7bdat, AE.sas7bdat

ADaM datasets → ADSL, ADLB

TLFs → demographics table, AE listing, lab plot

Define.xml snippet*/


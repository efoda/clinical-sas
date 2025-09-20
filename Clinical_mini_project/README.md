This mini-project, I am doing with ChatGPT help, simulates almost exactly what clinical SAS programmers do on the job, just scaled down. We build a complete mini clinical trial project that simulates real-life clinical SAS programming. We’ll go end-to-end: multiple domains, multiple visits, derivations, analysis flags, TLFs, and export-ready datasets. I’ll include SAS code and explanations at every stage.

Complete Mini Clinical Trial Example

Scenario:

Study ID: ST01
Subjects: 5 (101–105)
Treatments: TRT (active) vs PBO (placebo)
Domains: DM, VS, LB, AE
Visits: Baseline, Week 4, Week 8
Objective: Compare change from baseline SBP and lab results, summarize adverse events.
Include missing data handling (LOCF) and analysis flags.
Roadmap:

Step 1 — Create our raw data table: 1. raw_dm: DM (Demographics) 2. raw_vs: VS (Systolic BP) 3. raw_lb: LB (Glucose) 4. raw_ae: AE (Adverse Events)
Step 2 — Import and SDTM Mapping
Step 3 — ADaM Datasets
Step 4 — Merge Treatment Info
Step 5 — TLFs
Step 6 — Export ADaM Datasets for the FDA Submission
Key Real-Life Takeaways

Multiple domains: DM, VS, LB, AE → SDTM
ADaM derivations: Baseline, change from baseline, LOCF, flags
TLFs: Tables, Listings, Figures for clinical report
Missing data handling: critical in real trials
Export datasets: XPT format for regulatory submission
SAS code is your main tool for all stages

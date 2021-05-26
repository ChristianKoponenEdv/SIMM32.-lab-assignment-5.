* Encoding: UTF-8.

DATASET ACTIVATE DataSet1.
RECODE sex ('male'=1) ('female'=0) INTO male.
EXECUTE.

CROSSTABS
  /TABLES=sex BY male
  /FORMAT=AVALUE TABLES
  /CELLS=COUNT
  /COUNT ROUND CELL.

CORRELATIONS
  /VARIABLES=pain1 pain2 pain3 pain4
  /PRINT=TWOTAIL NOSIG
  /MISSING=PAIRWISE.

*restructured the pain variable by hand, also created a 'time' variable

MIXED pain_restructured WITH age STAI_trait pain_cat cortisol_serum mindfulness male Time
  /CRITERIA=DFMETHOD(SATTERTHWAITE) CIN(95) MXITER(100) MXSTEP(10) SCORING(1) 
    SINGULAR(0.000000000001) HCONVERGE(0, ABSOLUTE) LCONVERGE(0, ABSOLUTE) PCONVERGE(0.000001, ABSOLUTE)    
  /FIXED=age STAI_trait pain_cat cortisol_serum mindfulness male Time | SSTYPE(3)
  /METHOD=REML
  /PRINT=SOLUTION
  /RANDOM=INTERCEPT | SUBJECT(ID) COVTYPE(VC)
  /SAVE=PRED.

MIXED pain_restructured WITH age STAI_trait pain_cat cortisol_serum mindfulness male Time
  /CRITERIA=DFMETHOD(SATTERTHWAITE) CIN(95) MXITER(100) MXSTEP(10) SCORING(1) 
    SINGULAR(0.000000000001) HCONVERGE(0, ABSOLUTE) LCONVERGE(0, ABSOLUTE) PCONVERGE(0.000001, ABSOLUTE)    
  /FIXED=age STAI_trait pain_cat cortisol_serum mindfulness male Time | SSTYPE(3)
  /METHOD=REML
  /PRINT=CORB  SOLUTION
  /RANDOM=INTERCEPT Time | SUBJECT(ID) COVTYPE(UN)
  /SAVE=PRED.

* Changed the name of the saved variables to:   Pred_random_intercept_model        Pred_random_slope_model   

SORT CASES  BY ID.
SPLIT FILE SEPARATE BY ID.

* Chart Builder.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=Time 
    MEAN(Pain_Restructured)[name="MEAN_Pain_Restructured"] obs_or_pred MISSING=LISTWISE REPORTMISSING=NO    
  /GRAPHSPEC SOURCE=INLINE.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: Time=col(source(s), name("Time"), unit.category())
  DATA: MEAN_Pain_Restructured=col(source(s), name("MEAN_Pain_Restructured"))
  DATA: obs_or_pred=col(source(s), name("obs_or_pred"), unit.category())
  GUIDE: axis(dim(1), label("Time"))
  GUIDE: axis(dim(2), label("Mean Pain_Restructured"))
  GUIDE: legend(aesthetic(aesthetic.color.interior), label("obs_or_pred"))
  GUIDE: text.title(label("Multiple Line Mean of Pain_Restructured by Time by obs_or_pred"))
  SCALE: linear(dim(2), include(0))
  ELEMENT: line(position(Time*MEAN_Pain_Restructured), color.interior(obs_or_pred), missing.wings())    
END GPL.

* close this split-data and open the old one again. 

FREQUENCIES VARIABLES=Time
  /STATISTICS=MEAN
  /ORDER=ANALYSIS.

COMPUTE time_centered=Time - 2.5.
EXECUTE.

COMPUTE time_centered_sq=time_centered * time_centered.
EXECUTE.

MIXED pain_restructured WITH age STAI_trait pain_cat cortisol_serum mindfulness male time_centered 
    time_centered_sq
  /CRITERIA=DFMETHOD(SATTERTHWAITE) CIN(95) MXITER(100) MXSTEP(10) SCORING(1) 
    SINGULAR(0.000000000001) HCONVERGE(0, ABSOLUTE) LCONVERGE(0, ABSOLUTE) PCONVERGE(0.000001, ABSOLUTE)    
  /FIXED=age STAI_trait pain_cat cortisol_serum mindfulness male time_centered time_centered_sq | 
    SSTYPE(3)
  /METHOD=REML
  /PRINT=CORB  SOLUTION
  /RANDOM=INTERCEPT time_centered time_centered_sq | SUBJECT(ID) COVTYPE(UN)
  /SAVE=PRED.

*merged data to easier visualize the predicted VS observed values.

SORT CASES  BY ID.
SPLIT FILE SEPARATE BY ID.

* Chart Builder.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=Time MEAN(Pain)[name="MEAN_Pain"] obs_or_pred 
    MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: Time=col(source(s), name("Time"), unit.category())
  DATA: MEAN_Pain=col(source(s), name("MEAN_Pain"))
  DATA: obs_or_pred=col(source(s), name("obs_or_pred"), unit.category())
  GUIDE: axis(dim(1), label("Time"))
  GUIDE: axis(dim(2), label("Mean Pain"))
  GUIDE: legend(aesthetic(aesthetic.color.interior), label("obs_or_pred"))
  GUIDE: text.title(label("Multiple Line Mean of Pain by Time by obs_or_pred"))
  SCALE: linear(dim(2), include(0))
  ELEMENT: line(position(Time*MEAN_Pain), color.interior(obs_or_pred), missing.wings())
END GPL.

* let us look into model diagnostics, to do that let us go back to the previous dataset.

MIXED pain_restructured WITH age STAI_trait pain_cat cortisol_serum mindfulness male time_centered 
    time_centered_sq
  /CRITERIA=DFMETHOD(SATTERTHWAITE) CIN(95) MXITER(100) MXSTEP(10) SCORING(1) 
    SINGULAR(0.000000000001) HCONVERGE(0, ABSOLUTE) LCONVERGE(0, ABSOLUTE) PCONVERGE(0.000001, ABSOLUTE)    
  /FIXED=age STAI_trait pain_cat cortisol_serum mindfulness male time_centered time_centered_sq | 
    SSTYPE(3)
  /METHOD=REML
  /PRINT=CORB  SOLUTION
  /RANDOM=INTERCEPT time_centered time_centered_sq | SUBJECT(ID) COVTYPE(UN)
  /SAVE=PRED RESID.

DATASET ACTIVATE DataSet1.
EXAMINE VARIABLES=pain_restructured
  /PLOT BOXPLOT STEMLEAF HISTOGRAM NPPLOT
  /COMPARE GROUPS
  /STATISTICS DESCRIPTIVES
  /CINTERVAL 95
  /MISSING LISTWISE
  /NOTOTAL.

EXAMINE VARIABLES=pain_restructured BY ID
  /PLOT BOXPLOT STEMLEAF HISTOGRAM NPPLOT
  /COMPARE GROUPS
  /STATISTICS DESCRIPTIVES
  /CINTERVAL 95
  /MISSING LISTWISE
  /NOTOTAL.

* Chart Builder.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=Time 
    MEAN(pain_restructured)[name="MEAN_pain_restructured"] ID MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: Time=col(source(s), name("Time"), unit.category())
  DATA: MEAN_pain_restructured=col(source(s), name("MEAN_pain_restructured"))
  DATA: ID=col(source(s), name("ID"), unit.category())
  GUIDE: axis(dim(1), label("Time"))
  GUIDE: axis(dim(2), label("Mean pain_restructured"))
  GUIDE: legend(aesthetic(aesthetic.color.interior), label("ID"))
  GUIDE: text.title(label("Multiple Line Mean of pain_restructured by Time by ID"))
  SCALE: linear(dim(2), include(0))
  ELEMENT: line(position(Time*MEAN_pain_restructured), color.interior(ID), missing.wings())
END GPL.

EXAMINE VARIABLES=RESID_1
  /PLOT BOXPLOT STEMLEAF HISTOGRAM NPPLOT
  /COMPARE GROUPS
  /STATISTICS DESCRIPTIVES
  /CINTERVAL 95
  /MISSING LISTWISE
  /NOTOTAL.

EXAMINE VARIABLES=RESID_1 BY ID
  /PLOT BOXPLOT STEMLEAF HISTOGRAM NPPLOT
  /COMPARE GROUPS
  /STATISTICS DESCRIPTIVES
  /CINTERVAL 95
  /MISSING LISTWISE
  /NOTOTAL.

* Chart Builder.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=PRED_1 RESID_1 MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE
  /FITLINE TOTAL=NO.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: PRED_1=col(source(s), name("PRED_1"))
  DATA: RESID_1=col(source(s), name("RESID_1"))
  GUIDE: axis(dim(1), label("Predicted Values"))
  GUIDE: axis(dim(2), label("Residuals"))
  GUIDE: text.title(label("Simple Scatter of Residuals by Predicted Values"))
  ELEMENT: point(position(PRED_1*RESID_1))
END GPL.

* Chart Builder.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=age RESID_1 MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE
  /FITLINE TOTAL=NO.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: age=col(source(s), name("age"))
  DATA: RESID_1=col(source(s), name("RESID_1"))
  GUIDE: axis(dim(1), label("age"))
  GUIDE: axis(dim(2), label("Residuals"))
  GUIDE: text.title(label("Simple Scatter of Residuals by age"))
  ELEMENT: point(position(age*RESID_1))
END GPL.

* Chart Builder.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=STAI_trait RESID_1 MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE
  /FITLINE TOTAL=NO.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: STAI_trait=col(source(s), name("STAI_trait"))
  DATA: RESID_1=col(source(s), name("RESID_1"))
  GUIDE: axis(dim(1), label("STAI_trait"))
  GUIDE: axis(dim(2), label("Residuals"))
  GUIDE: text.title(label("Simple Scatter of Residuals by STAI_trait"))
  ELEMENT: point(position(STAI_trait*RESID_1))
END GPL.

* Chart Builder.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=pain_cat RESID_1 MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE
  /FITLINE TOTAL=NO.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: pain_cat=col(source(s), name("pain_cat"))
  DATA: RESID_1=col(source(s), name("RESID_1"))
  GUIDE: axis(dim(1), label("pain_cat"))
  GUIDE: axis(dim(2), label("Residuals"))
  GUIDE: text.title(label("Simple Scatter of Residuals by pain_cat"))
  ELEMENT: point(position(pain_cat*RESID_1))
END GPL.

* Chart Builder.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=cortisol_serum RESID_1 MISSING=LISTWISE 
    REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE
  /FITLINE TOTAL=NO.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: cortisol_serum=col(source(s), name("cortisol_serum"))
  DATA: RESID_1=col(source(s), name("RESID_1"))
  GUIDE: axis(dim(1), label("cortisol_serum"))
  GUIDE: axis(dim(2), label("Residuals"))
  GUIDE: text.title(label("Simple Scatter of Residuals by cortisol_serum"))
  ELEMENT: point(position(cortisol_serum*RESID_1))
END GPL.

* Chart Builder.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=mindfulness RESID_1 MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE
  /FITLINE TOTAL=NO.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: mindfulness=col(source(s), name("mindfulness"))
  DATA: RESID_1=col(source(s), name("RESID_1"))
  GUIDE: axis(dim(1), label("mindfulness"))
  GUIDE: axis(dim(2), label("Residuals"))
  GUIDE: text.title(label("Simple Scatter of Residuals by mindfulness"))
  ELEMENT: point(position(mindfulness*RESID_1))
END GPL.

* Chart Builder.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=Time RESID_1 MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE
  /FITLINE TOTAL=NO.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: Time=col(source(s), name("Time"), unit.category())
  DATA: RESID_1=col(source(s), name("RESID_1"))
  GUIDE: axis(dim(1), label("Time"))
  GUIDE: axis(dim(2), label("Residuals"))
  GUIDE: text.title(label("Simple Scatter of Residuals by Time"))
  SCALE: linear(dim(2), include(0))
  ELEMENT: point(position(Time*RESID_1))
END GPL.

* Chart Builder.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=time_centered_sq RESID_1 MISSING=LISTWISE 
    REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE
  /FITLINE TOTAL=NO.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: time_centered_sq=col(source(s), name("time_centered_sq"))
  DATA: RESID_1=col(source(s), name("RESID_1"))
  GUIDE: axis(dim(1), label("time_centered_sq"))
  GUIDE: axis(dim(2), label("Residuals"))
  GUIDE: text.title(label("Simple Scatter of Residuals by time_centered_sq"))
  ELEMENT: point(position(time_centered_sq*RESID_1))
END GPL.

CORRELATIONS
  /VARIABLES=age STAI_trait pain_cat cortisol_serum mindfulness male time_centered time_centered_sq
  /PRINT=TWOTAIL NOSIG
  /MISSING=PAIRWISE.

SPSSINC CREATE DUMMIES VARIABLE=ID 
ROOTNAME1=ID_dummy 
/OPTIONS ORDER=A USEVALUELABELS=YES USEML=YES OMITFIRST=NO.

CROSSTABS
  /TABLES=ID BY ID_dummy_1 ID_dummy_2 ID_dummy_3 ID_dummy_4 ID_dummy_5 ID_dummy_6 ID_dummy_7 
    ID_dummy_8 ID_dummy_9 ID_dummy_10 ID_dummy_11 ID_dummy_12 ID_dummy_13 ID_dummy_14 ID_dummy_15 
    ID_dummy_16 ID_dummy_17 ID_dummy_18 ID_dummy_19 ID_dummy_20
  /FORMAT=AVALUE TABLES
  /CELLS=COUNT
  /COUNT ROUND CELL.

COMPUTE Resid_1_squared=RESID_1 * RESID_1.
EXECUTE.

REGRESSION
  /MISSING LISTWISE
  /STATISTICS COEFF OUTS R ANOVA
  /CRITERIA=PIN(.05) POUT(.10)
  /NOORIGIN 
  /DEPENDENT Resid_1_squared
  /METHOD=ENTER ID_dummy_2 ID_dummy_3 ID_dummy_4 ID_dummy_5 ID_dummy_6 ID_dummy_7 ID_dummy_8 
    ID_dummy_9 ID_dummy_10 ID_dummy_11 ID_dummy_12 ID_dummy_13 ID_dummy_14 ID_dummy_15 ID_dummy_16 
    ID_dummy_17 ID_dummy_18 ID_dummy_19 ID_dummy_20.

MIXED pain_restructured WITH age STAI_trait pain_cat cortisol_serum mindfulness male time_centered 
    time_centered_sq
  /CRITERIA=DFMETHOD(SATTERTHWAITE) CIN(95) MXITER(100) MXSTEP(10) SCORING(1) 
    SINGULAR(0.000000000001) HCONVERGE(0, ABSOLUTE) LCONVERGE(0, ABSOLUTE) PCONVERGE(0.000001, ABSOLUTE)    
  /FIXED=age STAI_trait pain_cat cortisol_serum mindfulness male time_centered time_centered_sq | 
    SSTYPE(3)
  /METHOD=REML
  /PRINT=CORB  SOLUTION
  /RANDOM=INTERCEPT time_centered time_centered_sq | SUBJECT(ID) COVTYPE(UN) SOLUTION.

EXAMINE VARIABLES=VAR00001
  /PLOT BOXPLOT STEMLEAF HISTOGRAM NPPLOT
  /COMPARE GROUPS
  /STATISTICS DESCRIPTIVES
  /CINTERVAL 95
  /MISSING LISTWISE
  /NOTOTAL.
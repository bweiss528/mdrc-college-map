library(shiny)
library(leaflet)
library(dplyr)
library(DT)

`%||%` <- function(a, b) if (!is.null(a)) a else b

# ============================================================
# COLLEGE DATA - Read from Excel file
# ============================================================
library(readxl)

# Read coordinates and college info from Excel
# Place the Excel file in the same folder as this R script
# Works locally and when deployed to shinyapps.io
excel_path <- "RCT_Database_Task5_Coordinates.xlsx"

colleges_raw <- as.data.frame(read_excel(excel_path, sheet = "Colleges"))

colleges <- data.frame(
  name             = as.character(colleges_raw[, "Institution Name"]),
  rcts             = as.character(colleges_raw[, "MDRC RCTs"]),
  degree           = as.character(colleges_raw[, "Highest Degree"]),
  state            = as.character(colleges_raw[, "State"]),
  urbanicity       = as.character(colleges_raw[, "Urbanicity"]),
  ipeds_locale     = as.character(colleges_raw[, "IPEDS Locale"]),
  lat              = as.numeric(colleges_raw[, "Latitude"]),
  lng              = as.numeric(colleges_raw[, "Longitude"]),
  comp_financial    = colleges_raw[, "Financial Support"] == "Yes",
  comp_advising     = colleges_raw[, "Advising"] == "Yes",
  comp_ft_summer    = colleges_raw[, "FT/Summer Enrollment"] == "Yes",
  comp_tutoring     = colleges_raw[, "Tutoring"] == "Yes",
  comp_instructional= colleges_raw[, "Instructional Reform"] == "Yes",
  comp_learning_comm= colleges_raw[, "Learning Communities"] == "Yes",
  comp_success_course= colleges_raw[, "Success Courses"] == "Yes",
  stringsAsFactors = FALSE
)

# ============================================================
# ALL STUDY PROGRAMS
# ============================================================
all_programs <- sort(c(
  "ALAP","ASAP CUNY","ASAP Ohio","Academic Plan","AtD Mentoring",
  "AtD Success Course","CUNY Start","DCMP","DPP","EASE","LC Career",
  "LC English","LC English + Success","LC Math","LC Math + Success",
  "LC Reading","MMA","ModMath","Montana 10","OD Advising + Incentive","OD LC",
  "OD PBS + Advising","OD Success","OD Success (Enhanced)",
  "PBS + Advising","PBS + Supports","PBS Math","PBS NY","PBS OH",
  "SUCCESS","iPASS Fresno State","iPASS MCCC","iPASS UNCC"
))

# ============================================================
# RCT INFO FOR POPUP SHEETS
# ============================================================
rct_info <- list(
  "ASAP CUNY" = list(
    long_name="Accelerated Study in Associate Programs - CUNY",
    description="ASAP is a comprehensive three-year program offering financial supports (tuition waivers, free textbooks, transit cards) and intensive student services including high-touch advising, career support, and tutoring. Students were required to enroll full-time and meet monthly with a dedicated adviser.",
    length="3 years", sites="3", students="903",
    female="62", black="33", hispanic="42", white="0", under25="83",
    financial="Yes", advising="Yes", ft_summer="Yes", tutoring="Yes", instructional="No", learning_comm="Yes", success_course="Yes",
    impl="ASAP was implemented largely as designed, with some variation by college. The program provided students with a wide array of services and created a substantial contrast with usual college services.",
    impact="ASAP has an estimated 18 percentage point effect on 3-year graduation rates and increases 6-year graduation rates by an estimated 10 percentage points.",
    reports="3-year report|||https://www.mdrc.org/work/publications/doubling-graduation-rates|6-year report|||https://www.mdrc.org/work/publications/effects-city-university-new-yorks-accelerated-study-associate-programs-after-six-years|8-year cost analysis|||https://www.mdrc.org/publication/eight-year-cost-analysis-randomized-controlled-trial-cuny-s-accelerated-study-associate"
  ),
  "ASAP Ohio" = list(
    long_name="Accelerated Study in Associate Programs - Ohio Replication",
    description="ASAP Ohio replicated the CUNY ASAP model at three Ohio community colleges, providing up to three years of financial and academic support with requirements to attend full-time and participate in program services.",
    length="3 years", sites="3", students="1,522",
    female="63", black="34", hispanic="9", white="0", under25="72",
    financial="Yes", advising="Yes", ft_summer="Yes", tutoring="Yes", instructional="No", learning_comm="Yes", success_course="Yes",
    impl="The Ohio programs were generally implemented as designed, creating a noticeable contrast between program and control group students in all areas of the model.",
    impact="The Ohio Programs nearly doubled degree receipt through three years and led to increases in transfers to four-year colleges.",
    reports="2-year brief|||https://www.mdrc.org/work/publications/doubling-graduation-rates-new-state|3-year report|||https://www.mdrc.org/sites/default/files/ASAP_OH_3yr_Impact_Report_1.pdf"
  ),
  "AtD Mentoring" = list(
    long_name="Achieving the Dream - Beacon Mentoring Program",
    description="A light-touch intervention in which college employee mentors made classroom presentations about campus services and identified struggling students for early outreach.",
    length="0.5 years", sites="1", students="2,185",
    female="58", black="0", hispanic="95", white="0", under25="71",
    financial="No", advising="Yes", ft_summer="No", tutoring="No", instructional="No", learning_comm="No", success_course="No",
    impl="The program was implemented with reasonable fidelity, though student-mentor contact outside class occurred less often than anticipated.",
    impact="No meaningful impact on passing math classes or persistence, though participants were less likely to be absent or withdraw from math.",
    reports="Final report|||https://www.mdrc.org/work/publications/opening-doors-new-forms-mentoring-help-low-income-students"
  ),
  "AtD Success Course" = list(
    long_name="Achieving the Dream - Student Success Course",
    description="A success course for developmental education students focusing on psychosocial and soft skills such as emotional awareness, learning styles, time management, and personal responsibility.",
    length="0.5 years", sites="3", students="930",
    female="69", black="57", hispanic="6", white="0", under25="64",
    financial="No", advising="No", ft_summer="No", tutoring="No", instructional="No", learning_comm="No", success_course="Yes",
    impl="The course stayed true to the On Course philosophy with a strong emphasis on psychosocial skills, though implementation was stronger in the first semester.",
    impact="Positive impacts on self-management, self-awareness, and emotional intelligence, but gains did not translate to academic achievement.",
    reports="Final report|||https://www.mdrc.org/work/publications/learning-college-student-success-course"
  ),
  "ALAP" = list(
    long_name="Aid Like A Paycheck",
    description="Tested biweekly disbursement of financial aid refunds (vs. the traditional lump-sum) to help students better budget their existing financial aid over the semester.",
    length="Indefinite", sites="2", students="8,911",
    female="58", black="30", hispanic="50", white="0", under25="78",
    financial="No", advising="No", ft_summer="No", tutoring="No", instructional="No", learning_comm="No", success_course="Yes",
    impl="Colleges successfully implemented biweekly disbursements, though student communications about financial aid were often unclear.",
    impact="Reduced debt to the college in the first semester, but no evidence of improved long-term academic outcomes.",
    reports="Interim report|||https://www.mdrc.org/work/publications/aid-paycheck|Final report|||https://www.mdrc.org/work/publications/smoothing-road-college-success"
  ),
  "CUNY Start" = list(
    long_name="CUNY Start",
    description="A prematriculation program for students with significant remedial needs. Students delay matriculation one semester to receive intensive instruction in math, reading, and writing from trained teachers.",
    length="0.5 years", sites="4", students="3,873",
    female="48", black="26", hispanic="36", white="0", under25="81",
    financial="No", advising="Yes", ft_summer="Yes", tutoring="Yes", instructional="Yes", learning_comm="Yes", success_course="Yes",
    impl="CUNY Start was implemented with fidelity to the program model. There was a substantial contrast with standard developmental courses, especially in math instruction.",
    impact="Over three years, CUNY Start substantially increased college readiness, slightly increased credit accumulation, and modestly increased graduation rates.",
    reports="Interim report|||https://www.mdrc.org/work/publications/cuny-start-evaluation|3-year report|||https://www.mdrc.org/work/publications/cuny-start-three-year-findings"
  ),
  "DCMP" = list(
    long_name="Dana Center Math Pathways",
    description="Diversifies math course content to align with students' career interests, and streamlines the typical two-semester developmental math series into one semester.",
    length="1 year", sites="4", students="1,437",
    female="62", black="15", hispanic="54", white="0", under25="77",
    financial="No", advising="No", ft_summer="No", tutoring="Yes", instructional="Yes", learning_comm="No", success_course="No",
    impl="Virtually all courses remained faithful to the revised curricula, creating a strong contrast with standard developmental and college-level algebra courses.",
    impact="Positive impact on completion of the developmental math sequence and likelihood of passing college-level math, though no impacts on overall credit accumulation at 3 or 5 years.",
    reports="1.5-year report|||https://www.mdrc.org/work/publications/gaining-ground|3-year brief|||https://www.mdrc.org/work/publications/dana-center-math-pathways-boosts-rates|5-year working paper|||https://www.mdrc.org/work/publications/long-term-effects-dana-center-math-pathways-model"
  ),
  "DPP" = list(
    long_name="Detroit Promise Path",
    description="Students begin meeting with college coaches before their first semester and receive a $50 monthly gift card incentive for meeting with coaches as directed. The program lasts three years including summers.",
    length="3 years", sites="5", students="1,283",
    female="59", black="80", hispanic="12", white="0", under25="99",
    financial="Yes", advising="Yes", ft_summer="Yes", tutoring="No", instructional="No", learning_comm="No", success_course="No",
    impl="Well implemented by Chamber staff with high fidelity to coaching and incentive components, though some variation existed across colleges.",
    impact="Positive effects on persistence, full-time enrollment, and credit accumulation. Effects on persistence in the second semester are among the largest MDRC has found in postsecondary experiments.",
    reports="Issue focus|||https://mdrc.org/publication/learning-success|Interim report|||https://www.mdrc.org/work/publications/detroit-promise-path-interim-report"
  ),
  "EASE" = list(
    long_name="Encouraging Additional Summer Enrollment",
    description="Two interventions: (1) a personalized behavioral science communications campaign encouraging summer enrollment, and (2) the same campaign paired with a last-dollar tuition assistance grant.",
    length="0.5 years", sites="10", students="10,851",
    female="61", black="26", hispanic="4", white="0", under25="68",
    financial="Yes", advising="No", ft_summer="Yes", tutoring="No", instructional="No", learning_comm="No", success_course="No",
    impl="Informational campaigns implemented with medium to high fidelity. Six of 10 colleges sent all messages; students received substantially more summer enrollment communications than the control group.",
    impact="Both interventions increased summer enrollment and credit accumulation, with tuition assistance producing larger effects. Effects on credits earned were maintained 1 year later.",
    reports="Phase 1 brief|||https://www.mdrc.org/work/publications/encouraging-additional-summer-enrollment-phase-1|Phase 2 brief|||https://www.mdrc.org/work/publications/encouraging-additional-summer-enrollment-phase-2"
  ),
  "iPASS Fresno State" = list(
    long_name="Integrated Planning and Advising for Student Success - Fresno State",
    description="Enhanced advising using technology with four components: MyDegreePlan training, faculty early-alert surveys, peer mentor outreach, and required advising appointments.",
    length="1 year", sites="1", students="1,219",
    female="61", black="3", hispanic="62", white="0", under25="98",
    financial="No", advising="Yes", ft_summer="No", tutoring="No", instructional="No", learning_comm="No", success_course="No",
    impl="Advisers informed students about MyDegreePlan and held workshops, though student participation was low and early-alert implementation faced challenges.",
    impact="No statistically significant effects on students' short-term educational outcomes.",
    reports="Interim report|||https://www.mdrc.org/work/publications/ipass-interim-report"
  ),
  "iPASS MCCC" = list(
    long_name="Integrated Planning and Advising for Student Success - MCCC",
    description="Targeted at-risk continuing students not already required to meet advisers. Featured faculty early-alert surveys, student self-reporting of issues, and required career assessments.",
    length="1 year", sites="1", students="3,030",
    female="59", black="18", hispanic="7", white="0", under25="58",
    financial="No", advising="Yes", ft_summer="No", tutoring="No", instructional="No", learning_comm="No", success_course="No",
    impl="Advisers raised concerns with the predictive analytics software. Adviser capacity constraints remained an issue despite additional resources.",
    impact="Slightly negative estimated effect, with statistically significant reductions of 0.3 credits in both credits attempted and credits earned in the first semester.",
    reports="Interim report|||https://www.mdrc.org/work/publications/ipass-interim-report"
  ),
  "iPASS UNCC" = list(
    long_name="Integrated Planning and Advising for Student Success - UNCC",
    description="Focused on identifying at-risk students and conducting outreach and advising using registration holds, sustained communication, and a structured advising toolbox.",
    length="1 year", sites="1", students="3,820",
    female="43", black="14", hispanic="9", white="0", under25="95",
    financial="No", advising="Yes", ft_summer="No", tutoring="No", instructional="No", learning_comm="No", success_course="No",
    impl="Program group students received considerably more communications from advisers. Most advisers used the toolbox and reported slightly more in-depth conversations.",
    impact="No statistically significant effects on students' short-term educational outcomes.",
    reports="Interim report|||https://www.mdrc.org/work/publications/ipass-interim-report"
  ),
  "LC Career" = list(
    long_name="Learning Communities - Career Focused",
    description="Continuing students took three courses together: two required for a specific major plus an integrative seminar exposing students to career information in their field.",
    length="0.5 years", sites="1", students="930",
    female="59", black="33", hispanic="19", white="0", under25="83",
    financial="No", advising="No", ft_summer="No", tutoring="No", instructional="No", learning_comm="No", success_course="Yes",
    impl="The integrative seminar was understood differently by different instructors, and high student and instructor turnover led to considerable variation in delivery.",
    impact="No meaningful impacts on educational outcomes during the program semester or subsequent semesters.",
    reports="Final report|||https://www.mdrc.org/work/publications/learning-communities-developmental-education-students|Synthesis report|||https://www.mdrc.org/work/publications/learning-communities-developmental-education-students-synthesis"
  ),
  "LC English" = list(
    long_name="Learning Communities - Developmental English",
    description="Linked developmental writing with another course at the developmental level (reading or math) or a college-level content course such as health, criminology, or music.",
    length="0.5 years", sites="1", students="1,431",
    female="51", black="9", hispanic="55", white="0", under25="81",
    financial="No", advising="No", ft_summer="No", tutoring="No", instructional="No", learning_comm="No", success_course="Yes",
    impl="The program created 12 different learning communities with generally high faculty collaboration, though only about half of assigned students enrolled in a learning community.",
    impact="Students attempted and earned significantly more developmental English credits and passed more English courses. No impact on cumulative credits earned.",
    reports="Final report|||https://www.mdrc.org/work/publications/learning-communities-developmental-education-students|Synthesis report|||https://www.mdrc.org/work/publications/learning-communities-developmental-education-students-synthesis"
  ),
  "LC English + Success" = list(
    long_name="Learning Communities - Developmental English + Success Course",
    description="Linked developmental reading or writing with a college-level content course plus a unique Master Learner session providing an extra hour of weekly classroom instruction.",
    length="0.5 years", sites="2", students="1,094",
    female="59", black="55", hispanic="4", white="0", under25="89",
    financial="No", advising="No", ft_summer="No", tutoring="No", instructional="No", learning_comm="No", success_course="Yes",
    impl="Strong links and cohorts with variation in faculty collaboration, curricular integration, and the amount of instruction offered.",
    impact="No meaningful impacts on credit attempts, progress in developmental English, or cumulative credits earned.",
    reports="Final report|||https://www.mdrc.org/work/publications/learning-communities-developmental-education-students|Synthesis report|||https://www.mdrc.org/work/publications/learning-communities-developmental-education-students-synthesis"
  ),
  "LC Math" = list(
    long_name="Learning Communities - Developmental Math",
    description="Classes in all levels of developmental math were linked primarily with college-level classes to provide integrated learning experiences.",
    length="0.5 years", sites="1", students="1,038",
    female="56", black="28", hispanic="33", white="0", under25="92",
    financial="No", advising="No", ft_summer="No", tutoring="No", instructional="No", learning_comm="No", success_course="Yes",
    impl="A basic model was designed and implemented, with greater evidence of more comprehensive elements appearing later. High variation within an overall trend of improvement.",
    impact="Students passed math earlier, but control group members largely caught up by study's end. No improvement in persistence.",
    reports="Final report|||https://www.mdrc.org/work/publications/learning-communities-developmental-education-students|Synthesis report|||https://www.mdrc.org/work/publications/learning-communities-developmental-education-students-synthesis"
  ),
  "LC Math + Success" = list(
    long_name="Learning Communities - Developmental Math + Success Course",
    description="Linked the lowest level of developmental math with the college's student success class, designed to prepare students for the demands of college.",
    length="0.5 years", sites="3", students="1,284",
    female="67", black="34", hispanic="55", white="0", under25="80",
    financial="No", advising="No", ft_summer="No", tutoring="Yes", instructional="Yes", learning_comm="No", success_course="No",
    impl="Curricular integration increased from minimal to basic over the demonstration. Faculty collaboration varied but generally increased.",
    impact="Significantly more likely to pass developmental math in the program semester. No impact on cumulative credits or persistence.",
    reports="Final report|||https://www.mdrc.org/work/publications/learning-communities-developmental-education-students|Synthesis report|||https://www.mdrc.org/work/publications/learning-communities-developmental-education-students-synthesis"
  ),
  "LC Reading" = list(
    long_name="Learning Communities - Developmental Reading",
    description="Co-enrolled groups of around 20 students in a developmental reading course and a college success course.",
    length="0.5 years", sites="3", students="1,086",
    female="57", black="36", hispanic="32", white="0", under25="84",
    financial="No", advising="No", ft_summer="No", tutoring="No", instructional="No", learning_comm="No", success_course="Yes",
    impl="A basic model was designed and implemented. About 31% of program group students did not enroll in a learning community in their first semester.",
    impact="No meaningful impact on students' academic success overall.",
    reports="Final report|||https://www.mdrc.org/work/publications/learning-communities-developmental-education-students|Synthesis report|||https://www.mdrc.org/work/publications/learning-communities-developmental-education-students-synthesis"
  ),
  "ModMath" = list(
    long_name="Modularized, Computer-Assisted Developmental Math",
    description="Reorganizes two semester-long developmental math courses into six 5-week modules, using a diagnostic assessment, computer-based instruction, and on-demand assistance from an instructor.",
    length="1 year", sites="1", students="1,408",
    female="64", black="19", hispanic="27", white="0", under25="60",
    financial="No", advising="No", ft_summer="No", tutoring="No", instructional="No", learning_comm="No", success_course="Yes",
    impl="Components were implemented well with fidelity to the model. Classroom experiences of program and control groups were substantially different.",
    impact="No evidence that the program was superior to the traditional math class.",
    reports="Interim report|||https://www.mdrc.org/work/publications/modularized-computer-assisted-developmental-math|Working paper|||https://www.mdrc.org/work/publications/modmath-working-paper"
  ),
  "OD Advising + Incentive" = list(
    long_name="Opening Doors - Advising + Financial Incentive",
    description="Students were assigned to dedicated counselors with smaller caseloads for more frequent, intensive contact over two semesters, plus a $150 stipend per semester ($300 total).",
    length="1 year", sites="2", students="2,145",
    female="76", black="29", hispanic="11", white="0", under25="56",
    financial="Yes", advising="Yes", ft_summer="Yes", tutoring="Yes", instructional="No", learning_comm="Yes", success_course="Yes",
    impl="Both colleges provided counseling services that were more intensive and personalized than standard services.",
    impact="Program group students registered for a second semester at a higher rate and earned an average of half a credit more, but no meaningful effect on long-term outcomes.",
    reports="Final report|||https://www.mdrc.org/work/publications/opening-doors-college|Synthesis brief|||https://www.mdrc.org/work/publications/opening-doors-synthesis"
  ),
  "OD LC" = list(
    long_name="Opening Doors - Comprehensive Learning Community",
    description="Placed freshmen in groups of up to 25 who took three classes together in their first semester, with enhanced counseling, tutoring, and a textbook voucher.",
    length="0.5 years", sites="1", students="1,550",
    female="55", black="36", hispanic="20", white="0", under25="93",
    financial="Yes", advising="Yes", ft_summer="Yes", tutoring="Yes", instructional="No", learning_comm="Yes", success_course="Yes",
    impl="Well implemented despite a compressed planning period and large scale. All learning communities had the same basic structure but varied in content and faculty collaboration.",
    impact="Positive effects on short-term credit accumulation maintained seven years after random assignment, though no discernible impact on economic outcomes.",
    reports="2-year report|||https://www.mdrc.org/work/publications/opening-doors-louisiana|7-year report|||https://www.mdrc.org/work/publications/seven-year-effects-opening-doors-learning-communities-program"
  ),
  "OD PBS + Advising" = list(
    long_name="Opening Doors - Performance Based Scholarship + Advising",
    description="Offered $1,000 per semester for two semesters to low-income parents in community college who enrolled at least half-time and maintained a 2.0 GPA, paired with dedicated counseling.",
    length="1 year", sites="3", students="1,021",
    female="92", black="82", hispanic="2", white="0", under25="47",
    financial="Yes", advising="Yes", ft_summer="Yes", tutoring="No", instructional="No", learning_comm="No", success_course="No",
    impl="Key elements were in place for the full study duration and were clearly distinct from what control group members received.",
    impact="Increased registration, persistence into subsequent semesters, credits earned, and a range of social and psychological outcomes.",
    reports="Final report|||https://www.mdrc.org/work/publications/opening-doors-new-orleans|Synthesis brief|||https://www.mdrc.org/work/publications/opening-doors-synthesis"
  ),
  "OD Success" = list(
    long_name="Opening Doors - College Success Course + Centers",
    description="A College Success course taught by a counselor providing study skills and college information, with students expected to visit on-campus Success Centers nine times during the semester.",
    length="0.5 years", sites="1", students="907",
    female="60", black="14", hispanic="52", white="0", under25="87",
    financial="No", advising="Yes", ft_summer="Yes", tutoring="Yes", instructional="Yes", learning_comm="Yes", success_course="Yes",
    impl="Chaffey's original program did not fully operate as designed, and participation rates were lower than hoped.",
    impact="No meaningful effects on credits earned or grades. Did not help students get off academic probation.",
    reports="Final report|||https://www.mdrc.org/work/publications/opening-doors-california|Synthesis brief|||https://www.mdrc.org/work/publications/opening-doors-synthesis"
  ),
  "OD Success (Enhanced)" = list(
    long_name="Opening Doors - College Success Course + Centers (Enhanced)",
    description="A two-semester, mandatory version of the College Success program paired with required Success Center visits and stronger participation requirements.",
    length="1 year", sites="1", students="446",
    female="59", black="11", hispanic="51", white="0", under25="87",
    financial="No", advising="Yes", ft_summer="Yes", tutoring="Yes", instructional="Yes", learning_comm="Yes", success_course="Yes",
    impl="The Enhanced program operated largely as designed with relatively high participation rates.",
    impact="Positive short-term effect on GPA and likelihood of being in good academic standing, though no meaningful improvement in credits earned or credential attainment long-term.",
    reports="Final report|||https://www.mdrc.org/work/publications/opening-doors-california|Synthesis brief|||https://www.mdrc.org/work/publications/opening-doors-synthesis"
  ),
  "PBS NY" = list(
    long_name="Performance Based Scholarships - New York",
    description="Offered $1,300 per semester for up to three semesters to students who maintained at least part-time enrollment, met attendance benchmarks, and earned a C average across six credits.",
    length="1 year", sites="2", students="1,511",
    female="69", black="36", hispanic="43", white="0", under25="39",
    financial="Yes", advising="No", ft_summer="Yes", tutoring="No", instructional="No", learning_comm="No", success_course="No",
    impl="Recruitment was very successful. Scholarship staff restricted interactions to financial aid questions since the program had no counseling component.",
    impact="Encouraged more full-time enrollment and summer registration, but no significant impact on long-term outcomes like cumulative credits or degree attainment.",
    reports="Interim report|||https://www.mdrc.org/work/publications/performance-based-scholarships-new-york|Interim synthesis brief|||https://www.mdrc.org/work/publications/performance-based-scholarships-synthesis"
  ),
  "PBS OH" = list(
    long_name="Performance Based Scholarships - Ohio",
    description="Offered up to $1,800 in scholarships over two semesters for students achieving a C or better in 6+ credits, with differential payments based on enrollment intensity.",
    length="1 year", sites="5", students="2,352",
    female="86", black="31", hispanic="8", white="0", under25="30",
    financial="Yes", advising="No", ft_summer="Yes", tutoring="No", instructional="No", learning_comm="No", success_course="No",
    impl="Program was implemented as designed. All colleges demonstrated strong capacity to implement performance monitoring and award disbursement.",
    impact="Evidence that the program decreased time to earn a degree, but no evidence of increased employment or earnings by study's end.",
    reports="4-year report|||https://www.mdrc.org/work/publications/performance-based-scholarships-ohio|Interim synthesis brief|||https://www.mdrc.org/work/publications/performance-based-scholarships-synthesis"
  ),
  "PBS + Advising" = list(
    long_name="Performance Based Scholarships + Advising",
    description="Provided up to $1,000 in additional aid per semester for four semesters, conditional on minimum credit hours and GPA, combined with enhanced academic advising.",
    length="2 years", sites="1", students="1,103",
    female="61", black="3", hispanic="60", white="0", under25="100",
    financial="Yes", advising="Yes", ft_summer="Yes", tutoring="No", instructional="No", learning_comm="No", success_course="No",
    impl="Key components including student recruitment, regular advising communication, and scholarship payments were successfully implemented.",
    impact="Small increases in credit accumulation during the first two years translated into notable increases in graduation rates after five years - an increase of 4.5 percentage points.",
    reports="Working paper|||https://www.mdrc.org/work/publications/performance-based-scholarships-advising|Interim synthesis brief|||https://www.mdrc.org/work/publications/performance-based-scholarships-synthesis"
  ),
  "PBS Math" = list(
    long_name="Performance Based Scholarships + Math Lab",
    description="Provided incentives for low-income students referred to developmental math to take courses early and consecutively, use an on-campus Math Lab, and strive for passing grades in exchange for a modest scholarship.",
    length="1.5 years", sites="1", students="1,087",
    female="66", black="32", hispanic="30", white="0", under25="53",
    financial="Yes", advising="No", ft_summer="No", tutoring="Yes", instructional="No", learning_comm="No", success_course="No",
    impl="Program operated largely as designed. Staff fulfilled their duties, and scholarship payments were distributed with few errors.",
    impact="Students were much more likely to visit a Math Lab. Program helped move students further in the math sequence and modestly increased overall credits and graduation rates.",
    reports="Final report|||https://www.mdrc.org/work/publications/performance-based-scholarships-math-lab|Interim synthesis brief|||https://www.mdrc.org/work/publications/performance-based-scholarships-synthesis"
  ),
  "PBS + Supports" = list(
    long_name="Performance Based Scholarships + Supports",
    description="Offered up to $4,500 over three semesters to low-income Latino men, with scholarship payments for meeting enrollment benchmarks plus additional dollars for participating in advising, tutoring, and peer workshops.",
    length="1.5 years", sites="5", students="1,033",
    female="0", black="0", hispanic="100", white="0", under25="69",
    financial="Yes", advising="Yes", ft_summer="Yes", tutoring="Yes", instructional="No", learning_comm="Yes", success_course="Yes",
    impl="Students participated at high rates in advising and support services. The program demonstrated that such a model can be implemented at scale.",
    impact="Positive effect on retention and full-time enrollment. Increased net financial aid and allowed some students to reduce dependence on loans.",
    reports="Interim report|||https://www.mdrc.org/work/publications/performance-based-scholarships-supports|Interim synthesis brief|||https://www.mdrc.org/work/publications/performance-based-scholarships-synthesis"
  ),
  "SUCCESS" = list(
    long_name="Scaling Up College Completion Efforts for Student Success",
    description="SUCCESS was a lower-cost comprehensive approach providing financial support, advising, and full-time enrollment encouragement over three years. Students were required to enroll full-time and participate in program services including coaching and financial incentives.",
    length="3 years", sites="11", students="4,153",
    female="67", black="28", hispanic="31", white="32", under25="50",
    financial="Yes", advising="Yes", ft_summer="Yes", tutoring="No", instructional="No", learning_comm="No", success_course="No",
    impl="SUCCESS was not implemented as originally designed due to the COVID-19 pandemic. Most coaching was provided virtually rather than in person, and some financial support components were scaled back.",
    impact="On average, SUCCESS had no discernible effect on credits earned in the first year or on degree receipt through three years. Some variation in effects was found across colleges.",
    reports="Varying Levels of SUCCESS (Oct 2023)|||https://www.mdrc.org/sites/default/files/SUCCESS_One-Year_Report_v2.pdf|Testing a Lower Cost Model of Student Supports (Aug 2025)|||https://www.mdrc.org/sites/default/files/SUCCESS_Testing_Low_Cost.pdf"
  ),
  "Montana 10" = list(
    long_name="Montana 10 Student Support Program",
    description="Montana 10 was a multifaceted student support program designed by Montana's Office of the Commissioner of Higher Education, providing financial support, advising, tutoring, full-time enrollment promotion, and success courses over two to four years.",
    length="2-4 years", sites="5", students="1,459",
    female="62", black="1", hispanic="3", white="73", under25="80",
    financial="Yes", advising="Yes", ft_summer="Yes", tutoring="Yes", instructional="No", learning_comm="No", success_course="Yes",
    impl="Implementation of Montana 10 components varied across the five colleges in the first year. Some components were implemented with higher fidelity than others.",
    impact="In the first year of the program, there were no detectable effects on student academic outcomes. Students in both the program group and control group had similar enrollment and credit patterns.",
    reports="Montana 10 Early Findings Brief (Nov 2025)|||https://nocache.mdrc.org/sites/default/files/Montana_10_SS_Program.pdf"
  ),
  "MMA" = list(
    long_name="Multiple Measures Assessment and Placement",
    description="MMA replaced traditional standardized placement testing with a placement system that incorporated high school GPA and other academic measures, placing more students directly into college-level courses rather than developmental education.",
    length="1 year", sites="5", students="3,411",
    female="55", black="15", hispanic="10", white="49", under25="68",
    financial="No", advising="No", ft_summer="No", tutoring="No", instructional="Yes", learning_comm="No", success_course="No",
    impl="About 15 percent of all entering students were placed into an alternative (higher) course level as a result of MMA. Implementation was generally strong across sites.",
    impact="Students in the bump-up zone placed into college-level English were 16 percentage points more likely to complete the gateway course. The direct cost of MMA was approximately $33 per student.",
    reports="Increasing Gatekeeper Course Completion - Final Report (Dec 2021)|||https://www.mdrc.org/sites/default/files/MMA_Final_Report.pdf"
  ),
  "Academic Plan" = list(
    long_name="Scaling Academic Planning",
    description="Guaranteed access to either a group workshop or one-on-one academic counseling session to help students prepare an academic plan, along with electronic reminders to attend.",
    length="0.5 years", sites="1", students="1,839",
    female="48", black="1", hispanic="12", white="0", under25="89",
    financial="No", advising="Yes", ft_summer="No", tutoring="No", instructional="No", learning_comm="No", success_course="No",
    impl="The enhanced system was implemented as intended. Nudges were successfully delivered and counseling workshops were conducted according to plan.",
    impact="Both interventions increased academic plan completion rates by more than 20 percentage points over the control group.",
    reports="Final report|||https://www.mdrc.org/work/publications/scaling-academic-planning"
  )
)

# ============================================================
# INFO SHEET BUILDER
# ============================================================
make_info_sheet <- function(college_row) {
  college_name  <- college_row$name
  college_state <- college_row$state
  programs <- trimws(strsplit(college_row$rcts, ",")[[1]])

  yesno <- function(val) {
    if (!is.null(val) && val == "Yes")
      "<span style='background:#d4edda;color:#155724;padding:2px 8px;border-radius:3px;font-size:11px;font-weight:700;'>Yes</span>"
    else
      "<span style='background:#f8d7da;color:#721c24;padding:2px 8px;border-radius:3px;font-size:11px;font-weight:700;'>No</span>"
  }

  bar_row <- function(label, pct, color) {
    pct_clean <- min(as.numeric(pct), 100)
    paste0(
      "<div style='margin-bottom:5px;'>",
      "<div style='display:flex;justify-content:space-between;font-size:11px;color:#555;margin-bottom:2px;'>",
      "<span>", label, "</span><span><b>", pct, "%</b></span></div>",
      "<div style='background:#e8e3d8;border-radius:3px;height:8px;width:100%;'>",
      "<div style='background:", color, ";height:8px;border-radius:3px;width:", pct_clean, "%;'></div>",
      "</div></div>"
    )
  }

  program_blocks <- sapply(programs, function(prog) {
    info <- rct_info[[prog]]
    if (is.null(info)) {
      return(paste0(
        "<div style='background:white;margin:16px;border-radius:6px;padding:16px;",
        "box-shadow:0 2px 8px rgba(0,0,0,0.07);'>",
        "<b>", prog, "</b><p>Details not available.</p></div>"
      ))
    }

    female_n   <- as.numeric(info$female)
    male_n     <- max(0, 100 - female_n)
    black_n    <- as.numeric(info$black)
    hispanic_n <- as.numeric(info$hispanic)
    white_n    <- as.numeric(info$white)
    other_n    <- max(0, 100 - black_n - hispanic_n - white_n)
    under25_n  <- as.numeric(info$under25)
    over25_n   <- max(0, 100 - under25_n)

    charts <- paste0(
      "<div style='display:flex;gap:0;border-bottom:1px solid #eee;background:#fafafa;'>",
      "<div style='flex:1;padding:12px 14px;border-right:1px solid #eee;'>",
      "<div style='font-size:10px;text-transform:uppercase;letter-spacing:1px;color:#c8a951;font-weight:700;margin-bottom:8px;'>Gender</div>",
      bar_row("Female", female_n, "#c8a951"),
      bar_row("Male",   male_n,   "#1a3a5c"),
      "</div>",
      "<div style='flex:2;padding:12px 14px;border-right:1px solid #eee;'>",
      "<div style='font-size:10px;text-transform:uppercase;letter-spacing:1px;color:#c8a951;font-weight:700;margin-bottom:8px;'>Race / Ethnicity</div>",
      bar_row("Black",    black_n,    "#1a3a5c"),
      bar_row("Hispanic", hispanic_n, "#c8a951"),
      bar_row("White",    white_n,    "#4a7fa5"),
      bar_row("Other",    other_n,    "#a0b8cc"),
      "</div>",
      "<div style='flex:1;padding:12px 14px;'>",
      "<div style='font-size:10px;text-transform:uppercase;letter-spacing:1px;color:#c8a951;font-weight:700;margin-bottom:8px;'>Age</div>",
      bar_row("Under 25",    under25_n, "#c8a951"),
      bar_row("25 or older", over25_n,  "#1a3a5c"),
      "</div></div>"
    )

    paste0(
      "<div style='background:white;margin:16px;border-radius:6px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.07);'>",
      "<div style='background:#f0ebe0;padding:14px 18px 10px;border-bottom:3px solid #c8a951;'>",
      "<div style='font-family:Georgia,serif;font-size:16px;font-weight:700;color:#1a3a5c;'>", prog, "</div>",
      "<div style='font-size:12px;color:#666;margin-top:2px;'>", info$long_name, "</div>",
      "</div>",
      "<p style='padding:12px 18px 0;font-size:13px;color:#444;line-height:1.6;margin:0;'>", info$description, "</p>",
      "<div style='display:flex;gap:0;padding:14px 18px 10px;border-bottom:1px solid #eee;'>",
      "<div style='flex:1;text-align:center;'>",
      "<div style='font-family:Georgia,serif;font-size:18px;font-weight:700;color:#1a3a5c;'>", info$students, "</div>",
      "<div style='font-size:10px;text-transform:uppercase;color:#999;letter-spacing:1px;'>Students</div></div>",
      "<div style='flex:1;text-align:center;'>",
      "<div style='font-family:Georgia,serif;font-size:18px;font-weight:700;color:#1a3a5c;'>", info$sites, "</div>",
      "<div style='font-size:10px;text-transform:uppercase;color:#999;letter-spacing:1px;'>Sites</div></div>",
      "<div style='flex:1;text-align:center;'>",
      "<div style='font-family:Georgia,serif;font-size:18px;font-weight:700;color:#1a3a5c;'>", info$length, "</div>",
      "<div style='font-size:10px;text-transform:uppercase;color:#999;letter-spacing:1px;'>Duration</div></div>",
      "</div>",
      charts,
      "<div style='padding:10px 18px 14px;border-bottom:1px solid #eee;'>",
      "<div style='font-size:10px;text-transform:uppercase;letter-spacing:1px;color:#c8a951;font-weight:700;margin-bottom:8px;'>Program Components</div>",
      "<div style='display:flex;flex-wrap:wrap;gap:6px;'>",
      "<div style='font-size:12px;color:#555;min-width:180px;'><span style='color:#1a3a5c;font-weight:700;'>Financial Support:</span> ", yesno(info$financial), "</div>",
      "<div style='font-size:12px;color:#555;min-width:180px;'><span style='color:#1a3a5c;font-weight:700;'>Advising:</span> ", yesno(info$advising), "</div>",
      "<div style='font-size:12px;color:#555;min-width:180px;'><span style='color:#1a3a5c;font-weight:700;'>FT / Summer Enrollment:</span> ", yesno(info$ft_summer), "</div>",
      "<div style='font-size:12px;color:#555;min-width:180px;'><span style='color:#1a3a5c;font-weight:700;'>Tutoring:</span> ", yesno(info$tutoring), "</div>",
      "<div style='font-size:12px;color:#555;min-width:180px;'><span style='color:#1a3a5c;font-weight:700;'>Instructional Reform:</span> ", yesno(info$instructional), "</div>",
      "<div style='font-size:12px;color:#555;min-width:180px;'><span style='color:#1a3a5c;font-weight:700;'>Learning Communities:</span> ", yesno(info$learning_comm), "</div>",
      "<div style='font-size:12px;color:#555;min-width:180px;'><span style='color:#1a3a5c;font-weight:700;'>Success Courses:</span> ", yesno(info$success_course), "</div>",
      "</div></div>",
      "<div style='padding:12px 18px;'>",
      "<div style='font-size:10px;text-transform:uppercase;letter-spacing:1px;color:#c8a951;font-weight:700;margin-bottom:3px;'>Implementation</div>",
      "<div style='font-size:12px;color:#444;line-height:1.6;margin-bottom:10px;'>", info$impl, "</div>",
      "<div style='font-size:10px;text-transform:uppercase;letter-spacing:1px;color:#c8a951;font-weight:700;margin-bottom:3px;'>Impact Findings</div>",
      "<div style='font-size:12px;color:#444;line-height:1.6;'>", info$impact, "</div>",
      "</div>",
      
      "</div>"
    )
  })

  paste0(
    "<div style='padding:0;'>",
    "<div style='background:#1a3a5c;color:white;padding:24px 28px 20px;'>",
    "<div style='display:inline-block;background:#c8a951;color:#1a3a5c;font-size:10px;font-weight:700;",
    "text-transform:uppercase;letter-spacing:1px;padding:2px 8px;border-radius:3px;margin-bottom:10px;'>MDRC Research Site</div>",
    "<div style='font-family:Georgia,serif;font-size:24px;margin:0 0 4px;'>", college_name, "</div>",
    "<div style='color:#b0c4d8;font-size:14px;text-transform:uppercase;letter-spacing:2px;'>", college_state, "</div>",
    "<div style='color:#c8a951;font-size:12px;margin-top:6px;'>&#x1F4CD; IPEDS Locale: ", college_row$ipeds_locale, " &nbsp;|&nbsp; ", college_row$urbanicity, "</div>",
    "</div>",
    "<div style='background:#c8a951;color:#1a3a5c;font-size:11px;font-weight:700;",
    "text-transform:uppercase;letter-spacing:1px;padding:8px 28px;'>",
    "Study Programs (", length(programs), ")</div>",
    paste(program_blocks, collapse = ""),
    "</div>"
  )
}

# ============================================================
# CSS
# ============================================================
custom_css <- "
  @import url('https://fonts.googleapis.com/css2?family=Merriweather:wght@400;700&family=Source+Sans+3:wght@400;600&display=swap');
  body { background:#f4f1ec; font-family:'Source Sans 3',sans-serif; color:#2c2c2c; }
  .main-header { background:#1a3a5c; color:white; padding:18px 28px; border-bottom:4px solid #c8a951; }
  .main-header h2 { font-family:'Merriweather',serif; font-size:22px; margin:0; }
  .main-header p { margin:4px 0 0; font-size:13px; color:#b0c4d8; }
  .sidebar-panel { background:#fff; padding:20px; box-shadow:2px 0 6px rgba(0,0,0,0.05); height:100%; }
  .filter-label { font-family:'Merriweather',serif; font-size:12px; font-weight:700; color:#1a3a5c;
    text-transform:uppercase; letter-spacing:1px; margin:14px 0 6px; }
  .stat-box { background:#1a3a5c; border-radius:6px; padding:12px 16px; margin:16px 0; text-align:center; }
  .stat-number { font-family:'Merriweather',serif; font-size:32px; font-weight:700; color:#c8a951; display:block; }
  .stat-label { font-size:11px; text-transform:uppercase; letter-spacing:1px; color:#b0c4d8; }
  .map-container { border:2px solid #1a3a5c; border-radius:4px; overflow:hidden; box-shadow:0 4px 16px rgba(0,0,0,0.12); }
  .section-title { font-family:'Merriweather',serif; font-size:14px; color:#1a3a5c;
    border-bottom:2px solid #c8a951; padding-bottom:6px; margin:20px 0 12px; }
  select.form-control { border:1px solid #c0c8d0; border-radius:4px; font-size:13px; background:#fafafa; }
  .divider { border:none; border-top:1px solid #e0dbd0; margin:16px 0; }
  .mdrc-badge { display:inline-block; background:#c8a951; color:#1a3a5c; font-size:10px; font-weight:700;
    text-transform:uppercase; letter-spacing:1px; padding:2px 8px; border-radius:3px; margin-bottom:12px; }
  .hint-text { font-size:12px; color:#888; line-height:1.5; margin-top:8px; }
  .checkbox label { font-size:13px; color:#444; }
  .checkbox { margin-top:2px; margin-bottom:2px; }
  .modal-dialog { max-width:780px; }
  .modal-content { border:none; border-radius:6px; overflow:hidden; }
  .modal-header { background:#1a3a5c; border:none; padding:8px 16px; }
  .modal-body { padding:0; max-height:75vh; overflow-y:auto; background:#f4f1ec; }
  .modal-footer { background:#f4f1ec; border-top:1px solid #ddd; }
"

# ============================================================
# UI
# ============================================================
ui <- tagList(
  fluidPage(
    tags$head(tags$style(HTML(custom_css))),

    div(class = "main-header",
      h2("MDRC Postsecondary RCT Study Locations"),
      p("Interactive map of U.S. colleges and universities included in MDRC randomized controlled trials")
    ),

    br(),

    fluidRow(
      column(3,
        div(class = "sidebar-panel",
        div(class = "sidebar-inner",
          span(class = "mdrc-badge", "MDRC Research"),
          div(class = "stat-box",
            span(class = "stat-number", textOutput("college_count", inline = TRUE)),
            span(class = "stat-label", "Institutions Shown")
          ),
          hr(class = "divider"),

          div(class = "filter-label", "Filter by State"),
          selectInput("state_filter", label = NULL,
            choices = c("All States", sort(unique(colleges$state))),
            selected = "All States"),

          div(class = "filter-label", "Filter by Study Program"),
          selectInput("program_filter", label = NULL,
            choices = c("All Programs", all_programs),
            selected = "All Programs"),

          div(class = "filter-label", "Filter by Degree Level"),
          selectInput("degree_filter", label = NULL,
            choices = c("All Degree Levels", "Associate's", "Bachelor's"),
            selected = "All Degree Levels"),

          div(class = "filter-label", "Filter by Urbanicity"),
          selectInput("urbanicity_filter", label = NULL,
            choices = c("All Settings", "Urban", "Suburban", "Town", "Rural"),
            selected = "All Settings"),

          div(class = "filter-label", "Filter by Program Components"),
          checkboxInput("f_financial",    "Financial Support",              value = FALSE),
          checkboxInput("f_advising",     "Advising",                       value = FALSE),
          checkboxInput("f_ft_summer",    "FT / Summer Enrollment",         value = FALSE),
          checkboxInput("f_tutoring",     "Tutoring",                       value = FALSE),
          checkboxInput("f_instructional","Instructional Reform",            value = FALSE),
          checkboxInput("f_learning",     "Learning Communities",            value = FALSE),
          checkboxInput("f_success",      "Success Courses",                 value = FALSE),

          hr(class = "divider"),
          actionButton("reset_filters", "Reset All Filters",
            style = paste0("width:100%;background:#f0ebe0;color:#1a3a5c;",
                           "border:1px solid #c8a951;font-size:12px;font-weight:700;",
                           "text-transform:uppercase;letter-spacing:1px;")),
          hr(class = "divider"),
          p(class = "hint-text",
            "Click any marker to open a full institution profile including study descriptions, demographics, and findings.")
        )
        )
      ),

      column(9,
        div(style = "position:relative;",
          div(class = "map-container",
            leafletOutput("map", height = "540px")
          ),
          div(style = paste0(
            "position:absolute;bottom:18px;left:50%;transform:translateX(-50%);",
            "background:rgba(26,58,92,0.88);color:white;padding:7px 18px;",
            "border-radius:20px;font-size:12px;letter-spacing:0.5px;",
            "pointer-events:none;z-index:999;border:1px solid #c8a951;"
          ), HTML("&#x1F4CD; Click any marker to view full institution profile"))
        ),
        div(class = "section-title", "Institutions Currently Displayed — click a row to fly to that college"),
        DT::dataTableOutput("college_table")
      )
    ),

    # Modal
    tags$div(class = "modal fade", id = "infoModal", tabindex = "-1",
      tags$div(class = "modal-dialog",
        tags$div(class = "modal-content",
          tags$div(class = "modal-header",
            tags$button(type = "button", class = "close", `data-dismiss` = "modal",
              tags$span(style = "color:white;font-size:24px;", HTML("&times;")))
          ),
          tags$div(class = "modal-body", uiOutput("info_sheet")),
          tags$div(class = "modal-footer",
            tags$button(type = "button", class = "btn btn-secondary",
                        `data-dismiss` = "modal", "Close"))
        )
      )
    ),
    tags$div(style = paste0(
      "text-align:center;padding:14px;margin-top:8px;",
      "font-size:11px;color:#999;font-family:'Source Sans 3',sans-serif;",
      "border-top:1px solid #e0dbd0;letter-spacing:0.5px;"
    ), HTML("Developed by <b style='color:#1a3a5c;'>Benjamin Weiss</b> &nbsp;&middot;&nbsp; 2026"))
  ),
  tags$script(HTML("
    Shiny.addCustomMessageHandler('showModal', function(msg) {
      $('#infoModal').modal('show');
    });


  "))
)

# ============================================================
# SERVER
# ============================================================
server <- function(input, output, session) {

  filtered_colleges <- reactive({
    data <- colleges
    if (input$state_filter   != "All States")     data <- data %>% filter(state  == input$state_filter)
    if (input$program_filter != "All Programs")   data <- data %>% filter(grepl(input$program_filter, rcts, fixed = TRUE))
    if (input$degree_filter  != "All Degree Levels") data <- data %>% filter(degree == input$degree_filter)
    if (input$urbanicity_filter != "All Settings") data <- data %>% filter(urbanicity == input$urbanicity_filter)
    if (input$f_financial)    data <- data %>% filter(comp_financial    == TRUE)
    if (input$f_advising)     data <- data %>% filter(comp_advising     == TRUE)
    if (input$f_ft_summer)    data <- data %>% filter(comp_ft_summer    == TRUE)
    if (input$f_tutoring)     data <- data %>% filter(comp_tutoring     == TRUE)
    if (input$f_instructional)data <- data %>% filter(comp_instructional== TRUE)
    if (input$f_learning)     data <- data %>% filter(comp_learning_comm== TRUE)
    if (input$f_success)      data <- data %>% filter(comp_success_course==TRUE)
    data
  })

  observeEvent(input$reset_filters, {
    updateSelectInput(session, "state_filter",   selected = "All States")
    updateSelectInput(session, "program_filter", selected = "All Programs")
    updateSelectInput(session, "degree_filter",  selected = "All Degree Levels")
    updateSelectInput(session, "urbanicity_filter", selected = "All Settings")
    updateCheckboxInput(session, "f_financial",    value = FALSE)
    updateCheckboxInput(session, "f_advising",     value = FALSE)
    updateCheckboxInput(session, "f_ft_summer",    value = FALSE)
    updateCheckboxInput(session, "f_tutoring",     value = FALSE)
    updateCheckboxInput(session, "f_instructional",value = FALSE)
    updateCheckboxInput(session, "f_learning",     value = FALSE)
    updateCheckboxInput(session, "f_success",      value = FALSE)
  })

  output$college_count <- renderText({ nrow(filtered_colleges()) })

  # Fix 5: Define color palette ONCE outside observe so it is not recreated on every zoom/filter change
  pal <- colorFactor(
    palette = c("#1a3a5c", "#c8a951", "#2d7a3a", "#9b3030"),
    levels  = c("Urban", "Suburban", "Town", "Rural")
  )

  # Fix 1: Define selected_college BEFORE it is used in map_click handler
  selected_college <- reactiveVal(NULL)

  output$map <- renderLeaflet({
    leaflet(options = leafletOptions(minZoom = 4, maxZoom = 14)) %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      setView(lng = -96, lat = 38, zoom = 4) %>%
      setMaxBounds(lng1 = -125, lat1 = 24, lng2 = -66, lat2 = 50) %>%
      addLegend(
        position = "bottomright",
        colors   = c("#1a3a5c","#c8a951","#2d7a3a","#9b3030"),
        labels   = c("Urban","Suburban","Town","Rural"),
        title    = "Urbanicity (IPEDS)",
        opacity  = 0.9
      )
  })

  observe({
    data <- filtered_colleges()
    zoom <- input$map_zoom
    dot_radius <- if (is.null(zoom)) 5 else {
      if (zoom <= 4) 4
      else if (zoom <= 5) 6
      else if (zoom <= 6) 9
      else if (zoom <= 7) 14
      else if (zoom <= 8) 16
      else if (zoom <= 9) 13
      else if (zoom <= 11) 10
      else 7
    }

    # Fix 4: Show message if no colleges match filters
    if (nrow(data) == 0) {
      leafletProxy("map") %>% clearGroup("colleges")
      return()
    }

    leafletProxy("map", data = data) %>%
      clearGroup("colleges") %>%
      addCircleMarkers(
        lng = ~lng, lat = ~lat,
        radius = dot_radius,
        color = "#ffffff",
        fillColor = ~pal(urbanicity),
        fillOpacity = 0.9,
        weight = 1.5,
        layerId = ~name,
        group = "colleges",
        label = ~paste0(name, " (", urbanicity, ")"),
        labelOptions = labelOptions(
          style = list("font-size" = "13px", "border-color" = "#1a3a5c")
        )
      )
  })

  # Fix 2: Single combined marker click handler (no duplicate)
  # Fix 3: Use a flag to distinguish marker vs background clicks
  marker_just_clicked <- reactiveVal(FALSE)

  observeEvent(input$map_marker_click, {
    marker_just_clicked(TRUE)
    clicked <- input$map_marker_click$id
    if (!is.null(clicked)) {
      row <- colleges %>% filter(name == clicked)
      if (nrow(row) > 0) {
        output$info_sheet <- renderUI({ HTML(make_info_sheet(row[1, ])) })
        session$sendCustomMessage("showModal", list())
      }
    }
  })

  # Only zoom back to US when clicking map background (not a dot)
  observeEvent(input$map_click, {
    if (marker_just_clicked()) {
      marker_just_clicked(FALSE)
    } else {
      selected_college(NULL)
      leafletProxy("map") %>%
        clearGroup("highlight") %>%
        setView(lng = -96, lat = 38, zoom = 4)
      # Also deselect the table row
      DT::dataTableProxy("college_table") %>% DT::selectRows(NULL)
    }
  }, ignoreInit = TRUE)

  output$college_table <- DT::renderDataTable({
    df <- filtered_colleges() %>%
      select("Institution" = name, "State" = state, "Urbanicity" = urbanicity,
             "IPEDS Locale" = ipeds_locale, "Study Programs" = rcts)

    # Fix 4: Show empty state message in table
    DT::datatable(
      df,
      selection = list(mode = "single", selected = NULL, target = "row", selectable = TRUE),
      rownames  = FALSE,
      options   = list(
        pageLength = 10,
        dom        = "ftipr",
        language   = list(zeroRecords = "No institutions match the current filters. Try resetting your filters."),
        columnDefs = list(list(width = "35%", targets = 4))
      ),
      class = "hover stripe compact"
    )
  })

  draw_ring <- function(row) {
    if (is.null(row)) return()
    zoom <- input$map_zoom
    ring_radius <- if (is.null(zoom)) 18 else {
      if (zoom <= 4) 10
      else if (zoom <= 5) 12
      else if (zoom <= 6) 16
      else if (zoom <= 7) 22
      else if (zoom <= 8) 28
      else if (zoom <= 9) 24
      else if (zoom <= 11) 20
      else 16
    }
    leafletProxy("map") %>%
      clearGroup("highlight") %>%
      addCircleMarkers(
        lng         = row$lng,
        lat         = row$lat,
        radius      = ring_radius,
        color       = "#ff4444",
        fillColor   = "transparent",
        fillOpacity = 0,
        weight      = 3,
        group       = "highlight",
        options     = pathOptions(interactive = FALSE)
      )
  }

  # When a table row is clicked, fly to college and highlight it
  observeEvent(input$college_table_rows_selected, {
    idx <- input$college_table_rows_selected
    if (!is.null(idx)) {
      row <- filtered_colleges()[idx, ]
      selected_college(row)
      leafletProxy("map") %>%
        setView(lng = row$lng, lat = row$lat, zoom = 11)
      draw_ring(row)
    }
  })

  # Redraw ring after markers are redrawn on zoom change
  observeEvent(input$map_zoom, {
    draw_ring(selected_college())
  }, ignoreInit = TRUE)
}

shinyApp(ui = ui, server = server)

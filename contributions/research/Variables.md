# Explanations of Variables in the dataset

|variable name|explanation|type|
|:-----------|------------|----|
|bula_3rd | Bundesland during third grade | categorical
| year_3rd | Year when third grade was done | categorical
| treat | among treated cohorts | bool
right | ? | bool
nomiss | ? | bool
only_parents | ? | bool
target | target individual (relevant for study) | bool
cityno | municipality (Landkreise possibly) | categorical
kommheard | aware of voucher initiative | bool
kommgotten | got the voucher | bool
kommused | used the voucher | bool
sportsclub | member of sports club at time of survey | bool
sport_hrs | hours of sport per week |categorical
oweight | signals if person is overweight | bool
sport1hrs | person does more than 1 hour of sports per week | bool
sport2hrs | person does more than 2 hours of sports per week | bool
sport3hrs | person does more than 3 hours of sports per week | bool
sport_alt2 | 
health1 | person in very good health | bool
obese | person is obese | bool
eversmoked | did person ever smoke | bool
currentsmoking | is person a current smoker | bool
everalc | did person ever drink alcohol | bool
alclast7 | did person drink alcohol in last 7 days | bool
**female** | gender of person | bool
siblings | person has sibling(s) | bool
**born_germany** | person is born in Germany | bool
**parent_nongermany** | parents are not from Germany | bool
newspaper | family has newspaper at home (proxy for socioeconomic status) | bool
art_at_home | family has art at home (proxy for socioeconomic status) | bool
academictrack | (Person in Gymnasium) | bool
**sportsclub_4_7** | in sports club between ages 4 and 7 | bool
**music_4_7** | took music lessons between ages 4 and 7 | bool
**urban** | lives in city | bool
**yob** | year of birth | categorical
**mob** | month of birth | categorical
sib_part | ?
anz_osiblings | (number of other siblings) | categorical
age | age at survey | categorical
favsport | favourite type of sports | categorical 
LL_sport5-LL_sports12 | in sports club at age 5(-12) | bool
deutsch | ?
inschool | person was in school during survey | bool
sport | ?
mussp | ?
musunt | ?
fz_{....} | ?
es_ich{1-17} | ?
es_{...} | ?
**abi_p** | parents have Abitur | bool
**real_p** | parents have Realschulabschluss | bool
**haupt_p** | parents have Hauptschulabschluss | bool
**age_p** | (average) age of parents | categorical
memsport_p | parents are part of sports club | bool
sport1_p - sport11_p* | questionaire for parents regarding sports | categorical (scale from 1 (totally disagree) to 7 (totally agree))


*(1) Exercising is something that I do regularly. (2)
Exercising is something that I do automatically. (3) Exercising is something that I do without
explicitly reminding myself. (4) Exercising is something that I feel I need if I don’t do it. (5)
Exercising is something that I do without thinking about it. (6) Exercising is something that
would be exhausting for me not to do. (7) Exercising is something that is part of my weekly
routine. (8) Exercising is something that would be difficult for me not to do. (9) Exercising
is something that I do without the need to think about it. (10) Exercising is something that is
typical for me. (11) Exercising is something that I have been doing for a long time.


# Variables used for Estimation of Propensity Scores

|variable name|explanation|type|
|:-----------|------------|----|
**born_germany** | person is born in Germany | bool
**parent_nongermany** | parents are not from Germany | bool
**female** | gender of person | bool
**sportsclub_4_7** | in sports club between ages 4 and 7 | bool
**music_4_7** | took music lessons between ages 4 and 7 | bool
**urban** | lives in city | bool
**yob** | year of birth | categorical
**abi_p** | parents have Abitur | bool
**real_p** | parents have Realschulabschluss | bool
**haupt_p** | parents have Hauptschulabschluss | bool
**anz_osiblings** | (number of other siblings) | categorical
**[interaction terms]** | interaction between variables | float
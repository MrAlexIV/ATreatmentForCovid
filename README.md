# CODOProject, A Treatment For Covid
The following project leverages the CODO ontology, downloadable at the following link https://bioportal.bioontology.org/ontologies/CODO , to provide treatment for a patient suffering from COVID. First and foremost, an attempt is made to determine whether the patient has a high probability of having COVID, utilizing Bayesian rules based on the number of symptoms and the patient's contacts with infected individuals (distinguishing between close and non-close contacts). If this probability exceeds a certain threshold, a recommended treatment plan is proposed for the patient, involving the identification of the most suitable medication, the appropriate dosage in milligrams, and the recommended duration in days. The treatment plan takes into account any allergies the patient may have and any traumas resulting from previous illnesses that may prevent the use of certain medications.

If you wanna test the project, open SWI-prolog and consult esame.pl
Use the main rule suggerisci_trattamento('http://www.isibang.ac.in/ns/codo#p000004').
Not all the patients in the ontology have all the istances , so with some of them it won't work, you can add and change it. 
The whole file is a mix of Italian and English, if you are interested, I'll make it full english.

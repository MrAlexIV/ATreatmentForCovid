:- consult(codologia).
:- use_module(library(clpfd)).


location_patient(Patient,Loc):-
				findall(Locazione,propertyAssertion('http://www.isibang.ac.in/ns/codo#hasLocation',Patient,Locazione),Loc).
% a differenza di loc influenzale, questa tiene conto della pericolosità generale della location per avere covid
% la loc influenzale, serve per PB, questa per PA
% PA dunque vede loc pericolose, ciè in quella città circola covid
% PB vede se in quella città circola influenza, dunque prob di beccare sintomi
location_pericolosa(Patient,L1):-
	location_patient(Patient,L),
 verifica_loc(Patient,L,L1).

verifica_loc(Patient,[], []). 

verifica_loc(Patient,[Testa|Coda], ListaRisultato) :-
    	propertyAssertion('http://www.isibang.ac.in/ns/codo#isDangerous',Testa,literal(type('http://www.w3.org/2001/XMLSchema#boolean',true))),

    verifica_loc(Patient,Coda, ListaRisultatoCoda), % Continua a controllare la coda della lista
    ListaRisultato = [Testa | ListaRisultatoCoda]. % Aggiungi Testa alla lista risultato

verifica_loc(Patient,[_|Coda], ListaRisultato) :-
    verifica_loc(Patient,Coda, ListaRisultato). 
	
verifica_loc_influenzale(Patient,[], []). 

verifica_loc_influenzale(Patient,[Testa|Coda], ListaRisultato) :-
    	propertyAssertion('http://www.isibang.ac.in/ns/codo#influenzale',Testa,literal(type('http://www.w3.org/2001/XMLSchema#boolean',true))),

    verifica_loc_influenzale(Patient,Coda, ListaRisultatoCoda), % Continua a controllare la coda della lista
    ListaRisultato = [Testa | ListaRisultatoCoda]. % Aggiungi Testa alla lista risultato

verifica_loc_influenzale(Patient,[_|Coda], ListaRisultato) :-
    verifica_loc_influenzale(Patient,Coda, ListaRisultato). 
conta_loc_pericolose(Patient,NL):-
	location_pericolosa(Patient,L1),
		lunghezza_lista(L1,NL).


cerca_sintomi(Patient,List):-
	findall(Symptoms,propertyAssertion('http://www.isibang.ac.in/ns/codo#hasSymptom',Patient,Symptoms),List).
conta_sintomi(Patient,NS):-
	cerca_sintomi(Patient,L),
	lunghezza_lista(L,NS).
	
trova_relazioni(Patient,L1):-
			findall(People,propertyAssertion('http://www.isibang.ac.in/ns/codo#hasRelationship',Patient,People),L1).

verifica_relazioni(Patient,[], []). 

verifica_relazioni(Patient,[Testa|Coda], ListaRisultato) :-
    	propertyAssertion('http://www.isibang.ac.in/ns/codo#hasCovid',Testa,literal(type('http://www.w3.org/2001/XMLSchema#boolean',true))),

    verifica_relazioni(Patient,Coda, ListaRisultatoCoda), % Continua a controllare la coda della lista
    ListaRisultato = [Testa | ListaRisultatoCoda]. % Aggiungi Testa alla lista risultato

verifica_relazioni(Patient,[_|Coda], ListaRisultato) :-
    verifica_relazioni(Patient,Coda, ListaRisultato). 
	
conta_numero_positivi(Patient,NPNS):-
	 trova_relazioni(Patient,L1),
	verifica_relazioni(Patient,L1,Ris),
	lunghezza_lista(Ris,NPNS).
	
trova_relazioni_strette(Patient,L2):-
				findall(People,propertyAssertion('http://www.isibang.ac.in/ns/codo#hasCloseRelationship',Patient,People),L2).

	
conta_numero_positivi_stretti(Patient,NPS):-
	 trova_relazioni_strette(Patient,L2),
	verifica_relazioni(Patient,L2,Ris2),
	lunghezza_lista(Ris2,NPS).


lunghezza_lista([], 0). % La lunghezza di una lista vuota è 0

lunghezza_lista([_|Coda], Lunghezza) :-
    lunghezza_lista(Coda, LunghezzaCoda), 
    Lunghezza is LunghezzaCoda + 1 . 

sintomi_fuzzy(X,Y):-
	( X in 0..0 -> Y is 0.05 ;
	  X in 1..1 -> Y is 0.10 ;
	  X in 2..2 -> Y is 0.35;
	  X >= 3 -> Y is 0.50 ).

contatti_fuzzy(X,Y):-
	( X in 0..0 -> Y is 0.05 ;
	  X in 1..2 -> Y is 0.30 ;
	  X >= 3 -> Y is 0.65 ).

contatti_fuzzy_non(X,Y):-
	( X in 0..0 -> Y is 0.05 ;
	  X in 1..1 -> Y is 0.10 ;
	  X in 2..2 -> Y is 0.40 ;
	  X >= 3 -> Y is 0.45 ).


location_influenzale(Patient,NLI):-
	location_patient(Patient,L),
	verifica_loc_influenzale(Patient,L,LF),
	lunghezza_lista(LF,NLI).
prob_a_priori_sintomi(Patient,PB):-
	location_influenzale(Patient,NLI), % se abiti in zona influenzale, perc magg
	( NLI > 0 -> PB is 0.65;
	 PB is 0.35 ).
	 
% se sei socievole, maggior PC,PD	 
prob_a_priori_contatti(Patient,PX):-
	( propertyAssertion('http://www.isibang.ac.in/ns/codo#socievole',Patient,literal(type('http://www.w3.org/2001/XMLSchema#boolean',true))) -> PX is 0.65;
	   PX is 0.35 ).

	
calcolo_PBA(Patient,PBA):-
	conta_sintomi(Patient,NS),
    sintomi_fuzzy(NS, PAB),
   ottieni_PA(Patient,PA),
	  prob_a_priori_sintomi(Patient,PB),
	  PBA is (PAB * PB) / PA .
	  
calcolo_PCA(Patient,PCA):-
	conta_numero_positivi_stretti(Patient,NPS),
	contatti_fuzzy(NPS, PAC),
   ottieni_PA(Patient,PA),
	  prob_a_priori_contatti(Patient,PX),
	  PCA is (PAC * PX) / PA .
	  
calcolo_PDA(Patient,PDA):-
	conta_numero_positivi(Patient,NPS),
	contatti_fuzzy_non(NPS, PAD),
   ottieni_PA(Patient,PA),
	  prob_a_priori_contatti(Patient,PX),
	  PDA is (PAD * PX) / PA .
calcolo_PBCD(Patient,PBCD):-
		 prob_a_priori_contatti(Patient,PX),
		 prob_a_priori_sintomi(Patient,PB),
		PBCD is PB * PX * PX.
ottieni_PA(Patient,PA):-
	  conta_loc_pericolose(Patient,NL),
    ( NL > 0 -> PA is 0.70;
	   PA is 0.30 ).

calcolo_PBCDA(Patient,PA,PBCDA):-
	 ottieni_PA(Patient,PA),
	calcolo_PBA(Patient,PBA),
	calcolo_PCA(Patient,PCA),
	calcolo_PDA(Patient,PDA),
	PBCDA is PBA * PCA * PDA .

% Inferenza fuzzy basata su regole manuali
prob_avere_covid(Patient, PABCD) :-
	
	 % prob_a_priori_sintomi(Patient,PB),
	 % ottieni_PA(Patient,PA),
	calcolo_PBCDA(Patient,PA,PBCDA),
	calcolo_PBCD(Patient,PBCD),
	PABCD is (PA * PBCDA) / PBCD .
	
/*PARTE 2*/	
	
ha_vaccino(Patient):-
	propertyAssertion('http://www.isibang.ac.in/ns/codo#hasVaccino',Patient,literal(type('http://www.w3.org/2001/XMLSchema#boolean',true))).

trova_dosaggio_mg(Patient,[], []). 

trova_dosaggio_mg(Patient,[Testa|Coda], ListaRisultato) :-
    	propertyAssertion('http://www.isibang.ac.in/ns/codo#dosaggioMg',Testa,Dosi),
    trova_dosaggio_mg(Patient,Coda, ListaRisultatoCoda), % Continua a controllare la coda della lista
    ListaRisultato = [Dosi | ListaRisultatoCoda]. % Aggiungi Testa alla lista risultato

trova_dosaggio_mg(Patient,[_|Coda], ListaRisultato) :-
    trova_dosaggio_mg(Patient,Coda, ListaRisultato). 
	
% Caso base: la lista vuota
modifica_lista([], []).

% Caso ricorsivo: modifica la testa della lista e ricorri sulla coda
modifica_lista([Testa|Coda], [NuovoElemento|NuovaCoda]) :-
    % Modifica l'elemento, ad esempio raddoppiandolo
	dosaggio_Mg_intero3(Testa,NuovoElemento),    % Ricorri sulla coda della lista
    modifica_lista(Coda, NuovaCoda).


trova_dosaggio_giorni(Patient,[], []). 

trova_dosaggio_giorni(Patient,[Testa|Coda], ListaRisultato) :-
    	propertyAssertion('http://www.isibang.ac.in/ns/codo#dosaggioGiorni',Testa,Dosi),
    trova_dosaggio_giorni(Patient,Coda, ListaRisultatoCoda), % Continua a controllare la coda della lista
    ListaRisultato = [Dosi | ListaRisultatoCoda]. % Aggiungi Testa alla lista risultato

trova_dosaggio_giorni(Patient,[_|Coda], ListaRisultato) :-
    trova_dosaggio_giorni(Patient,Coda, ListaRisultato). 
	
% Caso base: la lista vuota
modifica_lista1([], []).

% Caso ricorsivo: modifica la testa della lista e ricorri sulla coda
modifica_lista1([Testa|Coda], [NuovoElemento|NuovaCoda]) :-
    % Modifica l'elemento, ad esempio raddoppiandolo
	dosaggio_giorni_intero3(Testa,NuovoElemento),    % Ricorri sulla coda della lista
    modifica_lista1(Coda, NuovaCoda).	
	
% Caso base: la lista vuota
modifica_lista_dosi([], []).

% Caso ricorsivo: modifica la testa della lista e ricorri sulla coda
modifica_lista_dosi([Testa|Coda], [NuovoElemento|NuovaCoda]) :-
    % Modifica l'elemento, ad esempio raddoppiandolo
    NuovoElemento is Testa / 2,
    % Ricorri sulla coda della lista
    modifica_lista_dosi(Coda, NuovaCoda).

ottieni_dosaggio_mg(Patient,F,DosiMg):-	
	% cerca_farmaci(Patient,F),
	trova_dosaggio_mg(Patient,F,D1),
	modifica_lista(D1,DosiMg).
ottieni_dosaggio_giorni(Patient,F,DosiGiorni):-
	% cerca_farmaci(Patient,F),
	trova_dosaggio_giorni(Patient,F,D2),
	modifica_lista1(D2,DosiGiorni).
stima_dosi(Patient,DosiMg,DosiGiorni,F):-
	calcolo_bmi(Patient,B),
	cerca_farmaci(Patient,F),
	B > 20,
    % trova_dosaggio_mg(Patient,F,D1),
	% modifica_lista(D1,DM),
	ottieni_dosaggio_mg(Patient,DosiMg),
	
	 % trova_dosaggio_giorni(Patient,F,D2),
	% modifica_lista1(D2,DG).
	ottieni_dosaggio_giorni(Patient,DosiGiorni).
stima_dosi(Patient,DM1,DosiGiorni,F):-
	calcolo_bmi(Patient,B),
	cerca_farmaci(Patient,F),
	B < 20,
    % trova_dosaggio_mg(Patient,F,D1),
	% modifica_lista(D1,DM), 
	ottieni_dosaggio_mg(Patient,DosiMg),
	modifica_lista_dosi(DosiMg,DM1),
	 % trova_dosaggio_giorni(Patient,F,D2),
	% modifica_lista1(D2,DG).
	ottieni_dosaggio_giorni(Patient,DosiGiorni).
	
stima_dosi_farmaco(Patient,F,DosiMg,DosiGiorni):-
	calcolo_bmi(Patient,B),
	% cerca_farmaci(Patient,F),
	B > 20,
    % trova_dosaggio_mg(Patient,F,D1),
	% modifica_lista(D1,DM),
	ottieni_dosaggio_mg(Patient,F,DosiMg),
	
	 % trova_dosaggio_giorni(Patient,F,D2),
	% modifica_lista1(D2,DG).
	ottieni_dosaggio_giorni(Patient,F,DosiGiorni).
stima_dosi_farmaco(Patient,F,DM1,DosiGiorni):-
	calcolo_bmi(Patient,B),
	% cerca_farmaci(Patient,F),
	B < 20,
    % trova_dosaggio_mg(Patient,F,D1),
	% modifica_lista(D1,DM), 
	ottieni_dosaggio_mg(Patient,F,DosiMg),
	modifica_lista_dosi(DosiMg,DM1),
	 % trova_dosaggio_giorni(Patient,F,D2),
	% modifica_lista1(D2,DG).
	ottieni_dosaggio_giorni(Patient,F,DosiGiorni).
	
hai_febbre(Patient):-
	cerca_sintomi(Patient,List),
	member('http://www.isibang.ac.in/ns/codo#Fever',List).
	
ottieni_priorita(Patient,[], []). 

ottieni_priorita(Patient,[Testa|Coda], ListaRisultato) :-
   propertyAssertion('http://www.isibang.ac.in/ns/codo#priority',Testa,Priorita),
    ottieni_priorita(Patient,Coda, ListaRisultatoCoda), % Continua a controllare la coda della lista
    ListaRisultato = [Priorita | ListaRisultatoCoda]. % Aggiungi Testa alla lista risultato

ottieni_priorita(Patient,[_|Coda], ListaRisultato) :-
    ottieni_priorita(Patient,Coda, ListaRisultato). 
	
modifica_lista_priorita([], []).

% Caso ricorsivo: modifica la testa della lista e ricorri sulla coda
modifica_lista_priorita([Testa|Coda], [NuovoElemento|NuovaCoda]) :-
    % Modifica l'elemento, ad esempio raddoppiandolo
	ottieni_priorita3(Testa,NuovoElemento),    % Ricorri sulla coda della lista
    modifica_lista_priorita(Coda, NuovaCoda).	
	
ottieni_priorita_intere(Far,Priorita):-
	ottieni_priorita(_,Far,Pr),
	modifica_lista_priorita(Pr,Priorita).
	
% Predicato per creare la lista di coppie priorità-elemento
crea_lista_priorita_elemento(ListaPriorita, ListaElementi, ListaPrioritaElemento) :-
    crea_coppie(ListaPriorita, ListaElementi, ListaPrioritaElemento).

crea_coppie([], [], []).
crea_coppie([P|RestoPriorita], [E|RestoElementi], [P-E|RestoCoppie]) :-
    crea_coppie(RestoPriorita, RestoElementi, RestoCoppie).
	
% Predicato per trovare l'elemento con la priorità più alta
elemento_con_priorita_piu_alta(Lista, Elemento) :-
    massima_priorita(Lista, 0, MaxPriorita),
    member(MaxPriorita-Elemento, Lista).

% Predicato ausiliario per trovare la massima priorità
massima_priorita([], MaxPriorita, MaxPriorita).
massima_priorita([Priorita-_|Resto], Acc, MaxPriorita) :-
    NuovaAcc is max(Acc, Priorita),
    massima_priorita(Resto, NuovaAcc, MaxPriorita).

elementoInLista(Elemento, Lista) :-
    Lista = [Elemento].

% Predicato per trovare l'elemento con la priorità più alta e recuperare gli elementi corrispondenti dalle altre due liste
trova_farmaco_migliore(Patient,Lista1,R) :-
   cerca_farmaci(Patient,Lista1),
	ottieni_priorita_intere(Lista1,ListaPriorita),
	crea_lista_priorita_elemento(ListaPriorita,Lista1,ListaFin),
    elemento_con_priorita_piu_alta(ListaFin, ResultElemento1),
	elementoInLista(ResultElemento1,R).


% Regola per la stampa delle informazioni sul paziente
suggerisci_trattamento(Patient) :-
    % Recupera le liste dal database di fatti
	prob_avere_covid(Patient,P),
	 P > 0.010,
   % stima_dosi(Patient,_,_,Farmaci),
   % cerca_farmaci(Patient,Farmaci),
   % controllo se hai febbre, stampa pure tachipirina
   trova_farmaco_migliore(Patient,Farmaci,Farmaco),
    (hai_febbre(Patient) , \+ member('http://www.isibang.ac.in/ns/codo#Tachipirina',Farmaci), not(propertyAssertion('http://www.isibang.ac.in/ns/codo#isAllergic',Patient,'http://www.isibang.ac.in/ns/codo#Tachipirina')) -> format(" hai anche la febbre, raccomando anche tachipirina dosi 1000mg per 5 giorni ");
	      format(" ") ),
   % stampare(Farmaci, Dosi, DosaggiGiorni).
   
   stima_dosi_farmaco(Patient,Farmaco,Dosi,DosaggiGiorni),
   

    format("Il paziente ha bisogno di farmaco(~w), dosiMg(~w), dosigiorni(~w)~n", [Farmaco, Dosi, DosaggiGiorni]).
	   % stampare(Farmaci).
	/*
suggerisci_trattamenti(Patient) :-
    % Recupera le liste dal database di fatti
	prob_avere_covid(Patient,P),
	P < 0.40,
	format("Il paziente non ha bisogno di trattamenti").*/

% Regola per la stampa effettiva delle informazioni
stampare([]).
stampare([Farmaco|Farmaci]) :-
   ottieni_dosaggio_mg(_,Farmaco,Dose),
   ottieni_dosaggio_giorni(_,Farmaco,DosaggiGiorni),
    format("In alternativa ,il paziente ha bisogno di farmaco(~w), dosiMg(~w), dosigiorni(~w)~n", [Farmaco, Dose, DosaggiGiorni]),
    % Ricorsione con le code delle liste
    stampare(Farmaci).


% Predicato per verificare se un elemento è membro di una lista
member(X, [X|_]).
member(X, [_|T]) :- member(X, T).

% Predicato per creare una lista C con elementi di B non presenti in A
crea_lista_diff(A, [], C) :-
    % Se B è vuota, la lista C sarà vuota
    C = [].
crea_lista_diff(A, [H|T], C) :-
    % Se H non è presente in A, lo aggiungi a C
    (   \+ member(H, A) ->
        C = [H|Resto],
        crea_lista_diff(A, T, Resto)
    ;   % Altrimenti, ignora H e passa al prossimo elemento di B
        crea_lista_diff(A, T, C)
    ). 

verifica_pesante(Patient,[], []). 

verifica_pesante(Patient,[Testa|Coda], ListaRisultato) :-
    	propertyAssertion('http://www.isibang.ac.in/ns/codo#pesante',Testa,literal(type('http://www.w3.org/2001/XMLSchema#boolean',true))),

    verifica_pesante(Patient,Coda, ListaRisultatoCoda), % Continua a controllare la coda della lista
    ListaRisultato = [Testa | ListaRisultatoCoda]. % Aggiungi Testa alla lista risultato

verifica_pesante(Patient,[_|Coda], ListaRisultato) :-
    verifica_pesante(Patient,Coda, ListaRisultato). 

verifica_non_pesante(Patient,[], []). 

verifica_non_pesante(Patient,[Testa|Coda], ListaRisultato) :-
    	propertyAssertion('http://www.isibang.ac.in/ns/codo#pesante',Testa,literal(type('http://www.w3.org/2001/XMLSchema#boolean',false))),

    verifica_non_pesante(Patient,Coda, ListaRisultatoCoda), % Continua a controllare la coda della lista
    ListaRisultato = [Testa | ListaRisultatoCoda]. % Aggiungi Testa alla lista risultato

verifica_non_pesante(Patient,[_|Coda], ListaRisultato) :-
    verifica_non_pesante(Patient,Coda, ListaRisultato). 
	
verifica_bimbo(Patient,[], []). 

verifica_bimbo(Patient,[Testa|Coda], ListaRisultato) :-
    	propertyAssertion('http://www.isibang.ac.in/ns/codo#lowBMI',Testa,literal(type('http://www.w3.org/2001/XMLSchema#boolean',true))),

    verifica_bimbo(Patient,Coda, ListaRisultatoCoda), % Continua a controllare la coda della lista
    ListaRisultato = [Testa | ListaRisultatoCoda]. % Aggiungi Testa alla lista risultato

verifica_bimbo(Patient,[_|Coda], ListaRisultato) :-
    verifica_bimbo(Patient,Coda, ListaRisultato). 
	
verifica_traumi_prob_respiratori(Patient,[], []). 

verifica_traumi_prob_respiratori(Patient,[Testa|Coda], ListaRisultato) :-
    	propertyAssertion('http://www.isibang.ac.in/ns/codo#BreathProblem',Testa,literal(type('http://www.w3.org/2001/XMLSchema#boolean',true))),

    verifica_traumi_prob_respiratori(Patient,Coda, ListaRisultatoCoda), % Continua a controllare la coda della lista
    ListaRisultato = [Testa | ListaRisultatoCoda]. % Aggiungi Testa alla lista risultato

verifica_traumi_prob_respiratori(Patient,[_|Coda], ListaRisultato) :-
    verifica_traumi_prob_respiratori(Patient,Coda, ListaRisultato). 
	
conta_traumi_problemi_resp(Patient,N):-
	trova_traumi(Patient,T),
	verifica_traumi_prob_respiratori(Patient,T,LT),
	lunghezza_lista(LT,N).
	

problemi_respiratori(Patient):-
	conta_traumi_problemi_resp(Patient,N),
	N >= 1 .

estrai_da_pesante(Patient,[], []). 

estrai_da_pesante(Patient,[Testa|Coda], ListaRisultato) :-
    	propertyAssertion('http://www.isibang.ac.in/ns/codo#usefulForBreath',Testa,literal(type('http://www.w3.org/2001/XMLSchema#boolean',true))),

    estrai_da_pesante(Patient,Coda, ListaRisultatoCoda), % Continua a controllare la coda della lista
    ListaRisultato = [Testa | ListaRisultatoCoda]. % Aggiungi Testa alla lista risultato

estrai_da_pesante(Patient,[_|Coda], ListaRisultato) :-
    estrai_da_pesante(Patient,Coda, ListaRisultato). 
	
cerca_farmaci(Patient,FF):-
	cerca_farmaci_senza_allergeni(Patient,F1),
	cerca_farmaci_senza_controindicazioniTraumi(Patient,F1,F),
	rischio_alto(Patient,P,Traumi,E),
	P > 0,
	% E > 18,
	not(problemi_respiratori(Patient)),
	verifica_pesante(Patient,F,FF).
cerca_farmaci(Patient,FFF):-
	cerca_farmaci_senza_allergeni(Patient,F1),
	cerca_farmaci_senza_controindicazioniTraumi(Patient,F1,F),
	rischio_alto(Patient,P,Traumi,E),
	P > 0,
	% E > 18,
	problemi_respiratori(Patient),
	verifica_pesante(Patient,F,FF),
  estrai_da_pesante(Patient,FF,FFF).
cerca_farmaci(Patient,FF):-
	cerca_farmaci_senza_allergeni(Patient,F1),
	cerca_farmaci_senza_controindicazioniTraumi(Patient,F1,F),
	rischio_alto(Patient,P,Traumi,E),
	P < 1,
	E > 13,
	verifica_non_pesante(Patient,F,FF).
cerca_farmaci(Patient,FF):-
	cerca_farmaci_senza_allergeni(Patient,F1),
	cerca_farmaci_senza_controindicazioniTraumi(Patient,F1,F),
	rischio_alto(Patient,P,Traumi,E),
	P < 1,
	E < 13,
     verifica_bimbo(Patient,F,FF).				
at_least_one_element_in_common(List1, List2) :-
    member(Element, List1),
    member(Element, List2).

lista_farmaci_da_scartare([],_,[]).
lista_farmaci_da_scartare([Farmaco|Farmaci],Traumi,[Farmaco | DS]):-
	findall(Dannosi,propertyAssertion('http://www.isibang.ac.in/ns/codo#notGoodWith',Farmaco,Dannosi),LD),
	at_least_one_element_in_common(LD,Traumi),
	lista_farmaci_da_scartare(Farmaci,Traumi,DS).
	
lista_farmaci_da_scartare([_ | Farmaci], Traumi, DS) :-
    lista_farmaci_da_scartare(Farmaci, Traumi, DS).

cerca_farmaci_senza_controindicazioniTraumi(Patient,Farmaci,F):-
	trova_traumi(Patient,T),
	lista_farmaci_da_scartare(Farmaci,T,Ds),
	crea_lista_diff(Ds,Farmaci,F).
	

	
cerca_farmaci_senza_allergeni(Patient,F):-
	lista_farmaci(Farmaci),
	findall(Allergeni,propertyAssertion('http://www.isibang.ac.in/ns/codo#isAllergic',Patient,Allergeni),LA),
     crea_lista_diff(LA,Farmaci,F).

lista_farmaci(Farmaci):-
	findall(Farmaco,classAssertion('http://www.isibang.ac.in/ns/codo#Medicines',Farmaco),Farmaci).

rischio_alto(Patient,P,Traumi,E):-
	conta_traumi(Patient,Traumi),
	eta3(Patient,E),
	% not(ha_vaccino(Patient)),
	(not(ha_vaccino(Patient)) -> P is 1; 
	Traumi >= 1 -> P is 1;
	E > 70 -> P is 1;
	 P is 0 ).
	 /*
rischio_alto(Patient,P,Traumi,E):-
	conta_traumi(Patient,Traumi),
	eta3(Patient,E),
	ha_vaccino(Patient),
	(Traumi >= 2; E > 70 -> P is 1;
	 P is 0 ).
rischio_alto(Patient,P,Traumi,E):-
	conta_traumi(Patient,Traumi),
	eta3(Patient,E),
	ha_vaccino(Patient),
	Traumi < 1, 
	E < 70,
	P is 0 .
rischio_alto(Patient,P,Traumi,E):-
	conta_traumi(Patient,Traumi),
	eta3(Patient,E),
	ha_vaccino(Patient),
	Traumi < 1; 
	E < 70,
	P is 0 .	*/
associazioni(Malattia, Traumi) :-
    findall(Trauma, propertyAssertion('http://www.isibang.ac.in/ns/codo#causes',Malattia, Trauma), Traumi).

cerca_malattie_pregresse(Patient,ListM):-
		findall(Malattie,propertyAssertion('http://www.isibang.ac.in/ns/codo#comorbidity',Patient,Malattie),ListM).
	
associazioni_per_lista([], []).

associazioni_per_lista([X|Rest], Associazioni) :-
    associazioni(X, AssociazioniX),
    associazioni_per_lista(Rest, RestAssociazioni),
    append(AssociazioniX, RestAssociazioni, AssociazioniNoDuplicati),
	list_to_set(AssociazioniNoDuplicati, Associazioni). % elimina duplicati


trova_traumi(Patient,T):-
	cerca_malattie_pregresse(Patient,M),
	associazioni_per_lista(M,T).

conta_traumi(Patient,NT):-
	trova_traumi(Patient,T),
	lunghezza_lista(T,NT).
	
calcolo_bmi(Patient,Bmi):-
		peso3(Patient,P),
		altezza3(Patient,A),
		Bmi is P / (A * A).
cerca_eta(Patient,LA):-
				findall(Anni,propertyAssertion('http://www.isibang.ac.in/ns/codo#age',Patient,Anni),LA).

eta(Patient,X):-
		    
                cerca_eta(Patient,Lt),
				arg(1,Lt,X).
eta2(Patient,Y):-
 eta(Patient,X),
	arg(1,X,Y).
	
eta3(Patient,ZI):-
 eta2(Patient,Y),
	arg(2,Y,Z),
    atom_number(Z,ZI).	% torna eta paziente come intero

cerca_altezza(Patient,LAl):-
				findall(Altezza,propertyAssertion('http://www.isibang.ac.in/ns/codo#height',Patient,Altezza),LAl).

altezza(Patient,X):-
		    
                cerca_altezza(Patient,Lt),
				arg(1,Lt,X).
altezza2(Patient,Y):-
 altezza(Patient,X),
	arg(1,X,Y).
	
altezza3(Patient,ZI):-
 altezza2(Patient,Y),
	arg(2,Y,Z),
    atom_number(Z,ZI).	% torna altezza paziente come intero

ottieni_priorita(Lt,X):-
              
				arg(1,Lt,X).
				
ottieni_priorita2(Lt,Y):-
 ottieni_priorita(Lt,X),
	arg(2,X,Y).
	
ottieni_priorita3(Lt,ZI):-
 ottieni_priorita2(Lt,Y),
    atom_number(Y,ZI).











dosaggio_Mg_intero(Lt,X):-
              
				arg(1,Lt,X).
				
dosaggio_Mg_intero2(Lt,Y):-
 dosaggio_Mg_intero(Lt,X),
	arg(2,X,Y).
	
dosaggio_Mg_intero3(Lt,ZI):-
 dosaggio_Mg_intero2(Lt,Y),
    atom_number(Y,ZI).		
	
dosaggio_giorni_intero(Lt,X):-
              
				arg(1,Lt,X).
				
dosaggio_giorni_intero2(Lt,Y):-
 dosaggio_giorni_intero(Lt,X),
	arg(2,X,Y).
	
dosaggio_giorni_intero3(Lt,ZI):-
 dosaggio_giorni_intero2(Lt,Y),
    atom_number(Y,ZI).	% torna peso paziente come intero	
cerca_peso(Patient,LAp):-
				findall(Peso,propertyAssertion('http://www.isibang.ac.in/ns/codo#weight',Patient,Peso),LAp).

peso(Patient,X):-
                cerca_peso(Patient,Lt),
				arg(1,Lt,X).
				
peso2(Patient,Y):-
 peso(Patient,X),
	arg(1,X,Y).
	
peso3(Patient,ZI):-
 peso2(Patient,Y),
	arg(2,Y,Z),
    atom_number(Z,ZI).	% torna peso paziente come intero
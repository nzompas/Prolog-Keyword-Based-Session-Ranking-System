query(ListofKeywords) :-
    /*Ορισμός αρχείου εισόδου*/
    see('sessions.pl'),
    /*Προετοιμασία λέξεων και βάρους και αποθήκευσή τους σε ξεχωριστές λίστες.*/
    preparation(ListofKeywords,ListofKeys,ListofWeights),
    /*Λήψη των sessions και δημιουργία λιστών με τους σχετικούς τίτλους και το σκορ σχετικότητας*/
    /*Το πέμπτο όρισμα λειτουργεί ως διακόπτης(1=διαβάζω session και συνεχίζω τους υπολογισμούς,0=Σταματάω και επιστρέφω τους υπολογισμούς)*/
    readSessions(ListofKeys,ListofWeights,ListTR,ListSR,1),
    /*Κλείσιμο αρχείου εισόδου*/
    seen,
    /*Διαγραφή του τελευταίου στοιχείου των λιστών τίτλων και σκορς καθώς προέκυψε ανεπάντεχα χωρίς εσκεμένο σκοπό*/
    deleteLastElement(ListTR,ListSR,RListTR,RListSR),
    /*Παράλληλη ταξινόμηση των λίστων που περιέχουν τα σκορς και τους τίτλους με βάση τα σκόρς*/
    isort(RListSR,SortListSR,RListTR,SortListTR),
    /*Εκτύπωση των αποτελεσμάτων*/
    nl,
    printResults(SortListTR,SortListSR).

/*Προετοιμασία λέξεων και βάρους και αποθήκευσή τους σε λίστα.*/
preparation([],[],[]).
/*Αν η λέξη-κλειδί αποτελείται από 2 λέξεις και πάνω, και έχει ορισμένο βάρος*/
preparation([Key-N|Words],[Key|KK],[N|WW]):-
    tokenize_atom(Key,L),
    length(L,Len),
    Len>=2,
    Weigword is N/Len,
    preparation2(L,KK,WW,Weigword,KKK,WWW),
    preparation(Words,KKK,WWW).
/*Αν η λέξη-κλειδί αποτελείται απο μόνο μία λέξη και έχει ορισμένο βάρος*/
preparation([Key-N|Words],[Key|KK],[N|WW]):-
    preparation(Words,KK,WW).
/*Αν η λέξη-κλειδί αποτελείται από 2 λέξεις και πάνω, και default βάρος 1*/
preparation([Key|Words],[Key|KK],[1|WW]):-
    tokenize_atom(Key,L),
    length(L,Len),
    Len>=2,
    Weigword is 1/Len,
    preparation2(L,KK,WW,Weigword,KKK,WWW),
    preparation(Words,KKK,WWW).
/*Αν η λέξη-κλειδί αποτελείται απο μόνο μία λέξη και default βάρος 1*/
preparation([Key|Words],[Key|KK],[1|WW]):-
    preparation(Words,KK,WW).

/*Προσθέτει στις λίστες λέξεων και βάρους, τις λέξεις με το ίδιο βάρος από την λέξη-κλειδί που αποτελείται απο 2 λέξεις και πάνω.*/
preparation2([],Words,Weights,_,Words,Weights).
preparation2([K|W],[K|Words],[WW|Weights],WW,KKK,WWW):-
    preparation2(W,Words,Weights,WW,KKK,WWW).

/*Λήψη των sessions*/
readSessions(_,_,[],[],0). /*Τέλος αρχείου*/
readSessions(ListofKeys,ListofWeights,[HTR|TTR],[HSR|TSR],1):-
    /*Λήψη session*/
    read(Session),
    (
        /*Όταν τελειώσει το αρχείο τελειώνει η διαδικασία και επιστρέφονται οι λίστες*/
        (
        Session=end_of_file,
        readSessions(ListofKeys,ListofWeights,TTR,TSR,0)/*Αποστολή 0 που σηματοδοτεί τη λήξη της διαδικασίας*/
        )
        ;
        /*Όσο υπάρχουν sessions γίνεται λήψη των δεδομένων για να φτιαχτούν οι λίστες*/
        (
        Session\=end_of_file,
        createListSessions(Session,ListofKeys,ListofWeights,HTR,HSR),
        readSessions(ListofKeys,ListofWeights,TTR,TSR,1)/*Αποστολή 0 που σηματοδοτεί τη συνέχεια της διαδικασίας*/
        )
    ).

/*Δημιουργία συνολικού σκορ για session και αποθήκευση του τίτλου του*/
createListSessions(session(TitleS,TopicsS),ListofKeys,ListofWeights,TitleS,TotalScoreSession):-
     scoreOfTopics(TopicsS,ListofKeys,ListofWeights,ScoresL),/*Σκοράρισμα των θεμάτων*/
     scoreOfTopicWithWords(TitleS,ListofKeys,ListofWeights,0,ScoreTitle),/*Σκοράρισμα του τίτλου*/
     totalScoreTitle(ScoreTitle,TST),/*Σκοράρισμα τίτλου επι 2 με βάση τις απαιτησεις της εκφώνησης*/
     scoreOfSession([TST],ScoresL,TotalScoreSession). /*Συνολικό σκορ ενός session*/

/*Σκοράρισμα session*/
scoreOfSession(TotalSTitle,TotalSTopic,TotalSS):-
    append(TotalSTitle,TotalSTopic,ListTotalSS),
    max_list(ListTotalSS,MaxS),
    sum_list(ListTotalSS,SumSS),
    TotalSS is (1000*MaxS+SumSS).


/*Σκράρισμα θεμάτων με ολες τις λέξεις κλειδιά*/
scoreOfTopics([],_,_,[]).
scoreOfTopics([T|RT],LK,LW,[Score|OfTopic]):-
    scoreOfTopicWithWords(T,LK,LW,0,Score),
    scoreOfTopics(RT,LK,LW,OfTopic),!.


/*Σκοράρισμα θέματος με όλες τις λέξεις κλειδιά.*/
scoreOfTopicWithWords(_,[],[],Score,Score):-!.
scoreOfTopicWithWords(Topic,[Key|RestK],[Weight|RestW],Temp,Score):-
    scoreOfTopicWithWord(Topic,Key,Weight,ScoreT),
    New is Temp+ScoreT,
    scoreOfTopicWithWords(Topic,RestK,RestW,New,Score),!.

/*Σκοράρισμα θέματος με μία λέξη κλειδί*/
scoreOfTopicWithWord(Topic,KeyWord,WeightWord,ScoreT):-
    /*Αν βρεθεί η λέξη επέστρεψε το βάρος της*/
    sub_string(case_insensitive,KeyWord,Topic),
    ScoreT=WeightWord.
    /*Αλλιώς επέστρεψε 0*/
scoreOfTopicWithWord(_,_,_,0).

/*Διπλασιασμός σκορ τίτλου*/
totalScoreTitle(ST,TST):-
    TST is ST*2.

/*Διαγραφή του τελευταίου στοιχείου των λιστών τίτλων και σκορς καθώς προέκυψε ανεπάντεχα χωρίς εσκεμένο σκοπό*/
deleteLastElement(ListTR,ListSR,RListTR,RListSR):-
    append(R1,[_],ListTR),
    RListTR=R1,
    append(R2,[_],ListSR),
    RListSR=R2.

/*Ταξινόμηση κατά φθίνουσα σειρά σχετικότητας*/
isort([],[],[],[]).
isort([HeadS|TailS],ResultS,[HeadT|TailT],ResultT):-
    isort(TailS,SortedTailS,TailT,SortedTailT),
    insert(HeadS,SortedTailS,ResultS,HeadT,SortedTailT,ResultT).

insert(XS,[],[XS],XT,[],[XT]).
insert(XS,[YS|TailS],[XS,YS|TailS],XT,[YT|TailT],[XT,YT|TailT]):-
    XS>YS.
insert(XS,[YS|TailS],[YS|ZS],XT,[YT|TailT],[YT|ZT]):-
    insert(XS,TailS,ZS,XT,TailT,ZT).

/*Εμφάνιση των αποτελεσμάτων*/
printResults([],[]).
printResults([HT|TT],[HS|TS]):-
    write('Session: '),write(HT),nl,
    write('      Relevanse = '),write(HS),nl,
    printResults(TT,TS).


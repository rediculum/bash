#!/bin/bash
#
# Mon Dec 29 13:20:30 CET 2008 
# Tue Mar 16 15:00:24 CET 2010 / EEA korr.: Phi Zahl addiert wenn mult. Inv. kleiner 0 ist
#                                anstatt groessere Primzahl
#
# RSA encryption simulator
#
# Usage: rsa_encrypter.sh [ 1.primenumber 2.primenumber [-d] ]
#
#################################################################################
# Variablen und Funktionen
#################################################################################
if [ ! `which bc` ]; then
        echo "bc not found"
        exit 2
fi
clear                   # Terminal loeschen
START=$(date +%s.%N)    # Zeit stoppen
 
if [ "$3" -eq "-d" ]; then       # Setze Variable DEBUG wenn der 3. Parameter -d ist
        DEBUG=1
else
        DEBUG=
fi
 
function_primzahl()             # Waehlt zufaellig eine Primzahl aus dem Bereich
{
        PRIM_ARRAY=( 2 3 5 7 11 13 17 19 23 29 31 37 41 43 47 53 59 61 67 71 73 79 83 89 97 101 103 107 109 113 127 131 137 139 149 151 157 163 167 173 179 181 191 193 197 199 211 223 227 229 233 239 241 251 257 263 269 271 277 281 283 293 307 311 313 317 331 337 347 349 353 359 367 373 379 383 389 397 401 409 419 421 431 433 439 443 449 457 461 463 467 479 487 491 499 503 509 521 523 541 547 557 563 569 571 577 587 593 599 601 607 613 617 619 631 641 643 647 653 659 661 673 677 683 691 701 709 719 727 733 739 743 751 757 761 769 773 787 797 809 811 821 823 827 829 839 853 857 859 863 877 881 883 887 907 911 919 929 937 941 947 953 967 971 977 983 991 997
)
        ANZ_PRIMS=${#PRIM_ARRAY[*]}     # Die Anzahl Elemente im Array
 
        INDEX=$(($RANDOM%$ANZ_PRIMS))   # Zufallszahl modulo Anzahl Elemente
        PRIMZAHL=${PRIM_ARRAY[$INDEX]}  # Inhalt der Indexes zuweisen
        echo $PRIMZAHL                  # Inhalt ausgeben
}
function_ggt()                  # Rechne den groessten gemeinsamen Teiler
{
        NUM1=$1                 # Erster Parameter (Zahl)
        NUM2=$2                 # Zweiter Parameter (Zahl)
        MOD=1                   # Pseudo Platzhalter, da Variable nicht leer sein darf
 
        # Einfacher eukldischer Algorithmus:
        while [ $MOD != 0 ]; do
                MOD=`expr $NUM2 % $NUM1`        # NUM2 Modulo NUM1
                if [ $MOD == 0 ]; then
                        echo $NUM1
                else
                        NUM2=$NUM1
                        NUM1=$MOD
                fi
        done
}
function_teilerfremd()          # Gibt eine Zahl zurueck, die teilerfremd zur uebergebenen Zahl ist (parameter $1)
{
        TEILER=0
        while [ $TEILER != 1 ]; do                      # Wiederhole den Vorgang bis der ggT 1 zutrifft
                ZUFALLSZAHL=$(($RANDOM%$1))             # Zufallszahl generieren die kleiner als uebergebene Zahl ist
                if [ $ZUFALLSZAHL = 0 ]; then
                        ZUFALLSZAHL=$(($RANDOM%$1))             # Falls Zahl 0 ist, generiere eine Neue
                fi
                TEILER=$(function_ggt $ZUFALLSZAHL $1)  # Rufe den groessten gem. Teiler auf
        done
        echo $ZUFALLSZAHL                               # Gefundene Zahl ausgeben
}
function_erweuklalgo()          # Erweiterter Euklidischer Algorithmus um das multiplikative Inverse zu ermitteln
                                # Funktion kann mittels zwei Zahlen und -d als 3. Parameter einzel aufgerufen werden
{
        if [ "$1" -le "$2" ]; then      # Werte kehren, falls erster Wert kleiner ist als Zweiter
                g1=$2; g2=$1
        else
                g1=$1; g2=$2
        fi
        y1=1; y2=0
        x1=0; x2=1
        q=0
        if [ $DEBUG ]; then
                printf "q\tg\ty\tx\n"
                echo "-------------------------"
                printf "$q\t$g1\t$y1\t$x1\n"
                printf "$q\t$g2\t$y2\t$x2\n"
        fi
        while [ $g2 != 1 ]; do          # Wiederhole die Zerlegung bis g2 den Wert 1 erreicht hat
                q=`expr $g1 / $g2`
                if [ $DEBUG ]; then
                        printf "$q\t"
                fi
 
                temp=$g2
                g2=`expr $g1 % $g2`
                g1=$temp
                if [ $DEBUG ]; then
                        printf "$g2\t"
                fi
 
                temp=$y2
                let y2=$q*$y2
                let y2=$y1-$y2
                y1=$temp
                if [ $DEBUG ]; then
                        printf "($y2)\t"
                fi
 
                temp=$x2
                let x2=$q*$x2
                let x2=$x1-$x2
                x1=$temp
                if [ $DEBUG ]; then
                        if [ $g2 == 1 ]; then
                                echo -e "\033[1m$x2\033[0m"
                        else
                                echo -e "$x2\t"
                        fi
                fi
 
        done
        if [ $DEBUG ]; then
                echo -e "\n g hat die Zahl 1 erreicht. Das multiplikative Inverse ist x"
        fi
        if [ "$x2" -le 0 ]; then  # Wenn die Inverse kleiner 0 ist, addiere die Phi-Zahl, damit positiv
                if [ $DEBUG ]; then
                        echo "x war eine negative Zahl, also Phi-Zahl generiert und addiert"
                        let phiN=(`expr $1 - 1`*`expr $2 - 1`)
                        let x2=$x2+$phiN
                else
                        let phiN=(`expr $q - 1`*`expr $p - 1`)
                fi
        fi
        if [ $DEBUG ]; then
                printf "Endgueltiges, multiplikatives Inverse von $2 und $1 ist: "
        fi
        echo $x2
}
################################################################################
# Implementation
################################################################################
function_alice1()                       # Alice's erster Schritt
{
        echo -e "\033[1m Alice: \033[0m"
        p=;q=
        if [ -e $1 -o -e $2 ]; then
                echo "Generiere Primzahlen..."
        elif [ $1 -eq -$2 ]; then
                echo "Zahlen duerfen nicht gleich sein"
                exit 2
        fi
        while [ $p == $q ]; do        # Wiederhole falls generierte Zahlen gleich  
                if [ -e $1 ]; then
                        p=$(function_primzahl)
                else
                        let p=$1
                fi
                if [ -e $2 ]; then
                        q=$(function_primzahl)
                else
                        let q=$2
                fi
        done
        let N=$q*$p; echo -e "RSA Modul: $q x $p = \033[1m $N \033[0m"
        let phiN=(`expr $q - 1`*`expr $p - 1`); echo -e "Eulersche Phi-Funktion: ($q - 1) x ($p - 1) = \033[1m $phiN \033[0m"
        echo "Suche mittels euklidischem Algorhitmus eine Nummer, die teilerfremd zu $phiN ist:"
        e=$(function_teilerfremd $phiN); echo -e "\033[1m $e \033[0m ist teilerfremd zu $phiN (beide haben 1 als ggT)"
        echo -e "Alice's oeffentlicher Schluessel ist das RSA Modul \033[1m $N \033[0m und die gefundene, teilerfremde Zahl \033[1m $e \033[0m"
        echo "An Bob senden  ---> ..."
}
function_bob1()                 # Bob's erster Schritt
{
        echo -e "\033[1m Bob: \033[0m"
        x=$(($RANDOM%$N)); echo -e "Moechte die Zahl \033[1m $x \033[0m sicher an Alice uebermitteln (Zahl muss kleiner als RSA Modul sein)"
        echo -ne "Verschluessle die Zahl mit der Formel: $x ^ $e mod $N = "; y=$(echo $x^$e%$N |bc); echo -e "\033[1m $y \033[0m"
        echo "Sende zurueck ---> ..."
}
function_alice2()                       # Alice's zweiter Schritt
{
        echo -e "\033[1m Alice: \033[0m"
        echo -ne "Benutze den erw. euklidischen Algorithmus um das multiplikative Inverse von $phiN und $e zu ermitteln:"
        b=$(function_erweuklalgo $phiN $e); echo -e "\033[1m $b \033[0m"
        echo -ne "Entschluessle $y mittels Formel: $y ^ $b mod $N = "; xy=$(echo $y^$b%$N |bc); echo -e "\033[1m $xy \033[0m"
        echo ""
        if [ $xy -eq $x ]; then
                echo "Hat geklappt!"
        else
                echo "Leider nicht geklappt"
        fi
}
# MAIN
#################################################################################
echo "Dieses Script simuliert eine RSA Verschluesselung"
echo "______________________________________"
if [ $DEBUG ]; then
        echo "Fuehre nur den erw. euklidischen Algorithmus aus"
        function_erweuklalgo $1 $2      # Debug Euklidischer Algorithmus
else
        function_alice1 $1 $2
        printf "\n"
        function_bob1
        printf "\n"
        function_alice2
fi
END=$(date +%s.%N)
DIFF=$(echo "$END - $START" |bc)
echo "Die Kalkulationen dauerten $DIFF Sek"

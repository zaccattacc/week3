pragma circom 2.0.0;

// [assignment] implement a variation of mastermind from https://en.wikipedia.org/wiki/Mastermind_(board_game)#Variation as a circuit

include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";

template MastermindVariation() {
    // Implementation of Number Mastermind that also checks for the sum of the numbers.
    signal input pubGuessA;
    signal input pubGuessB;
    signal input pubGuessC;
    signal input pubGuessD;
    signal input pubHitNum;
    signal input pubBlowNum;
    signal input pubSum;
    signal input pubSolnHash;

    // Private inputs
    signal input privSolnA;
    signal input privSolnB;
    signal input privSolnC;
    signal input privSolnD;
    signal input privSalt;

    signal output solnHashOut;

    var guess[4] = [pubGuessA, pubGuessB, pubGuessC, pubGuessD];
    var soln[4] = [privSolnA, privSolnB, privSolnC, privSolnD];

    component lessThan[2][4];
    component equalGuess[6];
    component equalSoln[6];
    var equalIdx = 0;
    

    for(var j = 0; j<4; j++){
        lessThan[0][j] = LessThan(3);
        lessThan[0][j].in[0] <== guess[j];
        lessThan[0][j].in[1] <== 6;
        lessThan[0][j].out === 1;
        lessThan[1][j] = LessThan(3);
        lessThan[1][j].in[0] <== soln[j];
        lessThan[1][j].in[1] <== 6;
        lessThan[1][j].out === 1;
        for(var k = j+1; k<4; k++){
            equalGuess[equalIdx] = IsEqual();
            equalGuess[equalIdx].in[0] <== guess[j];
            equalGuess[equalIdx].in[1] <== guess[k];
            equalGuess[equalIdx].out === 0;
            equalSoln[equalIdx] = IsEqual();
            equalSoln[equalIdx].in[0] <== soln[j];
            equalSoln[equalIdx].in[1] <== soln[k];
            equalSoln[equalIdx].out === 0;
            equalIdx += 1;
        }
    }

    // Count hit and blow
    var hit = 0;
    var blow = 0;
    component equal[4][4];

    for(var j = 0; j<4; j++){
        for(var k = 0; k < 4; k++){
            equal[j][k] = IsEqual();
            equal[j][k].in[0] <== soln[j];
            equal[j][k].in[1] <== guess[k];
            blow += equal[j][k].out;
            if(j == k){
                hit += equal[j][k].out;
                blow -= equal[j][k].out;

            }
        }
    }

    blow === 0;

    component equalHit = IsEqual();
    equalHit.in[0] <== pubHitNum;
    equalHit.in[1] <== hit;
    equalHit.out === 1;

    component equalBlow = IsEqual();
    equalBlow.in[0] <== pubBlowNum;
    equalBlow.in[1] <== blow;
    equalBlow.out === 1;

    signal Sum;

    Sum <== privSolnA + privSolnB + privSolnC + privSolnD;

    pubSum === Sum;

    component poseidon = Poseidon(5);
    poseidon.inputs[0] <== privSalt;
    poseidon.inputs[1] <== privSolnA;
    poseidon.inputs[2] <== privSolnB;
    poseidon.inputs[3] <== privSolnC;
    poseidon.inputs[4] <== privSolnD;

    solnHashOut <== poseidon.out;
    pubSolnHash === solnHashOut;


}

component main {public [pubGuessA, pubGuessB, pubGuessC, pubGuessD, pubHitNum, pubBlowNum, pubSolnHash]} = MastermindVariation();
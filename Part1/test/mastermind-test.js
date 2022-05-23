//[assignment] write your own unit test to show that your Mastermind variation circuit is working as expected
const chai = require("chai");
const path = require("path");
const wasm_tester = require("circom_tester").wasm;
const { buildPoseidon } = require("circomlibjs");

const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString("21888242871839275222246405745257275088548364400416034343698204186575808495617");
const Fr = new F1Field(exports.p);

const assert = chai.assert;


describe("Mastermind test", function(){
    this.timeout(100000000);

    it("Should verify the solution", async () => {

        // load the poseidon hasher
        let poseidon = await buildPoseidon();
        let F = poseidon.F;

        // initialize the mastermind circuit
        const circuit = await wasm_tester("contracts/circuits/MastermindVariation.circom");
        await circuit.loadConstraints();

        // inputs
        let soln = [2, 5, 4, 1];
        let guess = [2, 5, 4, 1];
        let Sum = 0;
        let hit = 0;
        let blow = 0;
        const privSalt = "6024332733"; // salt
        toBeHashed = [privSalt, ...guess];

        // calculates the hit and blow value
        for(var i = 0; i < 4; i++){
            Sum += guess[i];
            for(var j = 0; j < 4; j++){
                blow += (soln[i] == guess[j]) ? 1 : 0;
                if (i == j){
                    hit += (soln[i] == guess[j]) ? 1 : 0;
                    blow -= (soln[i] == guess[j]) ? 1 : 0;
                }
            }
        }

        let pubSolnHash = poseidon(toBeHashed);

        // Inputs for the circuit
        const Input = {
            "pubGuessA": guess[0].toString(),
            "pubGuessB": guess[1].toString(),
            "pubGuessC": guess[2].toString(),
            "pubGuessD": guess[3].toString(),
            "pubHitNum": hit.toString(),
            "pubBlowNum": blow.toString(),
            "pubSum": Sum.toString(),
            "pubSolnHash": F.toObject(pubSolnHash),
            "privSolnA": soln[0].toString(),
            "privSolnB": soln[1].toString(),
            "privSolnC": soln[2].toString(),
            "privSolnD": soln[3].toString(),
            "privSalt": privSalt,
        }

        // Calculating witness
        const witness = await circuit.calculateWitness(Input, true);
        
        await circuit.checkConstraints(witness);
        // Asserts that the hash is the same
        await circuit.assertOut(witness, {solnHashOut: F.toObject(pubSolnHash)})

    })

   
    
})
use Time;

use HPCCProblemSize, RARandomStream;


param numTables = 1;
type elemType = randType,
     indexType = randType;

config const n = computeProblemSize(elemType, numTables,
                                    returnLog2=true): indexType,
             N_U = 2**(n+2);   // numUpdates

const m = 2**n,                // probSize
      indexMask = m-1;

config const sequentialVerify = (numLocales < log2(m)),
             errorTolerance = 1.0e-2;

config const printParams = true,
             printArrays = false,
             printStats = true;


def main() {
  printConfiguration();

  const TableSpace: domain(1, indexType) distributed(Block) = [0..m);
  var T: [TableSpace] elemType;

  const UpdateSpace: domain(1, indexType) distributed(Block) = [0..N_U);

  const startTime = getCurrentTime();

  [i in TableSpace] T(i) = i;

  forall block in UpdateSpace.subBlocks do
    for r in RAStream(block) do
      T(r & indexMask) ^= r;

  const execTime = getCurrentTime() - startTime;

  const validAnswer = verifyResults(T, UpdateSpace);
  printResults(validAnswer, execTime);
}


def printConfiguration() {
  if (printParams) {
    printProblemSize(elemType, numTables, m);
    writeln("Number of updates = ", N_U, "\n");
  }
}


def verifyResults(T: [?TDom], UpdateSpace) {
  if (printArrays) then writeln("After updates, T is: ", T, "\n");

  if (sequentialVerify) then
    for r in RAStream([0..N_U)) do
      T(r & indexMask) ^= r;
  else
    forall i in UpdateSpace {
      const r = getNthRandom(i+1);
      atomic T(r & indexMask) ^= r;
    }

  if (printArrays) then writeln("After verification, T is: ", T, "\n");

  const numErrors = + reduce [i in TDom] (T(i) != i);
  if (printStats) then writeln("Number of errors is: ", numErrors, "\n");

  return numErrors <= (errorTolerance * N_U);
}


def printResults(successful, execTime) {
  writeln("Validation: ", if successful then "SUCCESS" else "FAILURE");
  if (printStats) {
    writeln("Execution time = ", execTime);
    writeln("Performance (GUPS) = ", N_U / execTime * 1.0e-9);
  }
}

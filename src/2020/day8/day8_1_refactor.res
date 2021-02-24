type terminate_t =
  | InfiniteLoop // infinite loop
  | OutOfIndex // out of index
  | NotYet // not terminated

type state_t = {
  idx: int,
  value: int,
  terminateState: terminate_t,
  visitIndexes: array<int>,
}

type instruction_t =
  | Acc(int)
  | Jmp(int)
  | Nop

type instructions_t = array<instruction_t>

let initialState: state_t = {idx: 0, value: 0, terminateState: NotYet, visitIndexes: []}

let splitSignValue = signValue => {
  let re = %re("/(\+|\-)([0-9]+)/")
  let result = Js.Re.exec_(re, signValue)

  switch result {
  | Some(r) => {
      let sign = Js.Nullable.toOption(Js.Re.captures(r)[1])
      let value =
        Js.Nullable.toOption(Js.Re.captures(r)[2])
        ->Belt.Option.getExn
        ->Belt.Int.fromString
        ->Belt.Option.getExn

      if sign == Some("-") {
        Some(-value)
      } else {
        Some(value)
      }
    }
  | None => None
  }
}

let parse = (strs: array<string>): instructions_t => {
  strs->Belt.Array.mapWithIndex((_, str) => {
    let line = str->Js.String2.split(" ")
    let (operator, signValue) = (line[0], line[1])
    let value = splitSignValue(signValue)->Belt.Option.getExn

    switch operator {
    | "acc" => Acc(value)
    | "jmp" => Jmp(value)
    | "nop" => Nop
    | _ => raise(Not_found)
    }
  })
}

let isVisited = (thisState): bool => {
  thisState.visitIndexes->Belt.Array.some(visitIndex => {visitIndex == thisState.idx}) == true
}

let terminateCheck = (instructions, thisState: state_t): terminate_t => {
  if thisState->isVisited == true {
    InfiniteLoop
  } else if thisState.idx > instructions->Belt.Array.length - 1 {
    OutOfIndex
  } else {
    NotYet
  }
}

let run = (instructions: instructions_t, thisState: state_t): state_t => {
  let terminateState = terminateCheck(instructions, thisState)
  let thisInstruction = instructions->Belt.Array.get(thisState.idx)

  switch thisInstruction {
  | Some(Acc(value)) => {
      idx: thisState.idx + 1,
      value: thisState.value + value,
      terminateState: terminateState,
      visitIndexes: thisState.visitIndexes->Belt.Array.concat([thisState.idx]),
    }
  | Some(Jmp(value)) => {
      ...thisState,
      idx: thisState.idx + value,
      terminateState: terminateState,
      visitIndexes: thisState.visitIndexes->Belt.Array.concat([thisState.idx]),
    }
  | Some(Nop) => {
      ...thisState,
      idx: thisState.idx + 1,
      terminateState: terminateState,
      visitIndexes: thisState.visitIndexes->Belt.Array.concat([thisState.idx]),
    }
  | _ => {
      ...thisState,
      terminateState: terminateState,
    }
  }
}

let rec execute = (originalInstructions: instructions_t, thisState: state_t): state_t => {
  let instructions = originalInstructions->Belt.Array.copy

  switch thisState.terminateState {
  | InfiniteLoop
  | OutOfIndex => thisState
  | NotYet => instructions->execute(run(instructions, thisState)) // newState  not terminated
  }
}

// Common
let originalInstructions = Node.Fs.readFileAsUtf8Sync("./input.txt")->Js.String2.split("\n")->parse

// Part 1
let outP1 = originalInstructions->execute(initialState)
outP1.value->Js.log

let makeCandidates = (instructions: instructions_t): array<instructions_t> => {
  instructions->Belt.Array.reduceWithIndex([], (acc, x, i) => {
    switch x {
    | Jmp(_) => {
        let newInstructions = originalInstructions->Belt.Array.copy
        let _setValue = newInstructions->Belt.Array.set(i, Nop)
        acc->Belt.Array.concat([newInstructions])
      }
    | Nop => {
        let newInstructions = originalInstructions->Belt.Array.copy
        let _setValue = newInstructions->Belt.Array.set(i, Jmp(i))
        acc->Belt.Array.concat([newInstructions])
      }
    | _ => acc
    }
  })
}

let outP2 = originalInstructions
->makeCandidates
->Belt.Array.map(candidate => candidate->execute(initialState))
->Belt.Array.keepMap(result => {
  switch result.terminateState {
  | OutOfIndex => Some(result)
  | _ => None
  }
})

outP2[0].value->Js.log

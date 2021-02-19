type state_t = {
  currentIndex: int,
  currentValue: int,
}

type instruction_t = {
  index: int,
  operator: string, // acc, jmp, nop
  value: int, // w/ sign
  count: int,
}

type instructions_t = array<instruction_t>

let initialState: state_t = {currentIndex: 0, currentValue: 0}

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
  strs->Belt.Array.mapWithIndex((i, str) => {
    let line = str->Js.String2.split(" ")
    let (operator, signValue) = (line[0], line[1])
    let value = splitSignValue(signValue)

    {
      index: i,
      operator: operator,
      value: value->Belt.Option.getExn,
      count: 0,
    }
  })
}

module IntCmp = Belt.Id.MakeComparable({
  type t = int
  let cmp = Pervasives.compare
})

let includes = (arrs, el) => Belt.Set.fromArray(arrs, ~id=module(IntCmp))->Belt.Set.has(el)

let countUpExecuted = (instructions: instructions_t, thisState: state_t): bool => {
  instructions->Belt.Array.set(
    thisState.currentIndex,
    {
      ...instructions[thisState.currentIndex],
      count: instructions[thisState.currentIndex].count + 1,
    },
  )
}

let rec operate = (instructions: instructions_t, thisState: state_t): state_t => {
  let thisInstruction =
    instructions
    ->Belt.Array.keepWithIndex((_, i) => i == thisState.currentIndex)
    ->Belt.Array.getExn(0)

  let countUpExecution = countUpExecuted(instructions, thisState)

  if countUpExecution != true {
    Js.Exn.raiseError("Failed to execute current instruction!")
  }

  if instructions[thisState.currentIndex].count >= 2 {
    thisState
  } else {
    switch thisInstruction.operator {
    | "nop" =>
      instructions->operate({
        currentIndex: thisState.currentIndex + 1,
        currentValue: thisState.currentValue,
      })
    | "acc" =>
      instructions->operate({
        currentIndex: thisInstruction.index + 1,
        currentValue: thisState.currentValue + thisInstruction.value,
      })
    | "jmp" =>
      instructions->operate({
        currentIndex: thisInstruction.index + thisInstruction.value,
        currentValue: thisState.currentValue,
      })
    | _ => {
        currentIndex: thisState.currentIndex,
        currentValue: thisState.currentValue,
      }
    }
  }
}

let findInstructionWithNopJmp = instructions =>
  instructions->Belt.Array.keep(instruction => {
    switch instruction.operator {
    | "acc" => false
    | "jmp" => true
    | "nop" => true
    | _ => false
    }
  })

let swapNopJmp = (
  instructions: instructions_t,
  instructionWithNopJmps: instructions_t,
  thisState: state_t,
): instructions_t => {
  let indexToSwap = instructionWithNopJmps[thisState.currentIndex].index

  let swapExectution = instructions->Belt.Array.set(
    indexToSwap,
    {
      ...instructions[indexToSwap],
      operator: instructions[indexToSwap].operator == "nop" ? "jmp" : "nop",
    },
  )

  if swapExectution != true {
    Js.Exn.raiseError("Failed to execute current instruction!")
  }

  instructions
}

let rec operateWithFixedInstruction = (
  instructions: instructions_t,
  instructionWithNopJmps: instructions_t,
  thisState: state_t,
): state_t => {
  let originalInstructions = instructions->Belt.Array.copy
  let newInstructions = instructions->swapNopJmp(instructionWithNopJmps, thisState)
  let finalState = newInstructions->operate(initialState)

  try {
    originalInstructions->operateWithFixedInstruction(
      instructionWithNopJmps,
      {
        currentValue: thisState.currentValue,
        currentIndex: thisState.currentIndex + 1,
      },
    )
  } catch {
  | _ => finalState
  }
}

// Common
let instructions = Node.Fs.readFileAsUtf8Sync("./sample.txt")->Js.String2.split("\n")->parse

let instructionWithNopJmps = instructions->findInstructionWithNopJmp

// Part 1
let finalStateP1 = instructions->operate(initialState)
finalStateP1.currentValue->Js.log

// [
//   {index: 0, operator: "nop", value: 0, count: 0},
//   {index: 1, operator: "acc", value: 1, count: 0},
//   {index: 2, operator: "jmp", value: 4, count: 0},
//   {index: 3, operator: "acc", value: 3, count: 0},
//   {index: 4, operator: "jmp", value: -3, count: 0},
//   {index: 5, operator: "acc", value: -99, count: 0},
//   {index: 6, operator: "acc", value: 1, count: 0},
//   {index: 7, operator: "nop", value: -4, count: 0},
//   {index: 8, operator: "acc", value: 6, count: 0},
// ]

// Part 2
// let finalStateP2 =
//   instructions
//   ->operateWithFixedInstruction(instructionWithNopJmps, initialState)
//   // finalStateP2.currentValue
//   ->Js.log

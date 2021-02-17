/*
operator: { acc, jmp, nop }
The accumulator starts at 0.
From the sample: Immediately before the program would run an instruction a second time, 
the value in the accumulator is 5.
*/

/*
TODO:
comment:
- return를 state로 하도록 (tuple or record)
*/

type line_t = {
  index: int,
  operator: string, // acc, jmp, nop
  value: int, // w/ sign
  count: int,
}

type instruction_t = array<line_t>

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

      Js.log(("value:", value))
      if sign == Some("-") {
        Some(-value)
      } else {
        Some(value)
      }
    }
  | None => None
  }
}

let parse = (strs: array<string>): instruction_t => {
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

// type state = {
//   currentValue: int,
//   currentIndex: int,
// }

// let rec operate = (instructions: instruction_t, thisIndex: int): (int, int) => {
//   // instructions->Belt.Array.map(instruction => {
//   /*
//         {
//           index: int,
//           operator: string, // acc, jmp, nop
//           sign: string, // + / -
//           value: int,
//           count: int,
//         }
//  */

//   let instruction = instructions->Belt.Array.keepWithIndex((_, i) => i == thisIndex)

//   let change =
//     instructions->Belt.Array.set(
//       thisIndex,
//       {...instructions[thisIndex], count: instructions[thisIndex].count + 1},
//     )

//   if change != true {
//     Js.Exn.raiseError("Something wrong")
//   }

//   instruction->Belt.Array.reduce(0, (acc, instruction) => {
//     /*
//     Js.log((
//       "(op, sign, value):", (instruction.operator, instruction.sign, instruction.value), "i", thisIndex, "acc", acc, "d", acc + instruction.value,
//     ))
//     */

//     if instructions[thisIndex].count >= 2 {
//       acc
//     } else {
//       switch (instruction.operator, instruction.sign) {
//       | ("nop", _) => {
//           instructions->operate(thisIndex + 1)->ignore

//             currentValue: acc,
//             currentIndex: newIndex
//           }
//         }
//       | ("acc", "+") => {
//           (
//           instructions->operate(instruction.index + 1)->ignore,
//           acc + instruction.value
//           )
//         }
//       | ("acc", "-") => {
//           instructions->operate(instruction.index - 1)->ignore
//           acc - instruction.value
//         }
//       | ("jmp", "+") => {
//           instructions->operate(instruction.index + instruction.value)->ignore
//           acc
//         }
//       | ("jmp", "-") => {
//           instructions->operate(instruction.index - instruction.value)->ignore
//           acc
//         }
//       | _ => acc
//       }
//     }
//   })
// }

let instructions = Node.Fs.readFileAsUtf8Sync("./sample.txt")
->Js.String2.split("\n")
->parse
// ->operate(0)
->Js.log

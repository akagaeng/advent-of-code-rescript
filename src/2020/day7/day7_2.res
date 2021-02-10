type input_t = array<string>

type node_t = {
  color: string,
  count: int,
}

type graph_t = array<node_t>

// type adjacencyList = array(node_t, array(node_t));
// type adjacencyList = array(string, array((int, string)))

module StrCmp = Belt.Id.MakeComparable({
  type t = string
  let cmp = Pervasives.compare
})

// Return: MapString type def?
let parse = (inputs: input_t) =>
  inputs
  ->Belt.Array.map(input => {
    let kv =
      input
      ->Js.String2.replaceByRe(%re("/bags|bag|[.]/g"), "")
      ->Js.String2.replace("no", "0")
      ->Js.String2.trim
      ->Js.String2.split("  contain ")
    (kv[0], kv[1])
  })
  ->Belt.Map.String.fromArray

/* MapString
{
   "shiny gold": "1 dark olive , 2 vibrant plum",
   ...
}
*/
let parseAdjacents = (adjacents: string) => {
  adjacents
  ->Js.String2.split(" , ")
  ->Belt.Array.map(content => {
    let qc = content->Js.String2.splitByRe(%re("/ (.*)/"))
    {
      color: qc[1]->Belt.Option.getExn,
      count: qc[0]->Belt.Option.getExn->int_of_string,
    }
  })
}

let findTargetColorFromBags = (bags, targetColor) => {
  bags->Belt.Map.String.getExn(targetColor)
}

let toUnique = (arr: array<string>): array<string> => {
  arr->Belt.Set.fromArray(~id=module(StrCmp))->Belt.Set.toArray
}

let getColors = (contents: array<node_t>): array<string> => contents->Belt.Array.map(c => c.color)

let getColorCounts = (contents: array<node_t>): array<int> => contents->Belt.Array.map(c => c.count)

let getColor = (node: node_t): string => node.color

let isNotNoOtherFromMpde = (parsedAdjacents: array<node_t>) =>
  parsedAdjacents->Belt.Array.keep(node => node.color !== "other")

let isNotOtherFromColor = (colors: array<string>) => colors->Belt.Array.keep(c => c !== "other")

let findAdjacentNodes = (targetColors, bags) => {
  targetColors
  ->Belt.Array.map(targetColor => bags->findTargetColorFromBags(targetColor))
  ->Belt.Array.map(adjacent => adjacent->parseAdjacents)
  ->Belt.Array.concatMany
}

let rec search = (bags, targetColors: array<string>, vertices: array<node_t>) => {
  let adjacentNodes = targetColors->isNotOtherFromColor->findAdjacentNodes(bags)
  switch adjacentNodes->Belt.Array.length == 0 {
  | true => vertices
  | false => search(bags, adjacentNodes->getColors, vertices->Belt.Array.concat(adjacentNodes))
  }
}

let getLength = arr => arr->Belt.Array.length

let inputs = Node.Fs.readFileAsUtf8Sync("./sample.txt")->Js.String2.split("\n")

let targetColor = "shiny gold"

let uniqueKeyColors = inputs->parse->Belt.Map.String.keysToArray->toUnique

uniqueKeyColors
->Belt.Array.map(keyColor => {
  inputs->parse->search([keyColor], [])->Belt.Array.keep(v => v.color != "other")
})
// ->Belt.Array.keepMap(r => {
//   let thisArr = r->Belt.Array.keep(v => v.color != "other")
//   // Js.log(("thisArr:", thisArr, thisArr->Belt.Array.length))
//   // let tailColor = thisArr[(thisArr->Belt.Array.length) - 1]
//   // tailColor
//   // thisArr->Belt.List.fromArray->Belt.List.tail
// })
>>>>>>> 1fe73bf394f853a688ebf04c617fec4bdfbd58dc
->Js.log

// Part 1 # DOING
inputs->parse
->Js.log

// Part 2
inputs->parse->search([targetColor], [])->getColorCounts->Js.log

/*
shiny gold 
    -> 1 dark olive
        -> 3 faded blue     -> 0 other
        -> 4 dotted black   -> 0 other
    -> 2 vibrant plum
        -> 5 faded blue      -> 0 other
        -> 6 dotted black    -> 0 other
*/

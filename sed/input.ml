open Test_lib
open Report

let%meta identifier = "sed"
let%meta stars = 2
let%meta title = "Adapt sed"
let%meta short_description = "Adapt sed so that it works on OS X"
let%meta author = []

let plus (x : int) (y : int) : int = x + y

let minus (x : int) (y : int) : int = x - y

let concat (x : string) (y : int) : string = x ^ (string_of_int y)

let rec recursive (x : float) : float = x

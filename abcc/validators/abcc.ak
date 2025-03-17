// use aiken/list.{foldl}
// use aiken/list.{length}
use aiken/builtin
fn check(a: List<Int>)-> Int{

  let x = builtin.foldl(a, [], fn(n, acc){
    if n != acc{

      [n, ..acc]
    }
    else{
      acc
    }
  })
  builtin.length(x)
}
test checkk(){
  check([1, 2, 3, 4, 4]) == 4
}

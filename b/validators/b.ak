use aiken/collection/list

pub fn luckyKids(behaviors: List<Int>) -> Int {

  when behaviors is {
    [] -> 0
    _ -> {

      let initial_count = 1
      

      check_kids(behaviors, initial_count)
    }
  }
}


fn check_kids(behaviors: List<Int>, initial_count: Int) -> Int {
  let n = list.length(behaviors)
  if n <= 1 {

    initial_count
  } else {

    check_kids_helper(behaviors, 0, n - 1, initial_count)
  }
}
fn check_kids_helper(behaviors: List<Int>, index: Int, max_index: Int, lucky_count: Int) -> Int {
  if index >= max_index {
    lucky_count
  } else {
    let current_behavior = get_element_at(behaviors, index)

    let count_better = count_better_than(behaviors, current_behavior, index + 1, max_index + 1)
    

    let total_older = max_index - index + 1
    

    let half_siblings = total_older / 2
    

    if count_better >= half_siblings {

      check_kids_helper(behaviors, index + 1, max_index, lucky_count + 1)
    } else {

      check_kids_helper(behaviors, index + 1, max_index, lucky_count)
    }
  }
}


fn count_better_than(behaviors: List<Int>, target: Int, start: Int, end: Int) -> Int {

  let sublist = list.take(list.drop(behaviors, start), end - start)

  count_elements_less_than(sublist, target)
}

fn count_elements_less_than(lst: List<Int>, target: Int) -> Int {
  list.foldr(lst, 0, fn(x, acc) { if x < target { acc + 1 } else { acc } })
}


fn get_element_at(lst: List<Int>, index: Int) -> Int {
  get_element_helper(lst, 0, index)
}


fn get_element_helper(lst: List<Int>, current: Int, target: Int) -> Int {
  when lst is {
    [] -> 0 
    [x, ..xs] -> {
      if current == target {
        x
      } else {
        get_element_helper(xs, current + 1, target)
      }
    }
  }
}
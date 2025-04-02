pub fn getCandyPosition(n: Int, r: Int, c: Int, candy: Int) -> List<Int> {
  if candy > n || candy <= 0 {
    [-1, -1, -1]
  } else {
    let per_box = r * c
    let box = if candy % per_box == 0 { candy / per_box } else { (candy / per_box) + 1 }
    let pos = if candy % per_box == 0 { per_box } else { candy % per_box }
    let rev_pos = per_box - pos + 1
    [box, (rev_pos - 1) / c, (rev_pos - 1) % c]
  }
}

type Roots{
    One(Int)
    Two(Int, Int)
    None    
}

fn issqrt(n: Int, x: Int, y: Int) -> Int {
    if y >= x {
        x
    } else {
        issqrt(n, y, (y + n / y) / 2)
    }
}
// test init(){
//     let x = 25
//     issqrt(x, x, (x + 1)/2 ) == 5
// }
fn calculate(a: Int, b: Int, c: Int) -> Roots {
    let delta = b * b - 4 * a * c
    if delta > 0 {
        let sqrt_delta = issqrt(delta, delta, (delta + 1) / 2)  // Gọi hàm issqrt để tính căn bậc hai
        let x1 = (-b - sqrt_delta) / (2 * a)
        let x2 = (-b + sqrt_delta) / (2 * a)
        Two(x1, x2)
    } else if delta == 0 {
        let x = -b / (2 * a)
        One(x)
    } else {
        None
    }
}

test case1() {
    calculate(1, 2, -3) == Two(-3, 1)  // Kiểm tra trường hợp với phương trình x^2 + 2x - 3 = 0
}

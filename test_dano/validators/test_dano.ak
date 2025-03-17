use cardano/assets.{PolicyId, AssetName, Value}
use aiken/collection/list
use cardano/transaction.{Input, OutputReference, Output, Transaction, Datum, InlineDatum, TransactionId, NoDatum}

// fn exact(
//     flat: List<(PolicyId, AssetName, Int)>,
//     pid: PolicyId,
//     tkn: AssetName,
//     amt: Int,

// )-> Bool{
//     list.any(flat, fn(entry){
//         let (policy, tokenname, amount) = entry
//         policy == pid && tkn == tokenname && amount == amt
//     })
// }
// test init(){
//     let a = [(#"000000", "long", 1000), (#"273981", "longdz", 2000)]
//     exact(a, #"000000", "long", 100000) == True 
// }

fn input_to_output(
    a: List<Input>,
    b: OutputReference
)-> Input{
    when list.find(a, fn(input){
        input.output_reference == b
    }) is{
        Some(input) -> input
        None -> fail @"Not Found"
    }
}

pub fn is_alphabetic(input: ByteArray) -> Bool {
  // Chuyển ByteArray thành list các Int
  let bytes = bytearray.to_list(input)
  
  // Kiểm tra từng byte một
  list.all(bytes, fn(byte) {
    // Kiểm tra xem byte có nằm trong khoảng ASCII của chữ cái không
    // A-Z: 65-90
    // a-z: 97-122
    (byte >= 65 && byte <= 90) || (byte >= 97 && byte <= 122)
  })
}

// Test cases
test is_alphabetic_test() {
  // Test chuỗi chỉ có chữ cái
  is_alphabetic("abcDEF") == True &&
  // Test chuỗi có số
  is_alphabetic("abc123") == False &&
  // Test chuỗi có ký tự đặc biệt
  is_alphabetic("abc!@#") == False &&
  // Test chuỗi có khoảng trắng
  is_alphabetic("abc def") == False &&
  // Test chuỗi rỗng
  is_alphabetic("") == True
}
use cardano/address.{Address}
use cardano/assets.{from_asset, from_lovelace, lovelace_of}
use cardano/transaction.{OutputReference, Transaction, find_input}
use vodka_address.{address_pub_key}
use vodka_extra_signatories.{key_signed}
use vodka_inputs.{inputs_at}
use vodka_value.{get_all_value_to, value_geq}

/// Datum cho giao dịch Market Place, chứa thông tin về người bán, giá cả và NFT
pub type MarketPlaceDatum {
  MarketPlaceDatum {
    // Địa chỉ của người bán NFT
    seller: Address,
    // Giá tiền của NFT (tính bằng Lovelace)
    price: Int,
    // Policy ID của NFT
    policy_id: ByteArray,
    // Asset Name của NFT
    asset_name: ByteArray,
  }
}

/// Các hành động có thể thực hiện trên Market Place
pub type MarketPlaceAction {
  // Mua NFT từ Market Place
  Buy
  // Đóng listing và lấy lại NFT (chỉ người bán)
  Close
}

/// Validator cho smart contract Market Place
/// 
/// @param own_address: Địa chỉ của smart contract Market Place này
/// @param fee: Phí giao dịch (tính bằng basis points, ví dụ: 250 = 2.5%)
validator market_place(own_address: Address, fee: Int) {
  spend(
    datum_opt: Option<MarketPlaceDatum>, 
    mkredeem: MarketPlaceAction, 
    own_ref: OutputReference, 
    tx: Transaction
  ) {
    // Đảm bảo datum tồn tại
    expect Some(datum) = datum_opt
    
    when mkredeem is {
      // Xử lý trường hợp mua NFT
      Buy -> {
        // Tìm input của script trong giao dịch
        expect Some(own_input) = find_input(tx.inputs, own_ref)
        let own_addr = own_input.output.address
        
        // Đảm bảo chỉ có một input từ script (chống double-spend)
        let is_one_only_input_script =
          when inputs_at(tx.inputs, own_addr) is {
            [_] -> True
            _ -> False
          }
          
        // Kiểm tra người bán nhận đủ số tiền
        // (Giá NFT + số ADA đã có trong UTXO)
        let is_proceed_paid = 
          get_all_value_to(tx.outputs, datum.seller)
          |> value_geq(
            from_lovelace(datum.price + lovelace_of(own_input.output.value))
          )
          
        // Kiểm tra phí được trả cho Market Place
        let is_fee_paid =
          get_all_value_to(tx.outputs, own_address)
          |> value_geq(
            from_lovelace(datum.price * fee / 10000)
          )
          
        // Tất cả điều kiện phải thỏa mãn
        is_one_only_input_script && is_proceed_paid && is_fee_paid
      }
      
      // Xử lý trường hợp đóng listing (chỉ người bán)
      Close -> {
        // Lấy khóa công khai của người bán
        expect Some(pub_key) = address_pub_key(datum.seller)
        
        // Kiểm tra giao dịch có chữ ký của người bán không
        key_signed(tx.extra_signatories, pub_key)
      }
    }
  }
  
  // Xử lý các endpoint khác
  else(_) {
    fail
  }
}
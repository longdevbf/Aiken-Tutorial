//mint.akuse aiken/collection/list
use aiken/crypto.{ScriptHash, VerificationKeyHash}
use cardano/address
use cardano/assets.{PolicyId, without_lovelace}
use cardano/transaction.{Transaction}
use hopistal/types.{Burn, Mint, MintRedeemer}
use hopistal/utils
use types/cip68
use aiken/collection/list

// @validator: Mint
// @title: Trình tạo tài sản động mã nguồn mở (Token/NFT) (CIP68)
// @description: Validator được sử dụng để đúc và đốt token (nft, token) theo chuẩn CIP68
// @params - platform: Địa chỉ khi người dùng tương tác với nền tảng, họ sẽ phải trả phí bảo trì nền tảng.
// @params - platform_fee: Số tiền tối thiểu mà người dùng phải trả cho nền tảng khi tương tác với nền tảng.
// @params - store: Nơi lưu trữ các token tham chiếu của token người dùng trong nfts được đúc theo CIP68 của nền tảng.
validator mint(
  platform: VerificationKeyHash,
  platform_fee: Int,
  store_payment_credential: ScriptHash,
  store_stake_credential: VerificationKeyHash,
  issuer: VerificationKeyHash,
) {
  mint(redeemer: MintRedeemer, policy_id: PolicyId, transaction: Transaction) {
    let Transaction { inputs, outputs, extra_signatories, mint, .. } =
      transaction
        //phẳng hóa giá trị mint 1. ko được có lovelace, 2. flatten() trả về danh sách token trong mint 
    let mint_flatten =
      mint
        |> without_lovelace()
        |> assets.flatten()
        //địa chỉ lưu trữtrữ
    let store_address =
      store_payment_credential
        |> address.from_script()
        |> address.with_delegation_key(store_stake_credential)
        //dia chi cua platform
    let platform_address = address.from_verification_key(platform)
    
    let output_utxo_platform =
      utils.find_output(outputs, platform_fee, platform_address)// lay ra cac dau ra dua vao thong tin dia chi va phi
    let check_output_platform = output_utxo_platform != None //bool
    when redeemer is {
// @action: Mint - Điều kiện để đúc tài sản (NFT/Token)
// - check_signed_by_author: Khi người dùng đúc tài sản, datum của validator store chứa trường author và người dùng phải cung cấp chữ ký để xác định rằng đây là tác giả đã đúc tài sản. Điều kiện này được thực hiện bằng cách so sánh chữ ký được nhập trong datum của validator store.
// - check_platform_fee: Kiểm tra trong output giao dịch có tồn tại một utxo chứa phí tối thiểu của nền tảng và được gửi đến địa chỉ nền tảng được định nghĩa trong tham số.
// - check_format_asset: Kiểm tra các trường được chỉ định như name, image, media_type, author tồn tại trong datum của validator store (yêu cầu metadata tài sản). Các trường này là bắt buộc.
// - amount_tx_output: số lượng output utxo = 4 trong đó 1 utxo cho địa chỉ platform_fee, 1 utxo cho địa chỉ validator store và 2 utxo địa chỉ người nhận trong đó 1 utxo chứa Token CIP222.
// - check_store_address: Kiểm tra tài sản (CIP100) được gửi đến một địa chỉ phải là địa chỉ của validator store
      Mint -> {
        
         
        // let signer_address = address.from_verification_key(issuer)
        // let signer_has_token = 
        // list.is_empty(
        //     utils.inputs_at_with_policy(inputs, signer_address, policy_id)
        // )
        
       
        let check_asset_mint =
          utils.check_asset_mint(
            mint_flatten,
            policy_id,
            cip68.prefix_100,
            cip68.prefix_222,
            outputs,
            store_address,
            issuer,
            extra_signatories,
            False,
          )
        and {
            //signer_has_token?,         // Chưa từng mint trước đó
            check_asset_mint?,
            check_output_platform?,
        }
      }

// @action: Burn - Điều kiện để đốt tài sản (NFT/Token)
// - signed_by_author: Khi người dùng thực hiện đốt tài sản, datum của validator store chứa trường author và người dùng phải cung cấp chữ ký để xác định rằng đây là tác giả đang thực hiện giao dịch đốt tài sản. Điều kiện này được thực hiện bằng cách so sánh chữ ký được nhập trong datum của validator store.
// - amount_tx_output: Output của giao dịch là 2 (1 utxo của địa chỉ nền tảng, 1 utxo của địa chỉ người nhận).
// - check_platform_fee: Kiểm tra số lượng ADA gửi đến nền tảng phải lớn hơn hoặc bằng số lượng ADA được định nghĩa trong tham số của validator.
// - check_amount: Kiểm tra số lượng token người dùng mà người gửi muốn đốt là hợp lệ và không vượt quá số lượng họ sở hữu.
// - ada_attacked: Kiểm tra nơi ADA đính kèm với token tham chiếu sẽ đi (đến ví mà người dùng hiện đang sở hữu).
// - check_amount_burn: Tác giả sẽ đốt cả hai NFT (Token Người dùng, Token Tham chiếu) với số lượng đã cho.
      Burn -> {
        let reference_asset =
          utils.find_input_reference_asset(inputs, extra_signatories)

        if list.length(reference_asset) > 0 {
          let mint_concat = list.concat(reference_asset, mint_flatten)
          let check_asset_burn =
            utils.check_asset_burn(
              mint_concat,
              policy_id,
              cip68.prefix_100,
              cip68.prefix_222,
            )
          and {
            check_asset_burn?,
            check_output_platform?,
          }
        } else {
          let check_asset_burn =
            utils.check_assets_prefix(mint_flatten, policy_id, cip68.prefix_222)
          and {
            check_asset_burn?,
            check_output_platform?,
          }
        }
      }
    }
  }

  else(_) {
    fail
  }
}

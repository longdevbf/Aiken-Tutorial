use aiken/crypto.{VerificationKeyHash}
use cardano/address
use cardano/assets.{without_lovelace}
use cardano/transaction.{
  InlineDatum, Output, OutputReference, Transaction, find_input,
}
use cardano/tx
use hopistal/types.{Remove, StoreRedeemer, Update}
use hopistal/utils
use types/cip68.{CIP68}
use validation/find.{output_by_addr_value}

// @validator: Store
// @title: Open source dynamic assets (Token/NFT) generator (CIP68)
// @description: Validator is used to update and remove tokens (nft, token) according to CIP68
// @params - platform: The address when users operate with the platform, they will have to pay a platform maintenance fee.
// @params - platform_fee: The minimum amount a user must pay to the platform when interacting with the platform.
// @params - issuer: 

validator store(
  platform: VerificationKeyHash, // địa chỉ của nền tảng(bên thu phí)
  platform_fee: Int,//phí nền tảngtảng
  issuer: VerificationKeyHash, //chữ ký của người mint (useruser)
) {
  spend(
    datum: Option<CIP68>, //datum gồm metadata và version 
    redeemer: StoreRedeemer, // gồm 2 action là update và removeremove
    output_reference: OutputReference, // đầu ra tham chiếu ngươif dùng muốn thực hiện
    transaction: Transaction,
  ) {
    expect Some(datum_input) = datum //chi nhan inline datum else(_) -> false
    let Transaction { inputs, outputs, extra_signatories, .. } = transaction //dinh nghia 1 transaction
    let platform_address = address.from_verification_key(platform) // public key cua dia chi(ben thu phi)
    let output_utxo_platform =
      utils.find_output(outputs, platform_fee, platform_address)// tim kiem output cua nen tang dua vao phi, dia chi, utxo
    expect Some(input) = find_input(inputs, output_reference)// tim kiem input dua vao utxo tham chieu
    let script_address = input.output.address //dia chi cua script
    let reference_token =
      input.output.value
        |> without_lovelace() //lay ra token (ko bao gom lovelace)
      
    let metadatum_input: CIP68 = datum_input//lay metadata
    expect author_input: ByteArray = //lay author tu metadata
      cip68.get(metadatum_input, types.author_key)
    let signed_by_author = tx.verify_signature(extra_signatories, author_input)
  //lay chu ki cua user
    when signed_by_author is {
      False -> False
      True ->
        when redeemer is {
          // @action: Update - Condition for update assets
          // signed_by_author: When a user updates an asset, there is an author field in the datum of the store validator. At the same time, the user must also provide a signature to update the fields in the datum to change the asset's metadata.
          // amount_tx_outputs: Check the transaction output which has a quantity of 3 (1 utxo sent to the store validator, 1 utxo sent to the platform address, and utxo is the author's address).
          // check_store_address: Check that the reference token used to change metadata exists and is sent to the store validator's address.
          // check_format_metadata: Check that the specified fields such as name, image, media_type, author exist in the store validator's datum (aka asset metadata). These fields are required. The value of author cannot be changed.
          // check_platform_fee: Check in the transaction output that the utxo contains the minimum platform fee and is sent to the platform address defined in params.
          // check_reference_token: Check the token to update the metadata that exists in the transaction output.
          Update -> {
            let utxo_output =
              output_by_addr_value(outputs, script_address, reference_token) // tim kiem utxo dua vao dia chi va info token
            expect InlineDatum(datum_output) = utxo_output.datum//lay inline datum
            expect metadatum_output: CIP68 = datum_output//lay metadata cua no
            expect author_input: ByteArray =
              cip68.get(metadatum_input, types.author_key)//lay dau vao metadata cua user
            expect author_output: ByteArray =
              cip68.get(metadatum_output, types.author_key)// lay dau ra
            let check_author = author_input == author_output //kiem tra 2 cai nay giong nhau 
            and {
              utils.check_output_utxo(utxo_output, issuer, extra_signatories)?, //kiem tra utxo cua ng ki
                 utils.check_output_update(inputs, outputs, script_address),//kiem tra input va output co giong nhau k
              output_utxo_platform != None, //kiem tra utxo cua nen tang ! none tuc la da ton tai nft tham chieu
              check_author,// kiem tra 2 dau vao va dau ra giong nhau
            }
          }
          // @action: Remove - Condition for remove assets
          // signed_by_author: When the user performs asset removal, the datum of the store validator contains the author field and the user must provide a signature to identify that this is the author who performed the asset minting transaction. This condition is performed by comparing the signature entered in the datum of the store validator.
          // Check in the transaction output that there exists an utxo containing the platform's minimum fee and is sent to the platform's address defined in params.
          // The transaction output has a quantity of 2 (1 utxo of the platform address, 1 utxo of the author)
          Remove -> {
            let author_address = address.from_verification_key(author_input)//lay pubkeyhash cua user
            utils.check_output_remove(
              outputs,
              platform_address,
              platform_fee,
              author_address,
            )//kiem tra output cua user va nen tang
          }
        }
    }
  }

  else(_) {
    fail
  }
}

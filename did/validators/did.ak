use aiken/collection/list
use aiken/crypto.{
  Blake2b_224, Hash, Script, ScriptHash, VerificationKey, VerificationKeyHash,
}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{Transaction}

pub type DidAction {
  Register
  Update
  Verify
  Revoke
}

pub type Identity {
  owner: Hash<Blake2b_224, VerificationKey>,
  name: ByteArray,
  metadata: ByteArray,
  created_at: Int,
  updated_at: Int,
  is_active: Bool,
}

pub type Datum {
  identity: Identity,
  action: DidAction,
}

pub type Redeemer {
  action: DidAction,
  new_metadata: Option<ByteArray>,
}
fn must_be_signed_by(
  tx: Transaction,
  vk: Hash<Blake2b_224, VerificationKey>,
) -> Bool {
  list.has(tx.extra_signatories, vk)
}
validator did {
  mint(datum: Datum, redeemer: Redeemer, ctx: ScriptContext) {
    let tx: Transaction = ctx.transaction
    // Kiểm tra chữ ký của owner
    when redeemer.action is {
      // Đăng ký mới - chỉ owner mới được đăng ký
      Register -> must_be_signed_by(tx, datum.identity.owner)
      // Cập nhật thông tin - chỉ owner mới được cập nhật
      Update ->
        when redeemer.new_metadata is {
          Some(_new_data) -> must_be_signed_by(tx, datum.identity.owner)
          None -> False
        }
      // Xác thực - ai cũng có thể xác thực một DID
      Verify -> datum.identity.is_active
      // Thu hồi - chỉ owner mới được thu hồi
      Revoke -> must_be_signed_by(tx, datum.identity.owner)
    }
  }

  else(_) {
    fail
  }
}



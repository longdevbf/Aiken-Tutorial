use aiken/crypto.{VerificationKeyHash}
use cardano/assets.{AssetName, PolicyId}
use types/cip68.{CIP68}

// the redeemer using mint validator

pub type Action {
  Lock
  UpdateContract
  Unlock
  AddAuthorizedUpdater { new_updater: VerificationKeyHash }
  RemoveAuthorizedUpdater { old_updater: VerificationKeyHash }
}

pub type PatientProfileDatum {
  owner: VerificationKeyHash,
  authorized_updaters: List<VerificationKeyHash>,
  nft_policy_id: PolicyId,
  nft_asset_name: AssetName,
  required_ada: Int,
  metadata: CIP68,
}

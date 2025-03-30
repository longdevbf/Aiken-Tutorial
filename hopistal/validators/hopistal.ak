use aiken/collection/list
use cardano/address.{Address}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{Input,
  Output, OutputReference, Transaction, find_input}
use hopistal/components.{
  ensure_nft_at_script, ensure_nft_to_owner, ensure_valid_update,
  ensure_valid_updater_change, verify_any_signature, verify_signature,
}
use hopistal/types.{
  Action, AddAuthorizedUpdater, Lock, PatientProfileDatum,
  RemoveAuthorizedUpdater, Unlock, UpdateContract,
}

validator hopistal_management {
  spend(
    datum_opt: Option<PatientProfileDatum>,
    redeemer: Action,
    ctx: ScriptContext,
    out_ref: OutputReference,
  ) {
    let tx: Transaction = ctx.transaction
    expect Some(this_input) = find_input(tx.inputs, out_ref)
    let this_addr: Address = this_input.output.address
    expect Some(datum) = datum_opt

    when redeemer is {
      Lock ->
        verify_signature(tx, datum.owner) && ensure_nft_at_script(
          tx.outputs,
          this_addr,
          datum,
        )
      UpdateContract ->
        verify_any_signature(tx, datum.authorized_updaters) && ensure_valid_update(
          tx.outputs,
          this_addr,
          datum,
        )
      Unlock ->
        verify_signature(tx, datum.owner)
        && ensure_nft_to_owner(
          tx.outputs,
          datum,
        )
      AddAuthorizedUpdater { new_updater } ->
        verify_signature(tx, datum.owner) && !list.has(
          datum.authorized_updaters,
          new_updater,
        ) && ensure_valid_updater_change(
          tx.outputs,
          this_addr,
          datum,
          list.push(datum.authorized_updaters, new_updater),
        )
      RemoveAuthorizedUpdater { old_updater } ->
        verify_signature(tx, datum.owner) && list.has(
          datum.authorized_updaters,
          old_updater,
        ) && ensure_valid_updater_change(
          tx.outputs,
          this_addr,
          datum,
          list.filter(
            datum.authorized_updaters,
            fn(updater) { updater != old_updater },
          ),
        )
    }
  }

  else(_) {
    False
  }
}

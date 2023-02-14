#import "../../src/contracts/contract_1/main.mligo" "Main"
#import "./helpers/bootstrap.mligo" "Bootstrap"
#import "./helpers/helper.mligo" "Helper"

let set_text = 
    let accounts = Bootstrap.boot_accounts(Tezos.get_now()) in
    let (_, _taddr, contr) = Bootstrap.originate_contract(Bootstrap.get_base_storage(accounts.0)) in
    let _ = Helper.pay_contract_fees_success(contr, 1tez) in
    Helper.set_text_success(contr, "Test")

let fees_not_paid = 
    let accounts = Bootstrap.boot_accounts(Tezos.get_now()) in
    let (_, _taddr, contr) = Bootstrap.originate_contract(Bootstrap.get_base_storage(accounts.0)) in
    Helper.set_text_failure(contr, "Test", Main.Errors.fees_not_paid)

let tier_should_change = 
    let accounts = Bootstrap.boot_accounts(Tezos.get_now()) in
    let (_, taddr, contr) = Bootstrap.originate_contract(Bootstrap.get_base_storage(accounts.0)) in
    let _ = Helper.pay_contract_fees_success(contr, 1tez) in
    let _ = Helper.set_text_success(contr, "Test") in
    let _ = Helper.set_text_success(contr, "Test") in
    let _ = Helper.set_text_success(contr, "Test") in
    let modified_store = Helper.get_storage(taddr) in
    match Map.find_opt accounts.0 modified_store.user_map with
        Some((_user, tier, _count)) -> 
            (match tier with 
                Gold -> ()
                | _ -> failwith "Tier should be Gold")
        | None -> failwith "User not in the map"
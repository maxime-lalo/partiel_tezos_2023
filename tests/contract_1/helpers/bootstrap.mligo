#import "../../../src/contracts/contract_1/main.mligo" "Main"

let boot_accounts (inittime : timestamp) =
    let () = Test.reset_state_at inittime 6n ([] : tez list) in
    let accounts =
        Test.nth_bootstrap_account 1,
        Test.nth_bootstrap_account 2,
        Test.nth_bootstrap_account 3
    in
    accounts

let originate_contract (init_storage: Main.Storage.t) = 
    let (taddr, _, _) = Test.originate Main.main init_storage 0mutez in
    let contr = Test.to_contract taddr in
    let addr = Tezos.address contr in
    (addr, taddr, contr)

let base_admin : address = "tz1cGkwCNGQqeA5BcAUqi8KoZxwmLfMkJEbR"

let get_base_storage(defaultAdmin: address) : Main.Storage.t = 
    let base_storage: Main.Storage.t = {
        creator_blacklist = [];
        admin_list = Map.literal[
            (defaultAdmin, true)
        ];
        has_paid = Map.empty;
        collections = [];
    }
    in
    base_storage
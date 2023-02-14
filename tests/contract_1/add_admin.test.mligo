#import "../../src/contracts/contract_1/main.mligo" "Main"
#import "./helpers/bootstrap.mligo" "Bootstrap"
#import "./helpers/helper.mligo" "Helper"

let test_send_invite = 
    let accounts = Bootstrap.boot_accounts(Tezos.get_now()) in
    let (_, _taddr, contr) = Bootstrap.originate_contract(Bootstrap.get_base_storage(accounts.0)) in
    let () = Test.set_source(accounts.0) in
    Helper.add_admin_success(accounts.1 , contr)

let test_send_invite_twice = 
    let accounts = Bootstrap.boot_accounts(Tezos.get_now()) in
    let (_, _taddr, contr) = Bootstrap.originate_contract(Bootstrap.get_base_storage(accounts.0)) in
    let _ = Test.set_source(accounts.0) in
    let _ = Helper.add_admin_success(accounts.1 , contr) in
    Helper.add_admin_failure(accounts.1 , contr, Main.Errors.invitation_already_sent)
